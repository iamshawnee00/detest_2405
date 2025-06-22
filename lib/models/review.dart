// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String authorId;
  final String restaurantId;
  final String? dishId; // Optional, for dish-specific reviews
  final Timestamp timestamp;
  final Map<String, double> tasteDialData; // e.g., {"Wok Hei": 4.5, "Spiciness": 3.0}

  Review({
    required this.authorId,
    required this.restaurantId,
    this.dishId,
    required this.timestamp,
    required this.tasteDialData,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'restaurantId': restaurantId,
      if (dishId != null) 'dishId': dishId,
      'timestamp': timestamp,
      'tasteDialData': tasteDialData,
    };
  }
}
