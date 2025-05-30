import 'dart:io' as io;
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/apis/storage_api.dart';
import 'package:twitter_clone/apis/tweet_api.dart';
import 'package:twitter_clone/apis/user_api.dart';
import 'package:twitter_clone/core/enums/notification_type_enum.dart';
import 'package:twitter_clone/core/enums/tweet_type_enum.dart';
import 'package:twitter_clone/core/utils.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/notification/controller/notification_controller.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:twitter_clone/models/user_model.dart';
import 'package:appwrite/models.dart';

// Provider for the TweetController
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

// FutureProvider to get all tweets
final getTweetsProvider = FutureProvider((ref) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweets();
});

// FutureProvider.family to get replies to a specific tweet
final getRepliesToTweetProvider = FutureProvider.family((ref, Tweet tweet) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getRepliesToTweet(tweet);
});

// StreamProvider to listen for the latest tweet (for real-time updates)
final getLatestTweetProvider = StreamProvider((ref) {
  final tweetAPI = ref.watch(tweetAPIProvider);
  return tweetAPI.getLatestTweet();
});

// FutureProvider.family to get a tweet by its ID
final getTweetByIdProvider = FutureProvider.family((ref, String id) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetById(id);
});

// FutureProvider.family to get tweets by a specific hashtag
final getTweetsByHashtagProvider = FutureProvider.family((ref, String hashtag) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetsByHashtag(hashtag);
});

// Provider for the bot user.
// IMPORTANT: Replace 'YOUR_BOT_USER_UID_HERE' with the actual UID of your bot user in Appwrite.
// You MUST create a user in Appwrite specifically for this bot and use its UID here.
final botUserProvider = FutureProvider<UserModel>((ref) async {
  // In a real application, you would fetch the bot user's data from your Appwrite
  // database using a UserAPI. For this example, we're creating a dummy UserModel.
  // Example if you had a UserAPI:
  // final userAPI = ref.watch(userAPIProvider);
  // final botUserDoc = await userAPI.getUserData('YOUR_BOT_USER_UID_HERE');
  // return UserModel.fromMap(botUserDoc.data);

  return const UserModel(
    email: 'healthadviser@gmail.com',
    name: 'Health advisor',
    profilePic:
        'https://cdn.discordapp.com/attachments/1228445946900381720/1376418121413431326/healthbotpfp.PNG?ex=683540c4&is=6833ef44&hm=008c8e022687ba02e4b00deb52143fe3ec23fb75f502bb69f5da6a5a0b5348e1&', // Placeholder image for the bot
    bannerPic: '',
    uid:
        '683222f400388f832b44', // <<< IMPORTANT: REPLACE THIS WITH YOUR BOT'S ACTUAL UID FROM APPWRITE
    bio: 'I provide helpful messages about healthy tweets.',
    isTwitterBlue: true, followers: [],
    following: [],
    healthPoints: 0, // Optionally, make the bot appear verified
  );
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

  // Fetches all tweets from the API
  Future<List<Tweet>> getTweets() async {
    final tweetList = await _tweetAPI.getTweets();
    return tweetList.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  // Fetches a single tweet by its ID
  Future<Tweet> getTweetById(String id) async {
    final tweet = await _tweetAPI.getTweetById(id);
    return Tweet.fromMap(tweet.data);
  }

  // Handles liking/unliking a tweet
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

  // Handles resharing a tweet
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
      (l) {
        if (context.mounted) {
          // Add this check
          showSnackBar(context, l.message);
        }
      },
      (r) async {
        tweet = tweet.copyWith(
          id: ID.unique(),
          reshareCount: 0,
          tweetedAt: DateTime.now(),
        );
        final res2 = await _tweetAPI.shareTweet(tweet);
        res2.fold(
          (l) {
            if (context.mounted) {
              // Add this check
              showSnackBar(context, l.message);
            }
          },
          (r) {
            _notificationController.createNotification(
              text: '${currentUser.name} reshared your tweet!',
              postId: tweet.id,
              notificationType: NotificationType.retweet,
              uid: tweet.uid,
            );
            if (context.mounted) {
              // Add this check
              showSnackBar(context, 'Retweeted!');
            }
          },
        );
      },
    );
  }

  // Fetches replies to a given tweet
  Future<List<Tweet>> getRepliesToTweet(Tweet tweet) async {
    final document = await _tweetAPI.getRepliesToTweet(tweet);
    return document.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  // Fetches tweets containing a specific hashtag
  Future<List<Tweet>> getTweetsByHashtag(String hashtag) async {
    final document = await _tweetAPI.getTweetsByHashtag(hashtag);
    return document.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  void shareTweet({
    required List<io.File> images,
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    if (text.isEmpty) {
      if (context.mounted) {
        showSnackBar(context, 'Please enter text or select an image.');
      }
      return;
    }

    state = true;
    final hashtags = _getHashtagsFromText(text);
    String link = _getLinkFromText(text);
    final user = _ref.read(currentUserDetailsProvider).value!;

    List<String> imageLinks = [];
    if (images.isNotEmpty) {
      imageLinks = await _storageAPI.uploadImage(images);
    }

    String category = '';
    String persuasiveMessage = '';

    try {
      final response = await http.post(
        Uri.parse('http://ur_ip_address:8000/classify_post'), // Your FastAPI endpoint
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        category = data['category'];
        if (category.toLowerCase() == 'unhealthy') {
          persuasiveMessage = data['persuasive_message'];
        } else {
          persuasiveMessage = "No message generated (classified as healthy).";
        }
        print('Classification Result: Category: $category, Message: $persuasiveMessage');
      } else {
        print('Failed to classify tweet: ${response.statusCode} ${response.body}');
        category = 'Unknown';
        persuasiveMessage = 'Classification failed.';
      }
    } catch (e) {
      print('Error calling classification API: $e');
      category = 'Unknown';
      persuasiveMessage = 'Error during classification.';
    }

    if (category.toLowerCase() == 'healthy' || category.toLowerCase() == 'unhealthy') {
      _updateUserHealthPoints(category, user.uid);
    }

    TweetType tweetType = images.isNotEmpty ? TweetType.image : TweetType.text;

    Tweet tweet = Tweet(
      text: text,
      hashtags: hashtags,
      link: link,
      uid: user.uid,
      tweetType: tweetType,
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

    res.fold((l) {
      if (context.mounted) {
        showSnackBar(context, l.message);
      }
    }, (r) async {
      if (repliedToUserId.isNotEmpty) {
        _notificationController.createNotification(
          text: '${user.name} replied to your tweet!',
          postId: r.$id,
          notificationType: NotificationType.reply,
          uid: repliedToUserId,
        );
      }

      if (category.toLowerCase() == 'unhealthy' && persuasiveMessage.isNotEmpty) {
        final botUser = await _ref.read(botUserProvider.future);

        final botReplyTweet = Tweet(
          text: persuasiveMessage,
          hashtags: const [],
          link: '',
          uid: botUser.uid,
          tweetType: TweetType.text,
          tweetedAt: DateTime.now(),
          likes: const [],
          commentIds: const [],
          id: '',
          reshareCount: 0,
          retweetedBy: '',
          repliedTo: r.$id,
          category: 'healthy',
          persuasiveMessage: '',
        );

        final botRes = await _tweetAPI.shareTweet(botReplyTweet);

        botRes.fold(
          (l) => print('Failed to send bot reply: ${l.message}'),
          (botReplyDocument) {
            print('Bot successfully replied to tweet ${r.$id}');
            _notificationController.createNotification(
              text: '${botUser.name} replied to your tweet!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: user.uid,
            );
          },
        );
      }
    });
    state = false;
  }

  // Extracts links from the tweet text
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

  // Extracts hashtags from the tweet text
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

  // Update the shareTweet methods to handle health points
  void _updateUserHealthPoints(String category, String uid) async {
    final userAPI = _ref.read(
        userAPIProvider); // Assuming userAPIProvider is defined and provides a UserAPI
    final userData = await userAPI.getUserData(uid);
    final user = UserModel.fromMap(userData.data);

    // Update health points based on tweet category
    final newPoints =
        user.healthPoints + (category.toLowerCase() == 'healthy' ? 1 : -1);

    // Ensure points don't go below 0
    final updatedPoints = newPoints < 0 ? 0 : newPoints;

    final updatedUser = user.copyWith(healthPoints: updatedPoints);
    await userAPI.updateUserData(updatedUser);
  }
}
