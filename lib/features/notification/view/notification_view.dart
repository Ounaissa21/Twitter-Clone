import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/common/error_page.dart';
import 'package:twitter_clone/common/loading_page.dart';
import 'package:twitter_clone/constants/appwrite_constants.dart';
import 'package:twitter_clone/core/enums/notification_type_enum.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/features/notification/controller/notification_controller.dart';
import 'package:twitter_clone/features/notification/widgets/notification_tile.dart';
import 'package:twitter_clone/models/notification_model.dart' as model;

class NotificationView extends ConsumerStatefulWidget {
  const NotificationView({super.key});

  @override
  ConsumerState<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends ConsumerState<NotificationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              // Settings functionality
            },
          ),
        ],
        bottom: TabBar(
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
            Tab(text: 'All'),
            Tab(text: 'Mentions'),
          ],
        ),
      ),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Loader();
          }
          return TabBarView(
            controller: _tabController,
            children: [
              // All notifications tab
              _buildNotificationsList(currentUser.uid, false),
              // Mentions tab (filtered notifications)
              _buildNotificationsList(currentUser.uid, true),
            ],
          );
        },
        error: (error, stackTrace) => _buildErrorState(error.toString()),
        loading: () => const Loader(),
      ),
    );
  }

  Widget _buildNotificationsList(String uid, bool mentionsOnly) {
    return ref.watch(getNotificationsProvider(uid)).when(
      data: (notifications) {
        // Filter notifications for mentions tab
        final filteredNotifications = mentionsOnly
            ? notifications.where((n) => 
                n.notificationType == NotificationType.reply ||
                n.text.contains('@')).toList()
            : notifications;

        return ref.watch(getLatestNotificationProvider).when(
          data: (data) {
            if (data.events.contains(
              'databases.*.collections.${AppwriteConstants.notificationsCollection}.documents.*.create',
            )) {
              final latestNotif = model.Notification.fromMap(data.payload);
              if (latestNotif.uid == uid) {
                // Check if notification already exists to avoid duplicates
                bool exists = filteredNotifications.any((n) => n.id == latestNotif.id);
                if (!exists) {
                  if (mentionsOnly) {
                    if (latestNotif.notificationType == NotificationType.reply ||
                        latestNotif.text.contains('@')) {
                      filteredNotifications.insert(0, latestNotif);
                    }
                  } else {
                    filteredNotifications.insert(0, latestNotif);
                  }
                }
              }
            }

            if (filteredNotifications.isEmpty) {
              return _buildEmptyState(mentionsOnly);
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.refresh(getNotificationsProvider(uid));
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredNotifications.length,
                itemBuilder: (BuildContext context, int index) {
                  final notification = filteredNotifications[index];
                  return TwitterNotificationTile(notification: notification);
                },
              ),
            );
          },
          error: (error, stackTrace) => _buildErrorState(error.toString()),
          loading: () {
            if (filteredNotifications.isEmpty) {
              return const Loader();
            }
            return ListView.builder(
              itemCount: filteredNotifications.length,
              itemBuilder: (BuildContext context, int index) {
                final notification = filteredNotifications[index];
                return TwitterNotificationTile(notification: notification);
              },
            );
          },
        );
      },
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      loading: () => const Loader(),
    );
  }

  Widget _buildEmptyState(bool isMentions) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMentions ? Icons.alternate_email : Icons.notifications_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isMentions ? 'No mentions yet' : 'No notifications yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isMentions 
                  ? 'When someone mentions you, you\'ll find it here.'
                  : 'When you get notifications, they\'ll show up here.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              error,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh notifications
                final currentUser = ref.read(currentUserDetailsProvider).value;
                if (currentUser != null) {
                  ref.refresh(getNotificationsProvider(currentUser.uid));
                }
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
    );
  }
}