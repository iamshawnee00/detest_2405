// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<String> preferences;
  final List<String> allergies;
  final String? foodMBTI;
  final List<String> topRestaurantIds;
  final List<String> friends;
  final String? foodieCardBio;
  
  // NEW: Map to store this user's interactions. Key: restaurantId, Value: 1 for like, -1 for yike.
  final Map<String, int> restaurantInteractions;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    this.preferences = const [],
    this.allergies = const [],
    this.foodMBTI,
    this.topRestaurantIds = const [],
    this.friends = const [],
    this.foodieCardBio,
    this.restaurantInteractions = const {}, // Initialize as empty map
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      preferences: List<String>.from(json['preferences'] as List<dynamic>? ?? []),
      allergies: List<String>.from(json['allergies'] as List<dynamic>? ?? []),
      foodMBTI: json['foodMBTI'] as String?,
      topRestaurantIds: List<String>.from(json['topRestaurantIds'] as List<dynamic>? ?? []),
      friends: List<String>.from(json['friends'] as List<dynamic>? ?? []),
      foodieCardBio: json['foodieCardBio'] as String?,
      restaurantInteractions: Map<String, int>.from(json['restaurantInteractions'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'preferences': preferences,
      'allergies': allergies,
      'foodMBTI': foodMBTI,
      'topRestaurantIds': topRestaurantIds,
      'friends': friends,
      'foodieCardBio': foodieCardBio,
      'restaurantInteractions': restaurantInteractions,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    List<String>? preferences,
    List<String>? allergies,
    String? foodMBTI,
    List<String>? topRestaurantIds,
    List<String>? friends,
    String? foodieCardBio,
    Map<String, int>? restaurantInteractions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      allergies: allergies ?? this.allergies,
      foodMBTI: foodMBTI ?? this.foodMBTI,
      topRestaurantIds: topRestaurantIds ?? this.topRestaurantIds,
      friends: friends ?? this.friends,
      foodieCardBio: foodieCardBio ?? this.foodieCardBio,
      restaurantInteractions: restaurantInteractions ?? this.restaurantInteractions,
    );
  }
}
