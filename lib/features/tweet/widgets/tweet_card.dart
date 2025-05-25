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
import 'package:timeago/timeago.dart' as timeago;

class TweetCard extends ConsumerWidget {
  final Tweet tweet;
  const TweetCard({
    super.key,
    required this.tweet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;

    return currentUser == null
        ? const Loader()
        : ref.watch(userDetailsProvider(tweet.uid)).when(
              data: (user) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Pallete.greyColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                UserProfileView.route(user),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(user.profilePic),
                              radius: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    if (user.isTwitterBlue)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: SvgPicture.asset(
                                          AssetsConstants.verifiedIcon,
                                          height: 18,
                                        ),
                                      ),
                                    Text(
                                      ' @${user.name} · ${timeago.format(
                                        tweet.tweetedAt,
                                        locale: 'en_short',
                                      )}',
                                      style: TextStyle(
                                        color: Pallete.greyColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                HashtagText(text: tweet.text),
                                if (tweet.tweetType == TweetType.image)
                                  CarouselImage(imageLinks: tweet.imageLinks),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TweetIconButton(
                                      pathName: AssetsConstants.commentIcon,
                                      text: tweet.commentIds.length.toString(),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          TwitterReplyScreen.route(tweet),
                                        );
                                      },
                                    ),
                                    TweetIconButton(
                                      pathName: AssetsConstants.retweetIcon,
                                      text: tweet.reshareCount.toString(),
                                      onTap: () {
                                        ref
                                            .read(tweetControllerProvider.notifier)
                                            .reshareTweet(
                                              tweet,
                                              currentUser,
                                              context,
                                            );
                                      },
                                    ),
                                    LikeButton(
                                      size: 25,
                                      onTap: (isLiked) async {
                                        ref
                                            .read(tweetControllerProvider.notifier)
                                            .likeTweet(tweet, currentUser);
                                        return !isLiked;
                                      },
                                      isLiked:
                                          tweet.likes.contains(currentUser.uid),
                                      likeBuilder: (isLiked) {
                                        return isLiked
                                            ? SvgPicture.asset(
                                                AssetsConstants.likeFilledIcon,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Pallete.redColor,
                                                  BlendMode.srcIn,
                                                ),
                                              )
                                            : SvgPicture.asset(
                                                AssetsConstants.likeOutlinedIcon,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Pallete.greyColor,
                                                  BlendMode.srcIn,
                                                ),
                                              );
                                      },
                                      likeCount: tweet.likes.length,
                                      countBuilder: (likeCount, isLiked, text) {
                                        return Text(
                                          text,
                                          style: TextStyle(
                                            color: isLiked
                                                ? Pallete.redColor
                                                : Pallete.whiteColor,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.share_outlined,
                                        size: 20,
                                        color: Pallete.greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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