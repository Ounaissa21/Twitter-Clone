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
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(currentUser.profilePic),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${currentUser.name}',
                    style: TextStyle(
                      color: Pallete.getSecondaryTextColor(isDarkMode),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${currentUser.following.length}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' Following',
                        style: TextStyle(
                          color: Pallete.getSecondaryTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${currentUser.followers.length}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' Followers',
                        style: TextStyle(
                          color: Pallete.getSecondaryTextColor(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Pallete.getBorderColor(isDarkMode), height: 1),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, UserProfileView.route(currentUser));
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.bookmark_border,
                    title: 'Bookmarks',
                    onTap: () {
                      Navigator.pop(context);
                      // Add bookmarks functionality
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.list_alt,
                    title: 'Lists',
                    onTap: () {
                      Navigator.pop(context);
                      // Add lists functionality
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    iconWidget: SvgPicture.asset(
                      AssetsConstants.verifiedIcon,
                      height: 24,
                      color: Colors.blue,
                    ),
                    title: 'Twitter Blue',
                    subtitle: currentUser.isTwitterBlue ? 'Subscribed' : 'Get verified',
                    onTap: () {
                      Navigator.pop(context);
                      if (!currentUser.isTwitterBlue) {
                        ref
                            .read(userProfileControllerProvider.notifier)
                            .updateUserProfile(
                                userModel: currentUser.copyWith(isTwitterBlue: true),
                                context: context,
                                bannerFile: null,
                                profileFile: null);
                      }
                    },
                  ),
                  
                  // Theme toggle item
                  _buildDrawerItem(
                    context: context,
                    icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    title: 'Display',
                    subtitle: isDarkMode ? 'Dark mode' : 'Light mode',
                    onTap: () {
                      _showThemeDialog(context, ref);
                    },
                  ),
                  
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings and privacy',
                    onTap: () {
                      Navigator.pop(context);
                      // Add settings functionality
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {
                      Navigator.pop(context);
                      // Add help functionality
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom section
            Divider(color: Pallete.getBorderColor(isDarkMode), height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: 'Log out',
              onTap: () {
                ref.read(authControllerProvider.notifier).logout(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: iconWidget ?? Icon(
        icon,
        color: Theme.of(context).iconTheme.color,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final themeController = ref.read(themeModeProvider.notifier);
    final currentTheme = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Choose display',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context: context,
                title: 'Light',
                subtitle: 'Light mode',
                icon: Icons.light_mode,
                isSelected: currentTheme == ThemeMode.light,
                onTap: () {
                  themeController.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context: context,
                title: 'Dark',
                subtitle: 'Dark mode',
                icon: Icons.dark_mode,
                isSelected: currentTheme == ThemeMode.dark,
                onTap: () {
                  themeController.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context: context,
                title: 'System',
                subtitle: 'Use device setting',
                icon: Icons.settings_system_daydream,
                isSelected: currentTheme == ThemeMode.system,
                onTap: () {
                  themeController.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Pallete.blueColor,
            )
          : null,
      onTap: onTap,
    );
  }
}