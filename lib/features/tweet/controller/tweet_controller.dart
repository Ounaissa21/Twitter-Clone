import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/apis/storage_api.dart';
import 'package:twitter_clone/apis/tweet_api.dart';
import 'package:twitter_clone/core/enums/notification_type_enum.dart';
import 'package:twitter_clone/core/enums/tweet_type_enum.dart';
import 'package:twitter_clone/core/utils.dart'; // Assuming showSnackBar is here
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/notification/controller/notification_controller.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:twitter_clone/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fpdart/fpdart.dart'; // Import fpdart

// Define a custom failure type for better error messages
class ClassificationFailure {
  final String message;
  ClassificationFailure(this.message);
}

final tweetControllerProvider = StateNotifierProvider<TweetController, bool>(
  (ref) {
    return TweetController(
      ref: ref,
      tweetAPI: ref.watch(tweetAPIProvider),
      storageAPI: ref.watch(storageAPIProvider),
      notificationController:
          ref.watch(notificationControllerProvider.notifier),
    );
  },
);

final getTweetsProvider = FutureProvider((ref) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweets();
});

final getRepliesToTweetProvider =
    FutureProvider.family((ref, Tweet tweet) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getRepliesToTweet(tweet);
});

final getLatestTweetProvider = StreamProvider.autoDispose((ref) {
  final tweetAPI = ref.watch(tweetAPIProvider);
  return tweetAPI.getLatestTweet();
});

final getTweetByIdProvider = FutureProvider.family((ref, String id) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetById(id);
});

final getTweetsByHashtagProvider =
    FutureProvider.family((ref, String hashtag) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetsByHashtag(hashtag);
});

class TweetController extends StateNotifier<bool> {
  final TweetAPI _tweetAPI;
  final StorageAPI _storageAPI;
  final Ref _ref;
  final NotificationController _notificationController;

  TweetController({
    required Ref ref,
    required TweetAPI tweetAPI,
    required StorageAPI storageAPI,
    required NotificationController notificationController,
  })  : _ref = ref,
        _tweetAPI = tweetAPI,
        _storageAPI = storageAPI,
        _notificationController = notificationController,
        super(false);

  Future<List<Tweet>> getTweets() async {
    final tweetList = await _tweetAPI.getTweets();
    return tweetList.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  Future<Tweet> getTweetById(String id) async {
    final tweet = await _tweetAPI.getTweetById(id);
    return Tweet.fromMap(tweet.data);
  }

  void likeTweet(Tweet tweet, UserModel user) async {
    List<String> likes = tweet.likes;

    if (tweet.likes.contains(user.uid)) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }

    tweet = tweet.copyWith(likes: likes);
    final res = await _tweetAPI.likeTweet(tweet);
    res.fold((l) => null, (r) {
      _notificationController.createNotification(
        text: '${user.name} liked your tweet!',
        postId: tweet.id,
        notificationType: NotificationType.like,
        uid: tweet.uid,
      );
    });
  }

  void reshareTweet(
      Tweet tweet, UserModel currentUser, BuildContext context) async {
    tweet = tweet.copyWith(
      retweetedBy: currentUser.name,
      likes: [],
      commentIds: [],
      reshareCount: tweet.reshareCount + 1,
    );

    final res = await _tweetAPI.updateReshareCount(tweet);
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        tweet = tweet.copyWith(
          id: ID.unique(),
          reshareCount: 0,
          tweetedAt: DateTime.now(),
        );
        final res2 = await _tweetAPI.shareTweet(tweet);
        res2.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
            _notificationController.createNotification(
              text: '${currentUser.name} reshared your tweet!',
              postId: tweet.id,
              notificationType: NotificationType.retweet,
              uid: tweet.uid,
            );
            showSnackBar(
              context,
              'reweeted',
            );
          },
        );
      },
    );
  }

  Future<List<Tweet>> getRepliesToTweet(Tweet tweet) async {
    final document = await _tweetAPI.getRepliesToTweet(tweet);
    return document.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  Future<List<Tweet>> getTweetsByHashtag(String hashtag) async {
    final document = await _tweetAPI.getTweetsByHashtag(hashtag);
    return document.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  // Refactored method to call FastAPI endpoint with Either type for error handling
  Future<Either<ClassificationFailure, Map<String, dynamic>>> classifyTweet(
      String tweetText) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/classify_post'), // Replace with your FastAPI server URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': tweetText,
        }),
      ).timeout(const Duration(seconds: 10)); // Add a timeout for network requests

      if (response.statusCode == 200) {
        return Right(jsonDecode(response.body));
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        // Client-side errors (e.g., bad request from client)
        print('Client error classifying tweet: ${response.statusCode} - ${response.body}');
        return Left(ClassificationFailure('Failed to classify tweet: Invalid request.'));
      } else if (response.statusCode >= 500) {
        // Server-side errors
        print('Server error classifying tweet: ${response.statusCode} - ${response.body}');
        return Left(ClassificationFailure('Failed to classify tweet: Server error.'));
      } else {
        // Other unexpected status codes
        print('Unexpected status code classifying tweet: ${response.statusCode} - ${response.body}');
        return Left(ClassificationFailure('Failed to classify tweet: Unexpected error.'));
      }
    } on SocketException {
      // No internet connection or host unreachable
      print('Network error calling FastAPI: SocketException');
      return Left(ClassificationFailure('No internet connection or server unreachable.'));
    } on FormatException {
      // Malformed JSON response
      print('Data format error calling FastAPI: FormatException');
      return Left(ClassificationFailure('Received malformed data from classification server.'));
    } on http.ClientException catch (e) {
      // Other http client specific errors (e.g., connection refused)
      print('HTTP Client error calling FastAPI: ${e.message}');
      return Left(ClassificationFailure('Could not connect to classification server: ${e.message}'));
    } on Exception catch (e) {
      // Catch all other unexpected errors
      print('An unknown error occurred calling FastAPI: $e');
      return Left(ClassificationFailure('An unknown error occurred during classification.'));
    }
  }

  void shareTweet({
    required List<File> images,
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    if (text.isEmpty) {
      showSnackBar(context, 'Please enter text');
      return;
    }

    state = true; // Set loading state at the beginning of the shareTweet process

    try {
      if (images.isNotEmpty) {
        await _shareImageTweet(
          context: context,
          images: images,
          text: text,
          repliedTo: repliedTo,
          repliedToUserId: repliedToUserId,
        );
      } else {
        await _shareTextTweet(
          context: context,
          text: text,
          repliedTo: repliedTo,
          repliedToUserId: repliedToUserId,
        );
      }
    } finally {
      // Ensure loading state is reset even if an error occurs
      state = false;
    }
  }

  Future<void> _shareImageTweet({
    required List<File> images,
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    final hashtags = _getHashtagsFromText(text);
    String link = _getLinkFromText(text);
    final user = _ref.read(currentUserDetailsProvider).value!;

    // Call FastAPI to classify the tweet and handle the result
    final classificationResult = await classifyTweet(text);

    String category = 'unknown'; // Default values
    String persuasiveMessage = '';

    classificationResult.fold(
      (failure) {
        // Handle error from FastAPI classification
        showSnackBar(context, 'Classification error: ${failure.message}');
        // You might decide to proceed with default values or stop the tweet process here.
        // For now, we proceed with defaults, but alert the user.
      },
      (data) {
        // Successfully got classification data
        category = data['category'] ?? 'unknown';
        persuasiveMessage = data['persuasive_message'] ?? '';
      },
    );

    // Continue with image upload even if classification failed,
    // unless you want to block tweet creation entirely on classification failure.
    final imageLinks = await _storageAPI.uploadImage(images);

    Tweet tweet = Tweet(
      text: text,
      hashtags: hashtags,
      link: link,
      imageLinks: imageLinks,
      uid: user.uid,
      tweetType: TweetType.image,
      tweetedAt: DateTime.now(),
      likes: const [],
      commentIds: const [],
      id: '',
      reshareCount: 0,
      retweetedBy: '',
      repliedTo: repliedTo,
      category: category,
      persuasiveMessage: persuasiveMessage,
    );

    final res = await _tweetAPI.shareTweet(tweet);

    res.fold(
      (l) => showSnackBar(context, 'Failed to share tweet: ${l.message}'), // More specific error message
      (r) {
        if (repliedToUserId.isNotEmpty) {
          _notificationController.createNotification(
            text: '${user.name} replied to your tweet!',
            postId: r.$id,
            notificationType: NotificationType.reply,
            uid: repliedToUserId,
          );
        }
        showSnackBar(context, 'Tweet shared successfully!'); // Success message
      },
    );
  }

  Future<void> _shareTextTweet({
    required String text,
    required BuildContext context,
    required repliedTo,
    required String repliedToUserId,
  }) async {
    final hashtags = _getHashtagsFromText(text);
    String link = _getLinkFromText(text);
    final user = _ref.read(currentUserDetailsProvider).value;

    // Call FastAPI to classify the tweet and handle the result
    final classificationResult = await classifyTweet(text);

    String category = 'unknown'; // Default values
    String persuasiveMessage = '';

    classificationResult.fold(
      (failure) {
        // Handle error from FastAPI classification
        showSnackBar(context, 'Classification error: ${failure.message}');
        // You might decide to proceed with default values or stop the tweet process here.
        // For now, we proceed with defaults, but alert the user.
      },
      (data) {
        // Successfully got classification data
        category = data['category'] ?? 'unknown';
        persuasiveMessage = data['persuasive_message'] ?? '';
      },
    );

    Tweet tweet = Tweet(
      text: text,
      hashtags: hashtags,
      link: link,
      imageLinks: const [],
      uid: user!.uid,
      tweetType: TweetType.text,
      tweetedAt: DateTime.now(),
      likes: const [],
      commentIds: const [],
      id: '',
      reshareCount: 0,
      retweetedBy: '',
      repliedTo: repliedTo,
      category: category,
      persuasiveMessage: persuasiveMessage,
    );

    final res = await _tweetAPI.shareTweet(tweet);

    res.fold(
      (l) => showSnackBar(context, 'Failed to share tweet: ${l.message}'), // More specific error message
      (r) {
        if (repliedToUserId.isNotEmpty) {
          _notificationController.createNotification(
            text: '${user.name} replied to your tweet!',
            postId: r.$id,
            notificationType: NotificationType.reply,
            uid: repliedToUserId,
          );
        }
        showSnackBar(context, 'Tweet shared successfully!'); // Success message
      },
    );
  }

  String _getLinkFromText(String text) {
    String link = '';
    List<String> wordsInSentence = text.split(' ');
    for (String word in wordsInSentence) {
      if (word.startsWith('https://') ||
          word.startsWith('www.') ||
          word.startsWith('http://')) {
        link = word;
      }
    }
    return link;
  }

  List<String> _getHashtagsFromText(String text) {
    List<String> hashtags = [];
    List<String> wordsInSentence = text.split(' ');
    for (String word in wordsInSentence) {
      if (word.startsWith('#')) {
        hashtags.add(word);
      }
    }
    return hashtags;
  }
}