// lib/models/restaurant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final List<String> cuisineTags;
  final Map<String, dynamic> overallTasteSignature; // Aggregated data

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.cuisineTags,
    required this.overallTasteSignature,
  });
}

// fromFirestore and toFirestore methods would be added here