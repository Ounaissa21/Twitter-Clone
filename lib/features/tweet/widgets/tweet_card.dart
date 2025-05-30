import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:like_button/like_button.dart';
import 'package:twitter_clone/common/error_page.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/assets_constants.dart';
import 'package:twitter_clone/core/enums/tweet_type_enum.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/features/tweet/views/twitter_reply_view.dart';
import 'package:twitter_clone/features/tweet/widgets/carousel_image.dart';
import 'package:twitter_clone/features/tweet/widgets/hashtag_text.dart';
import 'package:twitter_clone/features/user_profile/view/user_profile_view.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:twitter_clone/theme/pallete.dart';
import 'package:twitter_clone/theme/theme_controller.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:timeago/timeago.dart' as timeago;

class TweetCard extends ConsumerStatefulWidget {
  final Tweet tweet;
  final bool isReplyInThread;
  final bool showActionsDivider;
  const TweetCard({
    super.key,
    required this.tweet,
    this.isReplyInThread = false,
    this.showActionsDivider = false,
  });

  @override
  ConsumerState<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends ConsumerState<TweetCard> {
  int currentRating = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;

    final botUserAsyncValue = ref.watch(botUserProvider);

    return currentUser == null
        ? const Loader()
        : ref.watch(userDetailsProvider(widget.tweet.uid)).when(
              data: (user) {
                final bool isBotTweet = botUserAsyncValue.when(
                  data: (botUser) => widget.tweet.uid == botUser.uid,
                  loading: () => false,
                  error: (err, stack) => false,
                );

                return GestureDetector(
                  onTap: () {
                    if (!widget.isReplyInThread) {
                       Navigator.push(context, TwitterReplyScreen.route(widget.tweet));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Pallete.getBorderColor(isDarkMode),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.tweet.retweetedBy.isNotEmpty && !widget.isReplyInThread)
                            Padding(
                              padding: const EdgeInsets.only(left: 40.0, bottom: 4.0, right: 16.0),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    AssetsConstants.retweetIcon,
                                    color: Pallete.getSecondaryTextColor(isDarkMode),
                                    height: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.tweet.retweetedBy} retweeted',
                                    style: TextStyle(
                                      color: Pallete.getSecondaryTextColor(isDarkMode),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.isReplyInThread)
                                  SizedBox(
                                    width: 50,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          left: 24,
                                          child: Container(
                                            width: 2,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 0),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(context, UserProfileView.route(user));
                                            },
                                            child: CircleAvatar(
                                              radius: 18,
                                              backgroundImage: NetworkImage(user.profilePic),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, UserProfileView.route(user));
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(user.profilePic),
                                      ),
                                    ),
                                  ),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user.name,
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (user.isTwitterBlue) ...[
                                            const SizedBox(width: 4),
                                            SvgPicture.asset(
                                              AssetsConstants.verifiedIcon,
                                              height: 16,
                                            ),
                                          ],
                                          if (!isBotTweet && !widget.isReplyInThread) ...[
                                            const SizedBox(width: 4),
                                            SvgPicture.asset(
                                              user.getBadgeAsset(),
                                              height: 18,
                                              width: 18,
                                            ),
                                          ],
                                          const SizedBox(width: 4),
                                          
                                             Text(
                                              '@${user.name} · ${timeago.format(widget.tweet.tweetedAt, locale: 'en_short')}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Pallete.getSecondaryTextColor(isDarkMode),
                                                fontWeight: FontWeight.w400,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              // Show more options
                                            },
                                            child: Icon(
                                              Icons.more_horiz,
                                              color: Pallete.getSecondaryTextColor(isDarkMode),
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 4),
                                      
                                      if (widget.tweet.repliedTo.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: ref.watch(getTweetByIdProvider(widget.tweet.repliedTo)).when(
                                                data: (repliedToTweet) {
                                                  final replyingToUserAsyncValue = ref.watch(userDetailsProvider(repliedToTweet.uid));
                                                  return replyingToUserAsyncValue.when(
                                                    data: (replyingToUser) => RichText(
                                                      text: TextSpan(
                                                        text: 'Replying to ',
                                                        style: TextStyle(
                                                          color: Pallete.getSecondaryTextColor(isDarkMode),
                                                          fontSize: 15,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: '@${replyingToUser.name}',
                                                            style: const TextStyle(
                                                              color: Pallete.blueColor,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    loading: () => const SizedBox(),
                                                    error: (e, st) => const SizedBox(),
                                                  );
                                                },
                                                error: (error, st) => const SizedBox(),
                                                loading: () => const SizedBox(),
                                              ),
                                        ),
                                      
                                      HashtagText(text: widget.tweet.text),
                                      
                                      if (widget.tweet.tweetType == TweetType.image) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: CarouselImage(imageLinks: widget.tweet.imageLinks),
                                        ),
                                      ],
                                      
                                      if (widget.tweet.link.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Pallete.getBorderColor(isDarkMode),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: AnyLinkPreview(
                                              displayDirection: UIDirection.uiDirectionHorizontal,
                                              link: widget.tweet.link.startsWith('http')
                                                  ? widget.tweet.link
                                                  : 'https://${widget.tweet.link}',
                                              errorWidget: Container(
                                                padding: const EdgeInsets.all(16),
                                                child: Text(
                                                  'Failed to load preview',
                                                  style: TextStyle(color: Pallete.getSecondaryTextColor(isDarkMode)),
                                                ),
                                              ),
                                              placeholderWidget: Container(
                                                padding: const EdgeInsets.all(16),
                                                child: const CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (widget.showActionsDivider)
                            const Divider(
                              height: 24,
                              thickness: 0.5,
                              color: Colors.grey,
                            ),
                          
                          if (isBotTweet)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end, // Aligns the Column's content to the end
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end, // Aligns the stars within the Row to the end
                                    children: List.generate(5, (index) {
                                      final starNumber = index + 1;
                                      final isStarFilled = starNumber <= currentRating;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            currentRating = starNumber;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.star_rounded,
                                            color: isStarFilled 
                                                ? Pallete.yellowColor 
                                                : Pallete.getSecondaryTextColor(isDarkMode),
                                            size: 20,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  if (currentRating > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Rated $currentRating star${currentRating == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          color: Pallete.getSecondaryTextColor(isDarkMode),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.chat_bubble_outline,
                                    count: widget.tweet.commentIds.length,
                                    color: Pallete.getSecondaryTextColor(isDarkMode),
                                    onTap: () {
                                       Navigator.push(context, TwitterReplyScreen.route(widget.tweet));
                                    },
                                  ),
                                  _buildActionButton(
                                    icon: Icons.repeat,
                                    count: widget.tweet.reshareCount,
                                    color: Pallete.getSecondaryTextColor(isDarkMode),
                                    onTap: () {
                                      ref.read(tweetControllerProvider.notifier).reshareTweet(
                                            widget.tweet,
                                            currentUser,
                                            context,
                                          );
                                    },
                                  ),
                                  LikeButton(
                                    size: 18,
                                    onTap: (isLiked) async {
                                      ref.read(tweetControllerProvider.notifier).likeTweet(widget.tweet, currentUser);
                                      return !isLiked;
                                    },
                                    isLiked: widget.tweet.likes.contains(currentUser.uid),
                                    likeBuilder: (isLiked) {
                                      return Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Pallete.redColor : Pallete.getSecondaryTextColor(isDarkMode),
                                        size: 18,
                                      );
                                    },
                                    likeCount: widget.tweet.likes.length,
                                    countBuilder: (likeCount, isLiked, text) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: isLiked ? Pallete.redColor : Pallete.getSecondaryTextColor(isDarkMode),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildActionButton(
                                    icon: Icons.share_outlined,
                                    count: 0,
                                    color: Pallete.getSecondaryTextColor(isDarkMode),
                                    onTap: () {
                                      // Implement share functionality
                                    },
                                    showCount: false,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.bar_chart_outlined,
                                    count: (widget.tweet.commentIds.length +
                                            widget.tweet.reshareCount +
                                            widget.tweet.likes.length),
                                    color: Pallete.getSecondaryTextColor(isDarkMode),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              error: (error, stackTrace) => ErrorText(
                error: error.toString(),
              ),
              loading: () => const Loader(),
            );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool showCount = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            if (showCount && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}