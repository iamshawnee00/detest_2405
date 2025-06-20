// File: lib/providers/restaurant_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart'; // To update user interactions


class RestaurantProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none),
  );

  List<RestaurantModel> _restaurants = []; // General list, potentially for discover or search
  final Map<String, RestaurantModel> _fetchedRestaurantsById = {}; // Cache for specific fetches, now final
  List<RestaurantModel> _nearbyRestaurants = [];
  List<RestaurantModel> _moodBasedRestaurants = [];
  List<RestaurantModel> _filteredRestaurants = []; // Usually derived from _restaurants
  
  // --- NEW STATE FOR NOVELTY SUGGESTIONS ---
  List<RestaurantModel> _noveltySuggestions = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Expose all restaurants if needed, but be mindful of its source (general load vs specific)
  List<RestaurantModel> get restaurants => _restaurants; 
  List<RestaurantModel> get noveltySuggestions => _noveltySuggestions;

  List<RestaurantModel> get nearbyRestaurants => _nearbyRestaurants;
  List<RestaurantModel> get moodBasedRestaurants => _moodBasedRestaurants;
  List<RestaurantModel> get filteredRestaurants => _filteredRestaurants.isNotEmpty ? _filteredRestaurants : _restaurants; // Fallback to all if filter is not active
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;



  // --- NEW METHOD FOR NOVELTY SUGGESTIONS ---
  /// Fetches highly-rated restaurants that the user has not interacted with.
  Future<void> fetchNoveltySuggestions({
    required UserModel user,
    int limit = 20,
  }) async {
    _logger.i("Fetching novelty suggestions for user ${user.id}");
    // We can use the main loading flag or a specific one
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .orderBy('rating', descending: true) // Start with top-rated
          .limit(100) // Fetch a larger pool to filter from
          .get();

      final allTopRated = querySnapshot.docs
          .map((doc) => RestaurantModel.fromJson(doc.data()))
          .toList();

      // Filter out any restaurant the user has already liked or yiked
      final userInteractedIds = user.restaurantInteractions.keys.toSet();
      _noveltySuggestions = allTopRated
          .where((restaurant) => !userInteractedIds.contains(restaurant.id))
          .toList();
      
      // Shuffle to add variety and take the limit
      _noveltySuggestions.shuffle();
      if (_noveltySuggestions.length > limit) {
        _noveltySuggestions = _noveltySuggestions.sublist(0, limit);
      }
      
      _logger.i("Found ${_noveltySuggestions.length} novelty suggestions.");

    } catch (e, s) {
      _logger.e('Error fetching novelty suggestions', error: e, stackTrace: s);
      _errorMessage = "Failed to load new suggestions.";
    }

    _isLoading = false;
    notifyListeners();
  }


  // --- EXISTING METHODS ---
  // Helper to get a specific restaurant if already fetched
  RestaurantModel? getRestaurantFromCache(String id) => _fetchedRestaurantsById[id];

  Future<void> loadRestaurants({int limit = 50}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .orderBy('ratingGoogle', descending: true)
          .limit(limit)
          .get();

      _restaurants = querySnapshot.docs
          .map((doc) {
            try {
              final restaurant = RestaurantModel.fromJson(doc.data());
              _fetchedRestaurantsById[restaurant.id] = restaurant; // Add to cache
              return restaurant;
            } catch(e, s) {
              _logger.e("Error parsing restaurant ${doc.id}", error: e, stackTrace: s);
              return null;
            }
          })
          .whereType<RestaurantModel>()
          .toList();
      _logger.i("Loaded ${_restaurants.length} general restaurants.");
    } catch (e, s) {
      _logger.e('Error loading restaurants', error: e, stackTrace: s);
      _errorMessage = "Failed to load restaurants.";
      _restaurants = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // New method to fetch specific restaurants by their IDs
  Future<List<RestaurantModel>> getRestaurantsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    _isLoading = true;
    _errorMessage = null;
    // notifyListeners(); // Optional: notify if UI should show global loading for this specific fetch

    List<RestaurantModel> result = [];
    List<String> idsToFetch = [];

    // Check cache first
    for (String id in ids) {
      if (_fetchedRestaurantsById.containsKey(id)) {
        result.add(_fetchedRestaurantsById[id]!);
      } else {
        idsToFetch.add(id);
      }
    }

    if (idsToFetch.isNotEmpty) {
      _logger.i("Fetching ${idsToFetch.length} restaurants by IDs from Firestore.");
      try {
        // Firestore 'in' query can fetch up to 30 documents at a time.
        // For more than 30, you'd need to batch the requests.
        // List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = []; // Removed unused variable
        for(int i = 0; i < idsToFetch.length; i += 30) {
            List<String> sublist = idsToFetch.sublist(i, i + 30 > idsToFetch.length ? idsToFetch.length : i + 30);
            if (sublist.isNotEmpty) {
                 final querySnapshot = await _firestore
                    .collection('restaurants')
                    .where(FieldPath.documentId, whereIn: sublist)
                    .get();
                
                for (var doc in querySnapshot.docs) {
                    if (doc.exists) {
                        try {
                            final restaurant = RestaurantModel.fromJson(doc.data());
                            result.add(restaurant);
                            _fetchedRestaurantsById[restaurant.id] = restaurant; // Add to cache
                        } catch (e,s) {
                            _logger.e("Error parsing restaurant ${doc.id} during batch fetch", error: e, stackTrace: s);
                        }
                    }
                }
            }
        }
        _logger.i("Fetched ${result.length - (ids.length - idsToFetch.length)} new restaurants by ID. Total resolved: ${result.length}");

      } catch (e, s) {
        _logger.e('Error fetching restaurants by IDs', error: e, stackTrace: s);
        _errorMessage = "Failed to load some restaurant details.";
        // Don't clear existing results if some were fetched from cache or partially from Firestore
      }
    } else {
        _logger.i("All requested restaurant IDs found in cache.");
    }

    _isLoading = false;
    notifyListeners(); // Notify after all operations complete
    return result; // Return the combined list from cache and fetch
  }


  Future<void> loadNearbyRestaurants(double radiusInKm) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        _logger.w(_errorMessage);
        _isLoading = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          _logger.w(_errorMessage);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied, we cannot request permissions.';
        _logger.w(_errorMessage);
        _isLoading = false;
        notifyListeners();
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // For nearby, it's better to use a geo-query if possible.
      // If relying on client-side filtering of a general list:
      List<RestaurantModel> sourceList = List.from(_restaurants); // Use a copy of the general list
      if (sourceList.isEmpty) {
        _logger.i("No general restaurants loaded, fetching for nearby search...");
        // Temporarily load a broader set for nearby calculation if main list is empty
        // This is not ideal for efficiency but works for smaller datasets
        final tempQuerySnapshot = await _firestore.collection('restaurants').limit(200).get(); // Fetch more for client-side filter
        sourceList = tempQuerySnapshot.docs.map((doc) {
             try {
                final restaurant = RestaurantModel.fromJson(doc.data());
                _fetchedRestaurantsById[restaurant.id] = restaurant; // Cache them
                return restaurant;
            } catch(e,s) {
                _logger.e("Error parsing restaurant ${doc.id} for nearby temp list", error:e, stackTrace:s);
                return null;
            }
        }).whereType<RestaurantModel>().toList();

         if (_errorMessage != null) {
            _logger.e("Failed to load base restaurants for nearby search: $_errorMessage");
            _isLoading = false;
            notifyListeners();
            return;
         }
      }
      
      _nearbyRestaurants = sourceList.where((restaurant) {
        if (restaurant.latitude == 0.0 && restaurant.longitude == 0.0) {
            _logger.w("Restaurant ${restaurant.id} missing valid coordinates, skipping for nearby calculation.");
            return false;
        }
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          restaurant.latitude,
          restaurant.longitude,
        );
        return distance <= radiusInKm * 1000;
      }).toList();
      _logger.i("Found ${_nearbyRestaurants.length} nearby restaurants within $radiusInKm km.");
      
    } catch (e, s) {
      _logger.e('Error loading nearby restaurants', error: e, stackTrace: s);
      _errorMessage = "Failed to load nearby restaurants.";
      _nearbyRestaurants = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchRestaurants(String queryText) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (queryText.isEmpty) {
        _restaurants = []; 
        _filteredRestaurants = []; // Clear filtered as well
        _isLoading = false;
        notifyListeners();
        return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .where('nameSearchable', arrayContains: queryText.toLowerCase()) // Assumes 'nameSearchable' is an array of keywords
          // .where('name', isGreaterThanOrEqualTo: queryText) // Simpler prefix search
          // .where('name', isLessThanOrEqualTo: '$queryText\uf8ff')
          // .orderBy('name') 
          .limit(20)
          .get();

      // When searching, update _restaurants and clear _filteredRestaurants initially
      _restaurants = querySnapshot.docs
          .map((doc) {
            try {
                 final restaurant = RestaurantModel.fromJson(doc.data());
                _fetchedRestaurantsById[restaurant.id] = restaurant; // Cache them
                return restaurant;
            } catch(e,s) {
                _logger.e("Error parsing restaurant ${doc.id} from search", error:e, stackTrace:s);
                return null;
            }
        }).whereType<RestaurantModel>().toList();
      _filteredRestaurants = List.from(_restaurants); // Initialize filter with search results
      _logger.i("Search for '$queryText' found ${_restaurants.length} restaurants.");
    } catch (e, s) {
      _logger.e('Error searching restaurants', error: e, stackTrace: s);
      _errorMessage = "Failed to search restaurants.";
      _restaurants = [];
      _filteredRestaurants = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoodBasedRestaurants(String mood, {int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .where('moodTags', arrayContains: mood)
          .orderBy('ratingGoogle', descending: true)
          .limit(limit)
          .get();

      _moodBasedRestaurants = querySnapshot.docs
          .map((doc) {
            try {
                final restaurant = RestaurantModel.fromJson(doc.data());
                _fetchedRestaurantsById[restaurant.id] = restaurant; // Cache them
                return restaurant;
            } catch(e,s) {
                 _logger.e("Error parsing restaurant ${doc.id} from mood search", error:e, stackTrace:s);
                return null;
            }
        }).whereType<RestaurantModel>().toList();
      _logger.i("Found ${_moodBasedRestaurants.length} restaurants for mood '$mood'.");
          
    } catch (e, s) {
      _logger.e('Error loading mood-based restaurants', error: e, stackTrace: s);
      _errorMessage = "Failed to load mood-based restaurants.";
      _moodBasedRestaurants = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> likeRestaurant(String restaurantId, String userId) async {
    _errorMessage = null;
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference restaurantRef = _firestore.collection('restaurants').doc(restaurantId);
      batch.update(restaurantRef, {'likesYikesMap.$userId': 1}); 
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'restaurantInteractions.$restaurantId': 1});
      await batch.commit();
      _logger.i("User $userId liked restaurant $restaurantId.");
      _updateLocalRestaurantInteraction(restaurantId, userId, 1);
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error liking restaurant', error: e, stackTrace: s);
      _errorMessage = "Failed to like restaurant.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> yikeRestaurant(String restaurantId, String userId) async {
    _errorMessage = null;
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference restaurantRef = _firestore.collection('restaurants').doc(restaurantId);
      batch.update(restaurantRef, {'likesYikesMap.$userId': -1});
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'restaurantInteractions.$restaurantId': -1});
      await batch.commit();
      _logger.i("User $userId yiked restaurant $restaurantId.");
      _updateLocalRestaurantInteraction(restaurantId, userId, -1);
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error yiking restaurant', error: e, stackTrace: s);
      _errorMessage = "Failed to yike restaurant.";
      notifyListeners();
      return false;
    }
  }

  void _updateLocalRestaurantInteraction(String restaurantId, String userId, int interactionStatus) {
    void updateList(List<RestaurantModel> list) {
        var index = list.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
            // Assuming RestaurantModel has a method or you update its interaction map/count here
            // For example, if it has a Map<String, int> userInteractions:
            // final updatedInteractions = Map<String, int>.from(list[index].userInteractions ?? {});
            // updatedInteractions[userId] = interactionStatus;
            // list[index] = list[index].copyWith(userInteractions: updatedInteractions); 
            _logger.d("Local restaurant $restaurantId updated in a list for user $userId interaction. Actual model update logic is pending.");
        }
    }
    updateList(_restaurants);
    updateList(_nearbyRestaurants);
    updateList(_moodBasedRestaurants);
    updateList(_filteredRestaurants);
    
    // Also update the specific cache
    if (_fetchedRestaurantsById.containsKey(restaurantId)) {
        // Similar update logic for _fetchedRestaurantsById[restaurantId]
    }
  }

  void filterByCategory(String? category) {
    if (category == null || category.toLowerCase() == 'all') {
      _filteredRestaurants = List.from(_restaurants); // Use the general/searched list as base
    } else {
      _filteredRestaurants = _restaurants 
          .where((restaurant) => 
              restaurant.cuisineTypes.any((type) => type.toLowerCase() == category.toLowerCase())
          )
          .toList();
    }
    _logger.i("Filtered restaurants by category: $category. Found ${_filteredRestaurants.length}");
    notifyListeners();
  }
}
