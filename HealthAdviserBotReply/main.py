# main.py (for your Appwrite Function)
import os
import json
import time
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.id import ID
from appwrite.permission import Permission
from appwrite.role import Role

def main(context):
    context.log("Event Payload:")
    context.log(context.req.body)

    try:
        event_data = context.req.body
        new_tweet_document = event_data # This is the original tweet that triggered the function

        tweet_id = new_tweet_document['$id']
        tweet_category = new_tweet_document['category']
        # The persuasive message is expected from the FastAPI server's response,
        # which is embedded in the 'persuasiveMessage' field of the original tweet document.
        persuasive_message = new_tweet_document.get('persuasiveMessage', "Stay healthy!")
        
        context.log(f"Original Tweet ID: {tweet_id}, Category: {tweet_category}")

        client = Client()
        (client
            .set_endpoint(os.environ.get('APPWRITE_ENDPOINT'))
            .set_project(os.environ.get('APPWRITE_PROJECT_ID'))
            .set_key(os.environ.get('APPWRITE_API_KEY'))
        )
        databases = Databases(client)

        health_adviser_uid = os.environ.get('HEALTH_ADVISER_USER_ID') # Ensure this environment variable is set in Appwrite Function settings
        database_id = os.environ.get('TWEETS_DATABASE_ID') # Ensure this environment variable is set
        collection_id = os.environ.get('TWEETS_COLLECTION_ID') # Ensure this environment variable is set

        if not all([health_adviser_uid, database_id, collection_id]):
            context.log("Error: Missing one or more required environment variables (HEALTH_ADVISER_USER_ID, TWEETS_DATABASE_ID, TWEETS_COLLECTION_ID).")
            return context.res.empty()

        if tweet_category.lower() == 'unhealthy':
            context.log("Original tweet classified as unhealthy. Preparing bot reply...")

            # The bot's reply message will be the persuasive message from the classification.
            # You might want to format this further for display (e.g., "Health Adviser: " + persuasive_message)
            bot_reply_text = persuasive_message 
            
            # Data for the new tweet document (the bot's reply)
            bot_reply_tweet_data = {
                "text": bot_reply_text,
                "hashtags": [],
                "link": "",
                "imageLinks": [],
                "uid": health_adviser_uid, # The bot's UID
                "tweetType": "text", # This is a text-based reply
                "tweetedAt": int(time.time() * 1000), # Current timestamp
                "likes": [],
                "commentIds": [],
                "reshareCount": 0,
                "retweetedBy": "", # The bot's reply tweet itself is not a retweet
                "repliedTo": tweet_id, # This is crucial: links the reply to the original tweet
                "category": "healthy", # The bot's *reply content* is considered healthy advice
                "persuasiveMessage": "", # No further persuasive message needed for the reply itself
            }

            response = databases.create_document(
                database_id=database_id,
                collection_id=collection_id,
                document_id=ID.unique(), # Appwrite generates a unique ID for the new reply tweet
                data=bot_reply_tweet_data,
                permissions=[
                    Permission.read(Role.any()), # Allow everyone to read the bot's reply
                    Permission.update(Role.user(health_adviser_uid)), # Allow bot to update its own reply
                    Permission.delete(Role.user(health_adviser_uid))  # Allow bot to delete its own reply
                ]
            )
            context.log(f"Bot reply created successfully with ID: {response['$id']}")
        else:
            context.log("Original tweet classified as healthy. No bot reply needed from bot function.")

    except Exception as e:
        context.log(f"An error occurred in HealthAdviserBotReply function: {e}")
        context.log(f"Full traceback: {e.__traceback__}")

    return context.res.empty()