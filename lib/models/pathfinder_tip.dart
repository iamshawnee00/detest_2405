// lib/models/pathfinder_tip.dart
import 'package.cloud_firestore/cloud_firestore.dart';

enum TipType { parking, location, general }

class PathfinderTip {
  final String id;
  final String authorId;
  final String restaurantId;
  final TipType tipType;
  final String tipContent;
  final Timestamp timestamp;
  final int upvotes;
  final bool isVerified;

  PathfinderTip({
    required this.id,
    required this.authorId,
    required this.restaurantId,
    required this.tipType,
    required this.tipContent,
    required this.timestamp,
    this.upvotes = 0,
    this.isVerified = false,
  });

  factory PathfinderTip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return PathfinderTip(
      id: snapshot.id,
      authorId: data['authorId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      tipType: TipType.values.byName(data['tipType'] ?? 'general'),
      tipContent: data['tipContent'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      upvotes: data['upvotes'] ?? 0,
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'restaurantId': restaurantId,
      'tipType': tipType.name,
      'tipContent': tipContent,
      'timestamp': timestamp,
      'upvotes': upvotes,
      'isVerified': isVerified,
    };
  }
}
