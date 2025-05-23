import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/apis/storage_api.dart';
import 'package:twitter_clone/apis/tweet_api.dart';
import 'package:twitter_clone/core/enums/notification_type_enum.dart';
import 'package:twitter_clone/core/enums/tweet_type_enum.dart';
import 'package:twitter_clone/core/utils.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/notification/controller/notification_controller.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

final getTweetsProvider = FutureProvider((ref) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweets();
});

final getRepliesToTweetProvider = FutureProvider.family((ref, Tweet tweet) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getRepliesToTweet(tweet);
});

final getLatestTweetProvider = StreamProvider((ref) {
  final tweetAPI = ref.watch(tweetAPIProvider);
  return tweetAPI.getLatestTweet();
});

final getTweetByIdProvider = FutureProvider.family((ref, String id) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetById(id);
});

final getTweetsByHashtagProvider = FutureProvider.family((ref, String hashtag) {
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

  Future<Map<String, dynamic>> classifyTweet(String text) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/classify_post'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error classifying tweet: ${response.statusCode}');
        return {
          'category': 'Unknown',
          'persuasive_message': '',
        };
      }
    } catch (e) {
      print('Error calling classification API: $e');
      return {
        'category': 'Unknown',
        'persuasive_message': '',
      };
    }
  }

  Future<void> replyWithHealthAdvice(Tweet tweet) async {
    if (tweet.category.toLowerCase() == 'unhealthy') {
      final healthBotTweet = Tweet(
        text: tweet.persuasiveMessage,
        hashtags: [],
        link: '',
        imageLinks: [],
        uid: 'health_advisor_bot', // You'll need to create this user
        tweetType: TweetType.text,
        tweetedAt: DateTime.now(),
        likes: [],
        commentIds: [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: tweet.id,
        category: 'healthy',
        persuasiveMessage: '',
      );

      await _tweetAPI.shareTweet(healthBotTweet);
    }
  }

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
            showSnackBar(context, 'Retweeted!');
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

    state = true;

    try {
      // First, classify the tweet
      final classification = await classifyTweet(text);
      String category = classification['category'] ?? 'Unknown';
      String persuasiveMessage = classification['persuasive_message'] ?? '';

      if (images.isNotEmpty) {
        final imageLinks = await _storageAPI.uploadImage(images);
        Tweet tweet = Tweet(
          text: text,
          hashtags: _getHashtagsFromText(text),
          link: _getLinkFromText(text),
          imageLinks: imageLinks,
          uid: _ref.read(currentUserDetailsProvider).value!.uid,
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
          (l) => showSnackBar(context, l.message),
          (r) async {
            if (repliedToUserId.isNotEmpty) {
              _notificationController.createNotification(
                text: '${_ref.read(currentUserDetailsProvider).value!.name} replied to your tweet!',
                postId: r.$id,
                notificationType: NotificationType.reply,
                uid: repliedToUserId,
              );
            }

            // If unhealthy, create a health advisor bot reply
            if (category.toLowerCase() == 'unhealthy') {
              await replyWithHealthAdvice(Tweet.fromMap(r.data));
            }
          },
        );
      } else {
        Tweet tweet = Tweet(
          text: text,
          hashtags: _getHashtagsFromText(text),
          link: _getLinkFromText(text),
          imageLinks: const [],
          uid: _ref.read(currentUserDetailsProvider).value!.uid,
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
          (l) => showSnackBar(context, l.message),
          (r) async {
            if (repliedToUserId.isNotEmpty) {
              _notificationController.createNotification(
                text: '${_ref.read(currentUserDetailsProvider).value!.name} replied to your tweet!',
                postId: r.$id,
                notificationType: NotificationType.reply,
                uid: repliedToUserId,
              );
            }

            // If unhealthy, create a health advisor bot reply
            if (category.toLowerCase() == 'unhealthy') {
              await replyWithHealthAdvice(Tweet.fromMap(r.data));
            }
          },
        );
      }
    } finally {
      state = false;
    }
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