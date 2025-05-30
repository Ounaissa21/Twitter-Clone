import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/assets_constants.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/user_profile/controller/user_profile_controller.dart';
import 'package:twitter_clone/features/user_profile/view/user_profile_view.dart';
import 'package:twitter_clone/theme/pallete.dart';
import 'package:twitter_clone/theme/theme_controller.dart';

class SideDrawer extends ConsumerWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final themeController = ref.watch(themeModeProvider.notifier);
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;

    if (currentUser == null) {
      return const Loader();
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with user info
            ListTile(
              leading: CircleAvatar(
                backgroundImage: currentUser.profilePic.isNotEmpty
                    ? NetworkImage(currentUser.profilePic)
                    : const NetworkImage(
                  'https://www.gravatar.com/avatar/2c7d99fe281ecd3f689421808609ce6a?s=250&d=mm&r=x',
                ),
                
                radius: 30,
              ),
              title: Text(
                currentUser.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '@${currentUser.name}',
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: Text(
                    '${currentUser.following.length}',
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: const Text(
                    ' Following',
                    style: TextStyle(
                      fontSize: 17,
                      color: Pallete.greyColor,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: Text(
                    '${currentUser.followers.length}',
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: const Text(
                    ' Followers',
                    style: TextStyle(
                      fontSize: 17,
                      color: Pallete.greyColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Pallete.greyColor),

            // Profile
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  UserProfileView.route(currentUser),
                );
              },
                leading: Icon(
                Icons.person,
                color: Theme.of(context).iconTheme.color,
                size: 28,
                ),
                title: Text(
                'Profile',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                ),
              ),
            ),

            // Twitter Blue
            ListTile(
              onTap: () {},
              leading: SvgPicture.asset(
                AssetsConstants.verifiedIcon,
                color: Pallete.blueColor,
                height: 28,
              ),
              title: Text(
                'Twitter Blue',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                ),
              ),
            ),

            // Logout
            ListTile(
              onTap: () {
                ref.read(authControllerProvider.notifier).logout(context);
              },
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).iconTheme.color,
                size: 28,
              ),
              title: Text(
                'Log Out',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}