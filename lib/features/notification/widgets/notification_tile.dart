import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitter_clone/apis/user_api.dart';
import 'package:twitter_clone/constants/contants.dart';
import 'package:twitter_clone/core/enums/notification_type_enum.dart';
import 'package:twitter_clone/features/auth/controller/auth_controller.dart';
import 'package:twitter_clone/models/notification_model.dart' as model;
import 'package:twitter_clone/theme/pallete.dart';
import 'package:timeago/timeago.dart' as timeago;

class TwitterNotificationTile extends ConsumerWidget {
  final model.Notification notification;
  
  const TwitterNotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.2,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to the related tweet/post
          // You can implement navigation to tweet details here
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _getNotificationIcon(),
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        children: _buildNotificationText(),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Timestamp
                    Text(
                      _getTimeAgo(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon() {
    switch (notification.notificationType) {
      case NotificationType.like:
        return SvgPicture.asset(
          AssetsConstants.likeFilledIcon,
          color: Colors.red,
          height: 20,
        );
      case NotificationType.retweet:
        return SvgPicture.asset(
          AssetsConstants.retweetIcon,
          color: Colors.green,
          height: 20,
        );
      case NotificationType.follow:
        return const Icon(
          Icons.person_add,
          color: Colors.blue,
          size: 20,
        );
      case NotificationType.reply:
        return SvgPicture.asset(
          AssetsConstants.commentIcon,
          color: Colors.blue,
          height: 20,
        );
      default:
        return const Icon(
          Icons.notifications,
          color: Colors.grey,
          size: 20,
        );
    }
  }

  Color _getNotificationColor() {
    switch (notification.notificationType) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.retweet:
        return Colors.green;
      case NotificationType.follow:
        return Colors.blue;
      case NotificationType.reply:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<TextSpan> _buildNotificationText() {
    final parts = notification.text.split(' ');
    final spans = <TextSpan>[];
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      if (part.startsWith('@')) {
        // Highlight mentions
        spans.add(TextSpan(
          text: part,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else {
        spans.add(TextSpan(text: part));
      }
      
      // Add space between words (except for the last word)
      if (i < parts.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    
    return spans;
  }

  String _getTimeAgo() {
    // Since the notification model might not have a timestamp,
    // we'll use a placeholder. In a real app, you'd add a timestamp field
    // to your notification model
    return timeago.format(DateTime.now().subtract(const Duration(hours: 2)), locale: 'en_short');
  }

  bool _shouldShowAvatar() {
    // Show avatar for follow notifications and replies
    return notification.notificationType == NotificationType.follow ||
           notification.notificationType == NotificationType.reply;
  }
}

// Keep the original NotificationTile for backward compatibility
class NotificationTile extends StatelessWidget {
  final model.Notification notification;
  const NotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return TwitterNotificationTile(notification: notification);
  }
}