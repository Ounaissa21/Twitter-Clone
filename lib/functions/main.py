# main.py in your functions directory

import functions_framework
import tensorflow as tf
import numpy as np
import re
import string
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from textblob import TextBlob
from tensorflow.keras.preprocessing.text import tokenizer_from_json
from tensorflow.keras.preprocessing.sequence import pad_sequences
import json
import os
import requests

from venv.bin import nltk

# --- NLTK Downloads (Needed for the function environment) ---
# These downloads will happen when the function is deployed/initialized
# More reliable approach is to bundle the data with your function:
# https://firebase.google.com/docs/functions/callable-functions#include_sdk
try:
    nltk.data.find('corpora/stopwords')
except nltk.downloader.DownloadError:
    nltk.download('stopwords')
except LookupError: # Handle LookupError if find fails before DownloadError
    nltk.download('stopwords')

try:
    nltk.data.find('tokenizers/punkt')
except nltk.downloader.DownloadError:
    nltk.download('punkt')
except LookupError:
    nltk.download('punkt')

# Optional: uncomment if using vader_lexicon with TextBlob
# try:
#     nltk.data.find('sentiment/vader_lexicon')
# except nltk.downloader.DownloadError:
#      nltk.download('vader_lexicon')
# except LookupError:
#      nltk.download('vader_lexicon')


# --- Custom Stopword Set (MUST match train_model.py) ---
stop_words = set(stopwords.words('english'))
sentiment_words_to_keep = {'love', 'hate', 'like', 'dislike', 'good', 'bad', 'not', 'very', 'too', 'less', 'more', 'no'}
stop_words = stop_words - sentiment_words_to_keep

# --- Preprocessing function (MUST match train_model.py) ---
def preprocess_text(text):
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'http\S+', '', text)
    text = text.translate(str.maketrans('', '', string.punctuation))
    word_tokens = word_tokenize(text)
    filtered_words = [word for word in word_tokens if word not in stop_words]
    return " ".join(filtered_words)

# --- Load Global Resources (Model, Tokenizer) ---
# Load these outside the function definition so they are only loaded once
# when the function instance starts, not on every invocation.

tokenizer = None
tokenizer_config_path = os.path.join(os.path.dirname(__file__), 'tokenizer_config.json')
try:
    with open(tokenizer_config_path, 'r', encoding='utf-8') as f:
        tokenizer_json_string = f.read()
    tokenizer = tokenizer_from_json(tokenizer_json_string)
    print("Global: Tokenizer loaded successfully.")
except Exception as e:
    print(f"Global Error loading tokenizer configuration: {e}")
    # In a real function, you might want to log this error and handle function startup failure


interpreter = None
# Use the path to your saved TFLite model (optimized or unoptimized)
model_filename = 'healthy_unhealthy_model_optimized.tflite' # <--- !! VERIFY THIS FILENAME !!
model_path = os.path.join(os.path.dirname(__file__), model_filename)
try:
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    print("Global: TFLite model loaded and tensors allocated successfully.")
except Exception as e:
    print(f"Global Error loading TFLite model: {e}")
    # Log error, handle function startup failure

max_len = None
input_dtype = None
if interpreter:
    try:
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        max_len = input_details[0]['shape'][1]
        input_dtype = input_details[0]['dtype']
        print(f"Global: Detected max_len: {max_len}, Input dtype: {input_dtype}")
    except Exception as e:
        print(f"Global Error getting model details: {e}")
        # Log error, handle function startup failure


# --- OpenRouter API Details ---
# NOTE: Hardcoding API keys like this is NOT secure for production apps.
# For a real Flutter app, the API call should be made from a secure backend.
# Consider using Firebase Environment Configuration for API keys:
# https://firebase.google.com/docs/functions/config-env
OPENROUTER_API_KEY = "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" # Replace with your actual key if different
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# --- Helper: Sentiment analysis (using TextBlob) ---
def analyze_sentiment(text):
    # TextBlob returns a Sentiment object with polarity and subjectivity
    return TextBlob(text).sentiment.polarity

# --- Define keywords associated with unhealthy items/behaviors ---
unhealthy_keywords = [
    "pizza", "burger", "fries", "soda", "sugar", "candy", "chocolate",
    "smoking", "alcohol", "junk food", "fast food", "sedentary", "couch potato",
    "stay up late", "all night", "excessive screen time", "unhealthy food", "cigarettes"
    # Add more as needed
]
def contains_unhealthy_keyword(text, keywords):
    text_lower = text.lower()
    for keyword in keywords:
        if keyword in text_lower:
            return True
    return False

# --- Helper: Generate persuasive message using OpenRouter ---
def generate_persuasive_message(unhealthy_habit_text):
    print("Attempting to generate persuasive message...")
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        # Optional: Specify your site URL and GitHub repo if you have one
        # "HTTP-Referer": "YOUR_SITE_URL",
        # "X-Title": "YOUR_APP_NAME"
    }

    prompt = f"Reply to this tweet persuasively, encouraging a healthier choice without being preachy or judgmental: '{unhealthy_habit_text}'"

    data = {
        "model": "mistralai/mixtral-8x7b-instruct", # You can choose a different model if preferred
        "messages": [
            {"role": "system", "content": "You are a friendly health advisor bot on a social media platform. Respond like a tweet reply—concise, positive, persuasive, and engaging. Do not be judgmental. Encourage a healthier choice or perspective related to the user's tweet."},
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 60, # Adjust max tokens as needed for a tweet reply
        "temperature": 0.7 # Adjust temperature for creativity (0.0 to 1.0)
    }

    try:
        response = requests.post(OPENROUTER_URL, json=data, headers=headers)
        if response.status_code == 200:
            message = response.json().get("choices", [{}])[0].get("message", {}).get("content", "Could not generate a persuasive message at this time.")
            print("Persuasive Message generated successfully.")
            return message
        else:
            print(f"Error generating message: Status Code {response.status_code}")
            print("Error Response:", response.text)
            print("Ensure your OpenRouter API key is correct and the model is available.")
            return "Error generating message."
    except requests.exceptions.RequestException as e:
        print(f"Network Error generating message: {e}")
        print("Check internet connection or OpenRouter API status.")
        return "Error generating message."


# Known healthy habits (from your previous script) - Can be used for quick checks
known_healthy_habits = [
    "working out in the morning", "exercise", "eating vegetables",
    "drinking water", "sleeping well", "meditation", "yoga", "healthy food",
    "running", "swimming", "gym", "workout", "salad", "fruit", "vegetables"
    # Add more well-known healthy phrases
]


# --- Cloud Function Triggered by HTTP Request ---
@functions_framework.http
def classify_tweet_http(request):
    """HTTP Cloud Function to classify tweet text and generate a persuasive message if unhealthy."""
    print("--- Function classify_tweet_http triggered ---") # Log function start

    # Set CORS headers for local testing (if needed) and production
    # Allows POST requests from any origin during development
    # In production, restrict this to your app's origin
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    # Ensure model and tokenizer were loaded globally
    # If global loading failed, these will be None
    if interpreter is None or tokenizer is None or max_len is None or input_dtype is None:
        print("Function startup failed: Model or Tokenizer not loaded globally.")
        return json.dumps({"classification": "error", "message": "Backend model resources not ready."}), 500, headers


    # Get the tweet text from the request (assuming JSON body with 'text' key)
    try:
        request_json = request.get_json(silent=True)
        tweet_text = None
        if request_json and 'text' in request_json:
            tweet_text = request_json['text']
        else:
            print("Invalid request: JSON body with 'text' key expected.")
            return json.dumps({"classification": "error", "message": "Invalid request. Please send JSON body with 'text' key."}), 400, headers

        if not tweet_text or not isinstance(tweet_text, str):
            print("Invalid request: Tweet text is empty or not a string.")
            return json.dumps({"classification": "error", "message": "Tweet text is empty or invalid."}), 400, headers

    except Exception as e:
        print(f"Error parsing request JSON: {e}")
        return json.dumps({"classification": "error", "message": f"Error processing request: {e}"}), 400, headers


    original_text = tweet_text # Keep original text for post-processing and API call

    # --- Classification and Post-processing Logic (from test_model.py) ---
    # This part is similar to your test_model.py's classify_text_tflite function

    # Optional: Quick check for known healthy habits
    if any(habit in original_text.lower() for habit in known_healthy_habits):
        print("✅ Quick check: That seems like a well-known healthy habit!")
        # You could choose to return here if you trust the quick check
        # return json.dumps({"classification": "healthy", "message": "Quick check identified as healthy."}), 200, headers


    # --- Run Model Inference ---
    processed_text = preprocess_text(original_text)
    print(f"Processed Text for Model: '{processed_text}'")

    sequences = tokenizer.texts_to_sequences([processed_text])
    # Ensure padding dtype matches the model's expected input dtype
    padded_sequences = pad_sequences(sequences, maxlen=max_len, padding='post', truncating='post', dtype=input_dtype.__name__)
    input_data = np.array(padded_sequences, dtype=input_dtype)

    # Ensure input shape compatibility (Get details again inside the function is redundant if loaded globally)
    # Let's rely on the global details unless we suspect an issue
    # input_details = interpreter.get_input_details() # Redundant if loaded globally and checked at startup
    expected_input_shape = interpreter.get_input_details()[0]['shape'] # Get shape from global interpreter

    if len(input_data.shape) == 1:
        input_data = np.expand_dims(input_data, axis=0)

    if list(input_data.shape) != list(expected_input_shape):
        print(f"Error: Input data shape {input_data.shape} does not match expected model input shape {expected_input_shape}.")
        return json.dumps({"classification": "error", "message": "Input shape mismatch."}), 500, headers

    try:
        interpreter.set_tensor(interpreter.get_input_details()[0]['index'], input_data) # Use index from global interpreter
        interpreter.invoke()
        output_data = interpreter.get_tensor(interpreter.get_output_details()[0]['index']) # Use index from global interpreter
    except Exception as e:
        print(f"Error during model inference: {e}")
        return json.dumps({"classification": "error", "message": f"Error during model inference: {e}"}), 500, headers


    probability_unhealthy = None
    if output_data.shape == (1, 1):
        probability_unhealthy = output_data[0][0]
    else:
        print(f"Warning: Unexpected model output shape: {output_data.shape}")
        return json.dumps({"classification": "error", "message": "Unexpected model output shape."}), 500, headers

    probability_healthy = 1 - probability_unhealthy

    print(f"Model Prediction: Unhealthy={probability_unhealthy:.4f}, Healthy={probability_healthy:.4f}")

    # --- Post-processing with Sentiment ---
    sentiment_polarity = analyze_sentiment(original_text)
    contains_unhealthy_kwd = contains_unhealthy_keyword(original_text, unhealthy_keywords)

    print(f"Post-processing Info: Sentiment={sentiment_polarity:.4f}, Contains Unhealthy Keyword={contains_unhealthy_kwd}")

    # Define thresholds for post-processing
    model_unhealthy_confidence_threshold = 0.7
    model_healthy_confidence_threshold = 0.7
    negative_sentiment_threshold = -0.1
    positive_sentiment_threshold = 0.1

    # Check conditions for overrides
    is_rule1_override = (probability_unhealthy is not None and probability_unhealthy > model_unhealthy_confidence_threshold and
                         sentiment_polarity < negative_sentiment_threshold and
                         contains_unhealthy_kwd)

    is_rule2_override = (probability_healthy is not None and probability_healthy > model_healthy_confidence_threshold and
                         sentiment_polarity > positive_sentiment_threshold and
                         contains_unhealthy_kwd)

    print(f"Rule 1 Override Condition Met: [{is_rule1_override}]")
    print(f"Rule 2 Override Condition Met: [{is_rule2_override}]")


    final_classification = "healthy" # Default initial classification
    persuasive_message = None # Initialize persuasive message

    # Apply Override Rules using if/elif/else chain
    if is_rule1_override:
        final_classification = "healthy"
        print("Post-processing override: Negative sentiment towards unhealthy topic -> Classified as HEALTHY.")
    elif is_rule2_override:
        final_classification = "unhealthy"
        print("Post-processing override: Positive sentiment towards unhealthy topic -> Classified as UNHEALTHY.")
        # Generate persuasive message if classified as unhealthy by Rule 2
        persuasive_message = generate_persuasive_message(original_text)
    # If neither override rule is met, apply the model's default classification
    else:
        if probability_unhealthy is not None and probability_unhealthy > 0.5:
            final_classification = "unhealthy"
            print("Model Classified: That's likely an UNHEALTHY habit (no override).")
            # Generate persuasive message if classified as unhealthy by default threshold
            persuasive_message = generate_persuasive_message(original_text)
        else:
            final_classification = "healthy"
            print("Model Classified: That seems like a HEALTHY habit (no override).")

    print(f"Final classification: {final_classification}")

    # --- Return Response ---
    response_data = {
        "classification": final_classification,
        "probability_unhealthy": float(probability_unhealthy) if probability_unhealthy is not None else None,
        "probability_healthy": float(probability_healthy) if probability_healthy is not None else None,
        "sentiment_polarity": float(sentiment_polarity),
        "contains_unhealthy_keyword": bool(contains_unhealthy_kwd),
        "persuasive_message": persuasive_message
    }

    # Return JSON response with CORS headers
    return json.dumps(response_data), 200, headers
