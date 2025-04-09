import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/common/error_page.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/features/tweet/widgets/tweet_card.dart';


class HashtagView extends ConsumerWidget {
 static route(String hashtag) => MaterialPageRoute(
        builder: (context) =>  HashtagView(
          hashtag : hashtag,
        ),
      );
  final String hashtag;
  const HashtagView({super.key, required  this.hashtag,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hashtag'),
      ),
      body: ref.watch(getTweetsByHashtagProvider(hashtag)).when(
          data: (tweets) {
                    // if (data.events.contains(
                    //     'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create')) {
                    //   tweets.insert(0, Tweet.fromMap(data.payload));
                    // } else if (data.events.contains(
                    //     'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update')) {
                         
                    //       //get id of the original tweet
                    //   final startingPoint = data.events[0].lastIndexOf('documents.');
                    //   final endPoint = data.events[0].lastIndexOf('.update');
                    //   final tweetId = data.events[0].substring(startingPoint + 10, endPoint );

                    //   var tweet = tweets
                    //       .where((element) => element.id == tweetId)
                    //       .first;

                    //   //get the index to remove it
                    //   final tweetIndex = tweets.indexOf(tweet);
                    //   tweets.removeWhere((element) => element.id == tweetId);
                      
                    //   tweet = Tweet.fromMap(data.payload);
                    //   tweets.insert(tweetIndex, tweet);

                    // }
                    // Handle the latest tweet here if needed
                    return ListView.builder(
                      itemCount: tweets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final tweet = tweets[index];
                        return TweetCard(
                            tweet: tweet); // Replace with your tweet widget
                      },
                    );
                  },
                 
               
          error: (error, stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const Loader(),)
      );
  }
  }

