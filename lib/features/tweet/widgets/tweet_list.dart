import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/common/error_page.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/appwrite_constants.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/features/tweet/widgets/tweet_card.dart';
import 'package:twitter_clone/models/tweet_model.dart';

class TweetList extends ConsumerWidget {
  const TweetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black, // Assuming this is desired from the original
      child: ref.watch(getTweetsProvider).when(
        data: (tweets) {
          // Filter out replies from the main list
          final originalTweets =
              tweets.where((tweet) => tweet.repliedTo.isEmpty).toList();

          return ref.watch(getLatestTweetProvider).when(
            data: (data) {
              final newTweet = Tweet.fromMap(data.payload);
              // Only add to list if it's not a reply
              if (newTweet.repliedTo.isEmpty) {
                if (data.events.contains(
                    'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create')) {
                  // Avoid adding duplicates if already present
                  if (!originalTweets.any((t) => t.id == newTweet.id)) {
                    originalTweets.insert(0, newTweet);
                  }
                } else if (data.events.contains(
                    'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update')) {
                  final startingPoint =
                      data.events[0].lastIndexOf('documents.');
                  final endPoint = data.events[0].lastIndexOf('.update');
                  final tweetId =
                      data.events[0].substring(startingPoint + 10, endPoint);

                  var tweetIndex =
                      originalTweets.indexWhere((element) => element.id == tweetId);
                  if (tweetIndex != -1) {
                    originalTweets.removeAt(tweetIndex);
                    originalTweets.insert(tweetIndex, newTweet);
                  }
                }
              }

              if (originalTweets.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flutter_dash,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Welcome to Twitter!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                        Flexible(
                          child: Text(
                            'When you follow people, you\'ll see their Tweets here.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(getTweetsProvider);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: originalTweets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final tweet = originalTweets[index];
                    return TweetCard(tweet: tweet);
                  },
                ),
              );
            },
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.refresh(getTweetsProvider);
                      // also refresh the latest tweet provider if needed
                      ref.refresh(getLatestTweetProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
            loading: () {
              // Show loader or the potentially stale list of originalTweets
              if (originalTweets.isEmpty) return const Loader();
              return ListView.builder(
                itemCount: originalTweets.length,
                itemBuilder: (BuildContext context, int index) {
                  final tweet = originalTweets[index];
                  return TweetCard(tweet: tweet);
                },
              );
            },
          );
        },
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load tweets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(getTweetsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loading: () => const Loader(),
      ),
    );
  }
}