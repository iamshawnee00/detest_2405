// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart'; // To get current userId
import '../../providers/restaurant_provider.dart'; // For deep linking to restaurant
// import '../../providers/group_provider.dart'; // Commented out as GroupDetailScreen and its usage are pending
import '../../models/notification_model.dart';
import '../../models/restaurant_model.dart'; // For deep linking
// import '../../models/group_model.dart'; // Commented out as it might become unused
import '../restaurant/restaurant_detail_screen.dart'; // Example for deep linking
// import '../groups/group_detail_screen.dart'; // Commented out: Target of URI doesn't exist

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserNotifications();
    });
  }

  Future<void> _fetchUserNotifications() async {
    // Check for mounted before accessing context after potential async gap
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    String? currentUserId = authProvider.userModel?.id;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      await notificationProvider.fetchNotifications(currentUserId);
    } else {
      if (mounted) { // Guard use of BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not identified. Cannot fetch notifications.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    String? currentUserId = authProvider.userModel?.id;

    if (currentUserId == null || currentUserId.isEmpty) return;

    if (!notification.isRead) {
      await notificationProvider.markAsRead(currentUserId, notification.id);
    }

    if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
      Uri uri = Uri.parse(notification.deepLink!);
      if (uri.scheme == 'foodieapp' && mounted) { 
        if (uri.host == 'restaurant' && uri.pathSegments.isNotEmpty) {
          String restaurantId = uri.pathSegments.first;
          final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
          final List<RestaurantModel> restaurants = await restaurantProvider.getRestaurantsByIds([restaurantId]);
          
          if (!mounted) return; 
          if (restaurants.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: restaurants.first)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open restaurant: $restaurantId')));
          }
        } else if (uri.host == 'group' && uri.pathSegments.isNotEmpty) {
          String groupId = uri.pathSegments.first;
          // final groupProvider = Provider.of<GroupProvider>(context, listen: false); // Commented out
          // TODO: Fetch GroupModel using groupId and navigate to GroupDetailScreen
          // For now, just showing a message as GroupDetailScreen and provider logic is pending.
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to group: $groupId (Detail Screen Pending)')));
        } else {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on: ${notification.title} (Deep link: ${notification.deepLink})')));
        }
      }
    } else {
      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on: ${notification.title}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final List<NotificationModel> notifications = notificationProvider.notifications;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () {
                String? userId = authProvider.userModel?.id;
                if (userId != null && userId.isNotEmpty) {
                  notificationProvider.markAllAsRead(userId);
                }
              },
              child: const Text("Mark All Read"),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserNotifications,
            tooltip: "Refresh Notifications",
          )
        ],
      ),
      body: notificationProvider.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.errorMessage != null && notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text("Error Loading Notifications", style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(notificationProvider.errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            onPressed: _fetchUserNotifications,
                        )
                      ],
                    ),
                  ),
                )
              : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            'No Notifications Yet',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ll let you know when something new comes up!',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUserNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.isRead 
                                  ? Colors.grey.shade300 
                                  : Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                              child: Icon(
                                _getIconForNotificationType(notification.type),
                                color: notification.isRead 
                                    ? Colors.grey.shade600
                                    : Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                color: notification.isRead ? Colors.grey.shade700 : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              notification.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTimeAgo(notification.createdAt),
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                                if (!notification.isRead)
                                  const SizedBox(height: 4),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _handleNotificationTap(notification),
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                      ),
                    ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 365) {
      return '${(duration.inDays / 365).floor()}y ago';
    } if (duration.inDays > 30) {
      return '${(duration.inDays / 30).floor()}mo ago';
    } if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inSeconds > 10){
      return '${duration.inSeconds}s ago';
    }
     else {
      return 'Just now';
    }
  }

  IconData _getIconForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.newRestaurant:
        return Icons.storefront_outlined;
      case NotificationType.groupActivity:
        return Icons.group_work_outlined;
      case NotificationType.friendRequest:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.recommendation:
        return Icons.star_outline;
      case NotificationType.promotion:
        return Icons.campaign_outlined;
      case NotificationType.general: 
        return Icons.notifications_outlined;
    }
  }
}
