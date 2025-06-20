// lib/models/group_rating_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRatingModel {
  final String restaurantId;
  final String restaurantName; // Denormalized for easy display
  final String? restaurantImageUrl; // Denormalized for easy display
  final Map<String, double> memberRatings; // Map of userId -> rating (e.g., 1.0 to 5.0)
  final double averageRating;
  final DateTime lastRatedAt;

  GroupRatingModel({
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.memberRatings,
    required this.averageRating,
    required this.lastRatedAt,
  });

  factory GroupRatingModel.fromJson(Map<String, dynamic> json) {
    // Convert the dynamic map from Firestore to Map<String, double>
    final ratingsMap = Map<String, dynamic>.from(json['memberRatings'] ?? {});
    final memberRatings = ratingsMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
    
    return GroupRatingModel(
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? 'Unknown Restaurant',
      restaurantImageUrl: json['restaurantImageUrl'] as String?,
      memberRatings: memberRatings,
      averageRating: (json['averageRating'] as num? ?? 0.0).toDouble(),
      lastRatedAt: (json['lastRatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImageUrl': restaurantImageUrl,
      'memberRatings': memberRatings,
      'averageRating': averageRating,
      'lastRatedAt': Timestamp.fromDate(lastRatedAt),
    };
  }
}
