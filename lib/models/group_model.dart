// lib/models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar; // URL to group image
  final String adminId;
  final List<String> memberIds;
  final List<String> groupPreferences;
  final List<String> groupAllergies;
  final List<String> topRestaurantIds; // List of restaurant IDs
  final DateTime? createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.adminId,
    this.memberIds = const [],
    this.groupPreferences = const [],
    this.groupAllergies = const [],
    this.topRestaurantIds = const [], // Initialize as empty list
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      avatar: json['avatar'] as String?,
      adminId: json['adminId'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] as List<dynamic>? ?? []),
      groupPreferences: List<String>.from(json['groupPreferences'] as List<dynamic>? ?? []),
      groupAllergies: List<String>.from(json['groupAllergies'] as List<dynamic>? ?? []),
      topRestaurantIds: List<String>.from(json['topRestaurantIds'] as List<dynamic>? ?? []), // Deserialize new field
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'adminId': adminId,
      'memberIds': memberIds,
      'groupPreferences': groupPreferences,
      'groupAllergies': groupAllergies,
      'topRestaurantIds': topRestaurantIds, // Serialize new field
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
  
  // It's highly recommended to have a copyWith method for easier state management
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    String? adminId,
    List<String>? memberIds,
    List<String>? groupPreferences,
    List<String>? groupAllergies,
    List<String>? topRestaurantIds,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      groupPreferences: groupPreferences ?? this.groupPreferences,
      groupAllergies: groupAllergies ?? this.groupAllergies,
      topRestaurantIds: topRestaurantIds ?? this.topRestaurantIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
