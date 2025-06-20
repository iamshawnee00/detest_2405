// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  general, // Default type
  newRestaurant,
  groupActivity,
  friendRequest,
  recommendation,
  promotion,
}

class NotificationModel {
  final String id;
  final String userId; // The user this notification is for
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? relatedItemId; // e.g., restaurantId, groupId, userId (for friend request)
  final String? deepLink; // Optional: for navigating to specific content

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.general,
    required this.createdAt,
    this.isRead = false,
    this.relatedItemId,
    this.deepLink,
  });

  // Factory constructor to create a NotificationModel from a Firestore document
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => NotificationType.general,
          ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
      relatedItemId: json['relatedItemId'] as String?,
      deepLink: json['deepLink'] as String?,
    );
  }

  // Method to convert a NotificationModel instance to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedItemId': relatedItemId,
      'deepLink': deepLink,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedItemId,
    String? deepLink,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      deepLink: deepLink ?? this.deepLink,
    );
  }
}
