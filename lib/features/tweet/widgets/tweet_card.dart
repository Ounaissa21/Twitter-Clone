//import 'dart:io';
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
import 'package:twitter_clone/features/tweet/widgets/tweet_icon_button.dart';
import 'package:twitter_clone/features/user_profile/view/user_profile_view.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:twitter_clone/theme/pallete.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:timeago/timeago.dart' as timeago;

class TweetCard extends ConsumerStatefulWidget {
  final Tweet tweet;
  const TweetCard({
    super.key,
    required this.tweet,
  });

  @override
  ConsumerState<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends ConsumerState<TweetCard> {
  int currentRating = 0; // Track the current rating (0-5)

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    // Watch the botUserProvider to get the bot's UID
    final botUserAsyncValue = ref.watch(botUserProvider);

    return currentUser == null
        ? const Loader()
        : ref.watch(userDetailsProvider(widget.tweet.uid)).when(
              data: (user) {
                // Determine if the current tweet is from the bot
                final bool isBotTweet = botUserAsyncValue.when(
                  data: (botUser) => widget.tweet.uid == botUser.uid,
                  loading: () => false, // Assume not bot while loading
                  error: (err, stack) => false, // Assume not bot on error
                );

                // Health icon size is now fixed to normal (25.0)
                const double healthIconSize = 25.0;

                // Check if the current user has liked this tweet
                final bool isLiked = widget.tweet.likes.contains(currentUser.uid);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, TwitterReplyScreen.route(widget.tweet));
                  },
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context, UserProfileView.route(user));
                              },
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  user.profilePic,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.tweet.retweetedBy.isNotEmpty)
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AssetsConstants.retweetIcon,
                                        color: Pallete.greyColor,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${widget.tweet.retweetedBy} retweeted',
                                        style: const TextStyle(
                                          color: Pallete.greyColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isTwitterBlue)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                        ),
                                        child: SvgPicture.asset(
                                            AssetsConstants.verifiedIcon),
                                      ),

                                    if (!isBotTweet)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 5),
                                        child: SvgPicture.asset(
                                          AssetsConstants.Platinium1,
                                          height: healthIconSize,
                                          width: healthIconSize,
                                        ),
                                      ),

                                    Expanded(
                                      child: Text(
                                        '@${user.name} · ${timeago.format(widget.tweet.tweetedAt, locale: 'en_short')}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Pallete.greyColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                if (widget.tweet.repliedTo.isNotEmpty)
                                  ref
                                      .watch(
                                          getTweetByIdProvider(widget.tweet.repliedTo))
                                      .when(
                                        data: (repliedToTweet) {
                                          final replyingToUser = ref
                                              .watch(
                                                userDetailsProvider(
                                                  repliedToTweet.uid,
                                                ),
                                              )
                                              .value;
                                          return RichText(
                                            text: TextSpan(
                                              text: 'Replying to',
                                              style: const TextStyle(
                                                color: Pallete.greyColor,
                                                fontSize: 16,
                                              ),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        ' @${replyingToUser?.name}',
                                                    style: const TextStyle(
                                                      color: Pallete.blueColor,
                                                      fontSize: 16,
                                                    )),
                                              ],
                                            ),
                                          );
                                        },
                                        error: (error, st) => ErrorText(
                                          error: error.toString(),
                                        ),
                                        loading: () => const SizedBox(),
                                      ),

                                HashtagText(text: widget.tweet.text),
                                if (widget.tweet.tweetType == TweetType.image)
                                  CarouselImage(imageLinks: widget.tweet.imageLinks),
                                if (widget.tweet.link.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  AnyLinkPreview(
                                    displayDirection:
                                        UIDirection.uiDirectionHorizontal,
                                    link: widget.tweet.link.startsWith('https')
                                        ? widget.tweet.link
                                        : 'https://${widget.tweet.link}',
                                    errorWidget: const Text(
                                      'Failed to load preview',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    placeholderWidget:
                                        const CircularProgressIndicator(),
                                  ),
                                ],
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 10, right: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (isBotTweet) // Star rating system for bot tweets
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: List.generate(5, (index) {
                                                final starNumber = index + 1;
                                                final isStarFilled = starNumber <= currentRating;
                                                
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      currentRating = starNumber;
                                                    });
                                                    // Optional: You can add any additional logic here
                                                    // like saving the rating to local storage or showing a message
                                                    print('Rating: $starNumber stars');
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                    child: Icon(
                                                      Icons.star_rounded,
                                                      color: isStarFilled 
                                                          ? Pallete.yellowColor 
                                                          : Pallete.greyColor,
                                                      size: 25,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                            if (currentRating > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  '$currentRating star${currentRating == 1 ? '' : 's'}',
                                                  style: const TextStyle(
                                                    color: Pallete.greyColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      else // Original icons for non-bot tweets
                                        Row(
                                          children: [
                                            TweetIconButton(
                                              pathName: AssetsConstants.viewsIcon,
                                              text: (widget.tweet.commentIds.length +
                                                      widget.tweet.reshareCount +
                                                      widget.tweet.likes.length)
                                                  .toString(),
                                              onTap: () {},
                                            ),
                                            TweetIconButton(
                                              pathName: AssetsConstants.commentIcon,
                                              text:
                                                  widget.tweet.commentIds.length.toString(),
                                              onTap: () {},
                                            ),
                                            TweetIconButton(
                                              pathName: AssetsConstants.retweetIcon,
                                              text: widget.tweet.reshareCount.toString(),
                                              onTap: () {
                                                ref
                                                    .read(tweetControllerProvider
                                                        .notifier)
                                                    .reshareTweet(
                                                      widget.tweet,
                                                      currentUser,
                                                      context,
                                                    );
                                              },
                                            ),
                                            LikeButton(
                                              size: 25,
                                              onTap: (isLiked) async {
                                                ref
                                                    .read(tweetControllerProvider
                                                        .notifier)
                                                    .likeTweet(
                                                        widget.tweet, currentUser);
                                                return !isLiked;
                                              },
                                              isLiked: widget.tweet.likes
                                                  .contains(currentUser.uid),
                                              likeBuilder: (isLiked) {
                                                return isLiked
                                                    ? SvgPicture.asset(
                                                        AssetsConstants
                                                            .likeFilledIcon,
                                                        color: Pallete.redColor,
                                                      )
                                                    : SvgPicture.asset(
                                                        AssetsConstants
                                                            .likeOutlinedIcon,
                                                        color: Pallete.greyColor,
                                                      );
                                              },
                                              likeCount: widget.tweet.likes.length,
                                              countBuilder:
                                                  (likeCount, isLiked, text) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(left: 2),
                                                  child: Text(
                                                    text,
                                                    style: TextStyle(
                                                      color: isLiked
                                                          ? Pallete.redColor
                                                          : Pallete.whiteColor,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              onPressed: () {},
                                              icon: const Icon(
                                                Icons.share_outlined,
                                                size: 25,
                                                color: Pallete.greyColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Pallete.greyColor,
                      ),
                    ],
                  ),
                );
              },
              error: (error, stackTrace) => ErrorText(
                error: error.toString(),
              ),
              loading: () => const Loader(),
            );
  }
}