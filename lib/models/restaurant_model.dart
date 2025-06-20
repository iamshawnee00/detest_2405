// lib/models/restaurant_model.dart
// No cloud_firestore import needed here as we are using primitives and DateTime

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final String openingHours;
  final String? phoneNumber;
  final String? website;
  final List<String> cuisineTypes;
  final List<String> moodTags;
  final double rating; // Renamed for consistency with your UI
  
  // Fields to match your UI
  final String priceRange;
  final int totalRatings;
  final List<String> allergenInfo;

  // Map to store user interactions. Key: userId, Value: 1 for like, -1 for yike.
  final Map<String, int> userInteractions;

  RestaurantModel({
    required this.id,
    required this.name,
    this.description = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.images = const [],
    this.openingHours = '',
    this.phoneNumber,
    this.website,
    this.cuisineTypes = const [],
    this.moodTags = const [],
    this.rating = 0.0,
    this.priceRange = '\$\$',
    this.totalRatings = 0,
    this.allergenInfo = const [],
    this.userInteractions = const {},
  });

  // Calculated properties to easily get like/yike counts
  int get likesCount => userInteractions.values.where((v) => v == 1).length;
  int get yikesCount => userInteractions.values.where((v) => v == -1).length;

  // Note: The fromJson factory is simplified here. 
  // In your actual code, you should handle Timestamp conversion if you store dates.
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      images: List<String>.from(json['images'] as List<dynamic>? ?? []),
      openingHours: json['openingHours'] as String? ?? 'N/A',
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
      cuisineTypes: List<String>.from(json['cuisineTypes'] as List<dynamic>? ?? []),
      moodTags: List<String>.from(json['moodTags'] as List<dynamic>? ?? []),
      rating: (json['rating'] as num? ?? 0.0).toDouble(), // Use 'rating'
      priceRange: json['priceRange'] as String? ?? '\$\$',
      totalRatings: json['totalRatings'] as int? ?? 0,
      allergenInfo: List<String>.from(json['allergenInfo'] as List<dynamic>? ?? []),
      userInteractions: Map<String, int>.from(json['userInteractions'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      'website': website,
      'cuisineTypes': cuisineTypes,
      'moodTags': moodTags,
      'rating': rating, // Use 'rating'
      'priceRange': priceRange,
      'totalRatings': totalRatings,
      'allergenInfo': allergenInfo,
      'userInteractions': userInteractions,
    };
  }
  
  RestaurantModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    String? openingHours,
    String? phoneNumber,
    String? website,
    List<String>? cuisineTypes,
    List<String>? moodTags,
    double? rating,
    String? priceRange,
    int? totalRatings,
    List<String>? allergenInfo,
    Map<String, int>? userInteractions,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      openingHours: openingHours ?? this.openingHours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      moodTags: moodTags ?? this.moodTags,
      rating: rating ?? this.rating,
      priceRange: priceRange ?? this.priceRange,
      totalRatings: totalRatings ?? this.totalRatings,
      allergenInfo: allergenInfo ?? this.allergenInfo,
      userInteractions: userInteractions ?? this.userInteractions,
    );
  }
}
