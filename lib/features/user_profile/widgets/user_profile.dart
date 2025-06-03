import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitter_clone/common/common.dart';
import 'package:twitter_clone/constants/appwrite_constants.dart';
import 'package:twitter_clone/constants/assets_constants.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/tweet/controller/tweet_controller.dart';
import 'package:twitter_clone/features/tweet/widgets/tweet_card.dart';
import 'package:twitter_clone/features/user_profile/controller/user_profile_controller.dart';
import 'package:twitter_clone/features/user_profile/view/edit_profile_view.dart';
import 'package:twitter_clone/features/user_profile/widgets/follow_count.dart';
import 'package:twitter_clone/models/tweet_model.dart';
import 'package:twitter_clone/models/user_model.dart';
import 'package:twitter_clone/theme/pallete.dart';

class UserProfile extends ConsumerStatefulWidget {
  final UserModel user;
  const UserProfile({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<UserProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get badge name from health points
  String _getBadgeName(int healthPoints) {
    if (healthPoints >= 50) return 'Platinum';
    if (healthPoints >= 25) return 'Gold';
    if (healthPoints >= 15) return 'Silver';
    if (healthPoints >= 5) return 'Bronze';
    return 'Iron';
  }

  // Helper method to get next level requirements
  Map<String, dynamic> _getNextLevelInfo(int healthPoints) {
    if (healthPoints < 5) {
      return {'nextLevel': 'Bronze', 'pointsNeeded': 5 - healthPoints, 'totalNeeded': 5};
    } else if (healthPoints < 15) {
      return {'nextLevel': 'Silver', 'pointsNeeded': 15 - healthPoints, 'totalNeeded': 15};
    } else if (healthPoints < 25) {
      return {'nextLevel': 'Gold', 'pointsNeeded': 25 - healthPoints, 'totalNeeded': 25};
    } else if (healthPoints < 50) {
      return {'nextLevel': 'Platinum', 'pointsNeeded': 50 - healthPoints, 'totalNeeded': 50};
    } else {
      return {'nextLevel': 'Max Level', 'pointsNeeded': 0, 'totalNeeded': 50};
    }
  }

  // Helper method to calculate progress percentage
  double _getProgressPercentage(int healthPoints) {
    if (healthPoints < 5) {
      return healthPoints / 5;
    } else if (healthPoints < 15) {
      return (healthPoints - 5) / 10;
    } else if (healthPoints < 25) {
      return (healthPoints - 15) / 10;
    } else if (healthPoints < 50) {
      return (healthPoints - 25) / 25;
    } else {
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;

    return currentUser == null
        ? const Loader()
        : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      onPressed: () {
                        // More options menu
                      },
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                // Profile Header
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Banner and Profile Image
                      SizedBox(
                        height: 240,
                        child: Stack(
                          children: [
                            // Banner
                            Container(
                              width: double.infinity,
                              height: 180,
                              child: widget.user.bannerPic.isEmpty
                                  ? Container(color: Colors.grey[800])
                                  : Image.network(
                                      widget.user.bannerPic,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            // Profile Image
                            Positioned(
                              bottom: 20,
                              left: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(widget.user.profilePic),
                                  radius: 40,
                                ),
                              ),
                            ),
                            // Action Button
                            Positioned(
                              bottom: 20,
                              right: 16,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (currentUser.uid == widget.user.uid) {
                                    Navigator.push(context, EditProfileView.route());
                                  } else {
                                    ref
                                        .read(userProfileControllerProvider.notifier)
                                        .followUser(
                                          user: widget.user,
                                          context: context,
                                          currentUser: currentUser,
                                        );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentUser.uid == widget.user.uid
                                      ? Colors.transparent
                                      : currentUser.following.contains(widget.user.uid)
                                          ? Colors.white
                                          : Colors.blue,
                                  foregroundColor: currentUser.uid == widget.user.uid
                                      ? Colors.white
                                      : currentUser.following.contains(widget.user.uid)
                                          ? Colors.black
                                          : Colors.white,
                                  side: BorderSide(
                                    color: currentUser.uid == widget.user.uid
                                        ? Colors.grey[600]!
                                        : Colors.transparent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  currentUser.uid == widget.user.uid
                                      ? 'Edit profile'
                                      : currentUser.following.contains(widget.user.uid)
                                          ? 'Following'
                                          : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // User Info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and Verification with Health Badge
                            Row(
                              children: [
                                Text(
                                  widget.user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (widget.user.isTwitterBlue) ...[
                                  const SizedBox(width: 4),
                                  SvgPicture.asset(
                                    AssetsConstants.verifiedIcon,
                                    height: 20,
                                  ),
                                ],
                                const SizedBox(width: 8),
                                // Health Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        widget.user.getBadgeAsset(),
                                        height: 16,
                                        width: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getBadgeName(widget.user.healthPoints),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Health Points Summary
                            const SizedBox(height: 8),
                            Text(
                              '${widget.user.healthPoints} points • ${widget.user.healthPoints} healthy tweets',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            
                            // Username
                            const SizedBox(height: 4),
                            Text(
                              '@${widget.user.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            
                            // Bio
                            if (widget.user.bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.user.bio,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Follow Counts
                            Row(
                              children: [
                                FollowCount(
                                  count: widget.user.following.length,
                                  text: ' Following',
                                ),
                                const SizedBox(width: 20),
                                FollowCount(
                                  count: widget.user.followers.length,
                                  text: ' Followers',
                                ),
                              ],
                            ),
                            
                            // Badge Progress Section
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[800]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Badge Progress',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Current Badge Info
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        widget.user.getBadgeAsset(),
                                        height: 32,
                                        width: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_getBadgeName(widget.user.healthPoints)} Badge',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '${widget.user.healthPoints} healthy tweets',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${widget.user.healthPoints} pts',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Progress Bar
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${widget.user.healthPoints} points',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final nextLevelInfo = _getNextLevelInfo(widget.user.healthPoints);
                                              if (nextLevelInfo['pointsNeeded'] == 0) {
                                                return const Text(
                                                  'Max level reached!',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              }
                                              return Text(
                                                '${nextLevelInfo['pointsNeeded']} needed for ${nextLevelInfo['nextLevel']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: _getProgressPercentage(widget.user.healthPoints),
                                        backgroundColor: Colors.grey[700],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          widget.user.healthPoints >= 50 
                                              ? Colors.purple 
                                              : widget.user.healthPoints >= 25 
                                                  ? Colors.amber 
                                                  : widget.user.healthPoints >= 15 
                                                      ? Colors.grey 
                                                      : widget.user.healthPoints >= 5 
                                                          ? Colors.orange 
                                                          : Colors.brown,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.blue,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: const [
                        Tab(text: 'Tweets'),
                        Tab(text: 'Replies'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tweets Tab
                _buildTweetsList(),
                // Replies Tab
                _buildRepliesList(),
              ],
            ),
          );
  }

  Widget _buildTweetsList() {
    return ref.watch(getUserTweetsProvider(widget.user.uid)).when(
          data: (tweets) {
            return ref.watch(getLatestTweetProvider).when(
              data: (data) {
                final latestTweet = Tweet.fromMap(data.payload);

                bool isTweetAlreadyPresent = false;
                for (final tweetModel in tweets) {
                  if (tweetModel.id == latestTweet.id) {
                    isTweetAlreadyPresent = true;
                    break;
                  }
                }

                if (!isTweetAlreadyPresent && latestTweet.uid == widget.user.uid) {
                  if (data.events.contains(
                    'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create',
                  )) {
                    tweets.insert(0, Tweet.fromMap(data.payload));
                  } else if (data.events.contains(
                    'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update',
                  )) {
                    final startingPoint = data.events[0].lastIndexOf('documents.');
                    final endPoint = data.events[0].lastIndexOf('.update');
                    final tweetId = data.events[0].substring(startingPoint + 10, endPoint);

                    var tweet = tweets.where((element) => element.id == tweetId).first;
                    final tweetIndex = tweets.indexOf(tweet);
                    tweets.removeWhere((element) => element.id == tweetId);

                    tweet = Tweet.fromMap(data.payload);
                    tweets.insert(tweetIndex, tweet);
                  }
                }

                if (tweets.isEmpty) {
                  return _buildEmptyState('No tweets yet');
                }

                return ListView.builder(
                  itemCount: tweets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final tweet = tweets[index];
                    return TweetCard(tweet: tweet);
                  },
                );
              },
              error: (error, stackTrace) => ErrorText(error: error.toString()),
              loading: () {
                return ListView.builder(
                  itemCount: tweets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final tweet = tweets[index];
                    return TweetCard(tweet: tweet);
                  },
                );
              },
            );
          },
          error: (error, st) => ErrorText(error: error.toString()),
          loading: () => const Loader(),
        );
  }

  Widget _buildRepliesList() {
    // Filter tweets that are replies
    return ref.watch(getUserTweetsProvider(widget.user.uid)).when(
      data: (tweets) {
        final replies = tweets.where((tweet) => tweet.repliedTo.isNotEmpty).toList();
        
        if (replies.isEmpty) {
          return _buildEmptyState('No replies yet');
        }

        return ListView.builder(
          itemCount: replies.length,
          itemBuilder: (BuildContext context, int index) {
            final tweet = replies[index];
            return TweetCard(tweet: tweet);
          },
        );
      },
      error: (error, st) => ErrorText(error: error.toString()),
      loading: () => const Loader(),
    );
  }

  

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flutter_dash,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}