import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/common/error_page.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/appwrite_constants.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/features/tweet/widgets/tweet_card.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:twitter_clone/theme/pallete.dart';
import 'package:twitter_clone/theme/theme_controller.dart';

class TwitterReplyScreen extends ConsumerStatefulWidget {
  static route(Tweet tweet) => MaterialPageRoute(
        builder: (context) => TwitterReplyScreen(
          tweet: tweet,
        ),
      );

  final Tweet tweet;
  const TwitterReplyScreen({
    super.key,
    required this.tweet,
  });

  @override
  ConsumerState<TwitterReplyScreen> createState() => _TwitterReplyScreenState();
}

class _TwitterReplyScreenState extends ConsumerState<TwitterReplyScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    if (_replyController.text.trim().isNotEmpty) {
      ref.read(tweetControllerProvider.notifier).shareTweet(
        images: [],
        text: _replyController.text,
        context: context,
        repliedTo: widget.tweet.id,
        repliedToUserId: widget.tweet.uid,
      );
      _replyController.clear();
      setState(() {
        _isComposing = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
            size: 24,
          ),
        ),
        title: Text(
          'Tweet',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Original tweet
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Pallete.getBorderColor(isDarkMode),
                  width: 0.5,
                ),
              ),
            ),
            child: TweetCard(
              tweet: widget.tweet,
              isReplyInThread: false, // This is the main tweet in the reply view
              showActionsDivider: true, // Pass true to show the divider for actions
            ),
          ),
          // REMOVE THE DIVIDER FROM HERE, AS IT'S NOW INSIDE TweetCard for the original tweet
          // Divider(...), // <-- Remove this line

          // Replies list
          Expanded(
            child: ref.watch(getRepliesToTweetProvider(widget.tweet)).when(
              data: (tweets) {
                return ref.watch(getLatestTweetProvider).when(
                  data: (data) {
                    final latestTweet = Tweet.fromMap(data.payload);
                    bool isTweetAlreadyPresent = tweets.any((t) => t.id == latestTweet.id);

                    if (!isTweetAlreadyPresent && latestTweet.repliedTo == widget.tweet.id) {
                      if (data.events.contains(
                        'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create',
                      )) {
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted) {
                           }
                         });
                         final modifiableTweets = List<Tweet>.from(tweets);
                         modifiableTweets.insert(0, latestTweet);
                      } else if (data.events.contains(
                        'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update',
                      )) {
                        final tweetId = data.payload['\$id'];
                        final tweetIndex = tweets.indexWhere((element) => element.id == tweetId);
                        if (tweetIndex != -1) {
                        }
                      }
                    }
                    
                    if (tweets.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No replies yet', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                              SizedBox(height: 8),
                              Text('Be the first to reply!', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: tweets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final tweet = tweets[index];
                        return TweetCard(
                          tweet: tweet,
                          isReplyInThread: true, // Pass true for replies, no action divider
                          showActionsDivider: false, // Ensure divider is not shown for replies
                        );
                      },
                    );
                  },
                  error: (error, stackTrace) => ErrorText(error: error.toString()),
                  loading: () {
                    if (tweets.isEmpty) return const Loader();
                    return ListView.builder(
                      itemCount: tweets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final tweet = tweets[index];
                        return TweetCard(tweet: tweet, isReplyInThread: true, showActionsDivider: false);
                      },
                    );
                  },
                );
              },
              error: (error, stackTrace) => ErrorText(error: error.toString()),
              loading: () => const Loader(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Pallete.getBorderColor(isDarkMode),
              width: 0.2,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _isComposing ? Pallete.blueColor : (isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tweet your reply',
                        hintStyle: TextStyle(
                          color: Pallete.getSecondaryTextColor(isDarkMode),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: (_) => _sendReply(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isComposing ? Pallete.blueColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isComposing ? _sendReply : null,
                    icon: Icon(
                      Icons.send,
                      color: _isComposing ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}