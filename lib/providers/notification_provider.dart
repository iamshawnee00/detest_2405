// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/notification_model.dart'; // Assuming this path is correct

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5, lineLength: 100, colors: true, printEmojis: true, dateTimeFormat: DateTimeFormat.none));

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Fetches notifications for a specific user
  Future<void> fetchNotifications(String userId) async {
    if (userId.isEmpty) {
      _logger.w("fetchNotifications called with empty userId.");
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications') // Storing notifications as a subcollection of user
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit the number of notifications fetched
          .get();

      _notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
      _logger.i("Fetched ${_notifications.length} notifications for user $userId.");
    } catch (e, s) {
      _logger.e('Error fetching notifications for user $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to load notifications.";
      _notifications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Marks a specific notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    if (userId.isEmpty || notificationId.isEmpty) {
      _logger.w("markAsRead called with empty userId or notificationId.");
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].isRead = true;
        notifyListeners();
        _logger.i("Marked notification $notificationId for user $userId as read.");
      }
    } catch (e, s) {
      _logger.e('Error marking notification $notificationId as read for user $userId', error: e, stackTrace: s);
      // Optionally set an error message
    }
  }

  // Marks all unread notifications as read
  Future<void> markAllAsRead(String userId) async {
     if (userId.isEmpty) {
      _logger.w("markAllAsRead called with empty userId.");
      return;
    }
    _isLoading = true; // Indicate an operation is in progress
    notifyListeners();

    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      if (unreadNotifications.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var notification in unreadNotifications) {
        DocumentReference notifRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notification.id);
        batch.update(notifRef, {'isRead': true});
      }
      await batch.commit();

      // Update local state
      for (var notification in _notifications) {
        notification.isRead = true;
      }
      _logger.i("Marked all notifications for user $userId as read.");
    } catch (e, s) {
       _logger.e('Error marking all notifications as read for user $userId', error: e, stackTrace: s);
       _errorMessage = "Failed to mark all notifications as read.";
    }
    _isLoading = false;
    notifyListeners();
  }


  // Example: Method to add a notification (typically done server-side via Cloud Functions)
  // This is more for testing or direct app-triggered notifications if absolutely necessary.
  Future<void> addNotification(String userId, NotificationModel notification) async {
    if (userId.isEmpty) {
      _logger.w("addNotification called with empty userId.");
      return;
    }
    try {
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id); // Use provided ID or let Firestore generate one
      
      await docRef.set(notification.toJson());
      _notifications.insert(0, notification); // Add to the beginning of the list
      notifyListeners();
      _logger.i("Added notification ${notification.id} for user $userId.");
    } catch (e, s) {
      _logger.e('Error adding notification for user $userId', error: e, stackTrace: s);
    }
  }

  // Clear all notifications for a user (use with caution)
  Future<void> clearAllNotifications(String userId) async {
    if (userId.isEmpty) {
      _logger.w("clearAllNotifications called with empty userId.");
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      
      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _notifications = [];
      _logger.i("Cleared all notifications for user $userId.");
    } catch (e, s) {
      _logger.e('Error clearing all notifications for user $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to clear notifications.";
    }
    _isLoading = false;
    notifyListeners();
  }
}
