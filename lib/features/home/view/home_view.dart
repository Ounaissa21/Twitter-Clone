import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twitter_clone/constants/contants.dart';
import 'package:twitter_clone/features/home/widgets/side_drawer.dart';
import 'package:twitter_clone/features/tweet/views/create_tweet_view.dart';
import 'package:twitter_clone/theme/theme.dart';
import 'package:twitter_clone/theme/theme_controller.dart';

class HomeView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const HomeView(),
      );
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _page = 0;

  void onPageChange(int index) {
    setState(() {
      _page = index;
    });
  }

  onCreateTweet() {
    Navigator.push(context, CreateTweetScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _page == 0 
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).iconTheme.color,
                    size: 28,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Open menu',
                ),
              ),
              title: SvgPicture.asset(
                AssetsConstants.twitterLogo,
                height: 30,
                color: Pallete.blueColor,
              ),
              // actions: [
              //   // IconButton(
              //   //   icon: Icon(
              //   //     Icons.settings_outlined,
              //   //     color: Theme.of(context).iconTheme.color,
              //   //     size: 24,
              //   //   ),
              //   //   onPressed: () {
              //   //     // Settings functionality
              //   //   },
              //     tooltip: 'Settings',
              //   ),
              // ],
            )
          : null,
      body: IndexedStack(
        index: _page,
        children: UIContants.bottomTabBarPages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateTweet,
        backgroundColor: Pallete.blueColor,
        elevation: 2,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      drawer: const SideDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Pallete.getBorderColor(isDarkMode),
              width: 0.2,
            ),
          ),
        ),
        child: CupertinoTabBar(
          currentIndex: _page,
          onTap: onPageChange,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          border: null,
          activeColor: Theme.of(context).iconTheme.color,
          inactiveColor: Pallete.getSecondaryTextColor(isDarkMode),
          iconSize: 28,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SvgPicture.asset(
                  _page == 0
                      ? AssetsConstants.homeFilledIcon
                      : AssetsConstants.homeOutlinedIcon,
                  color: _page == 0 
                      ? Theme.of(context).iconTheme.color 
                      : Pallete.getSecondaryTextColor(isDarkMode),
                  height: 26,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SvgPicture.asset(
                  AssetsConstants.searchIcon,
                  color: _page == 1 
                      ? Theme.of(context).iconTheme.color 
                      : Pallete.getSecondaryTextColor(isDarkMode),
                  height: 26,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SvgPicture.asset(
                  _page == 2
                      ? AssetsConstants.notifFilledIcon
                      : AssetsConstants.notifOutlinedIcon,
                  color: _page == 2 
                      ? Theme.of(context).iconTheme.color 
                      : Pallete.getSecondaryTextColor(isDarkMode),
                  height: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}