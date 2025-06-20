// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart'; // Ensure this path is correct

class UserProvider extends ChangeNotifier {
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

  String? _errorMessage;
  bool _isUpdating = false; // Specific loading state for updates

  String? get errorMessage => _errorMessage;
  bool get isUpdating => _isUpdating;

  // Existing methods from your file...

  Future<bool> updateUserFoodieCard({
    required String userId,
    List<String>? preferences,
    List<String>? allergies,
    String? foodMBTI,
    List<String>? topRestaurantIds, // Assuming these are IDs
    String? foodieCardBio,
    // You can add more specific fields from UserModel if needed for the card
    String? name, // User's name might also be part of the card
    String? avatarUrl, // User's avatar might also be part of the card
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    Map<String, dynamic> dataToUpdate = {};

    // Fields directly from UserModel that are part of Foodie Card
    if (name != null) dataToUpdate['name'] = name;
    if (avatarUrl != null) dataToUpdate['avatarUrl'] = avatarUrl; // Corrected field name
    if (preferences != null) dataToUpdate['preferences'] = preferences;
    if (allergies != null) dataToUpdate['allergies'] = allergies;
    if (foodMBTI != null) dataToUpdate['foodMBTI'] = foodMBTI;
    if (topRestaurantIds != null) dataToUpdate['topRestaurantIds'] = topRestaurantIds;
    if (foodieCardBio != null) dataToUpdate['foodieCardBio'] = foodieCardBio;


    if (dataToUpdate.isEmpty) {
      _logger.i("updateUserFoodieCard: No data provided to update for user $userId.");
      _isUpdating = false;
      notifyListeners();
      return true; // Nothing to update
    }

    try {
      _logger.i("Attempting to update Foodie Card for user $userId with data: $dataToUpdate");
      await _firestore.collection('users').doc(userId).update(dataToUpdate);
      _logger.i("Successfully updated Foodie Card for user $userId.");
      
      // IMPORTANT: After updating, you need to ensure that the AuthProvider's UserModel
      // is also updated to reflect these changes in the UI immediately.
      // One way is to call a refresh method on AuthProvider:
      // Provider.of<AuthProvider>(context, listen: false).refreshUserModel();
      // This assumes AuthProvider has such a method.

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error updating Foodie Card for $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to update Foodie Card.";
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // ... (keep your existing methods like addFavoriteRestaurant, removeFavoriteRestaurant, addFriend, removeFriend, getUserById)
  // Ensure they also use the _logger instead of print() if they haven't been updated yet.

  // Example: Updating addFavoriteRestaurant with logger
  Future<bool> addFavoriteRestaurant(String userId, String restaurantId) async {
    _errorMessage = null;
    // _isUpdating = true; // If you want a loading state for this
    // notifyListeners();
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteRestaurants': FieldValue.arrayUnion([restaurantId])
      });
      _logger.i("User $userId added restaurant $restaurantId to favorites.");
      // _isUpdating = false;
      // notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error adding favorite restaurant for user $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to add favorite.";
      // _isUpdating = false;
      notifyListeners(); // Notify to show error
      return false;
    }
  }

   Future<bool> removeFavoriteRestaurant(String userId, String restaurantId) async {
    _errorMessage = null;
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteRestaurants': FieldValue.arrayRemove([restaurantId])
      });
      _logger.i("User $userId removed restaurant $restaurantId from favorites.");
      return true;
    } catch (e, s) {
      _logger.e('Error removing favorite restaurant for user $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to remove favorite.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> addFriend(String currentUserId, String friendUserId) async {
    _errorMessage = null;
    if (currentUserId == friendUserId) {
      _errorMessage = "You cannot add yourself as a friend.";
      _logger.w("User $currentUserId attempted to add self as friend.");
      notifyListeners();
      return false;
    }
    try {
      WriteBatch batch = _firestore.batch();
      
      DocumentReference currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {'friends': FieldValue.arrayUnion([friendUserId])});
      
      DocumentReference friendUserRef = _firestore.collection('users').doc(friendUserId);
      batch.update(friendUserRef, {'friends': FieldValue.arrayUnion([currentUserId])});

      await batch.commit();
      _logger.i("User $currentUserId added user $friendUserId as a friend (mutual).");
      return true;
    } catch (e, s) {
      _logger.e('Error adding friend: $currentUserId to $friendUserId', error: e, stackTrace: s);
      _errorMessage = "Failed to add friend.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFriend(String currentUserId, String friendUserId) async {
    _errorMessage = null;
    try {
      WriteBatch batch = _firestore.batch();
      
      DocumentReference currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {'friends': FieldValue.arrayRemove([friendUserId])});
      
      DocumentReference friendUserRef = _firestore.collection('users').doc(friendUserId);
      batch.update(friendUserRef, {'friends': FieldValue.arrayRemove([currentUserId])});

      await batch.commit();
      _logger.i("User $currentUserId removed user $friendUserId as a friend (mutual).");
      return true;
    } catch (e, s) {
      _logger.e('Error removing friend: $currentUserId from $friendUserId', error: e, stackTrace: s);
      _errorMessage = "Failed to remove friend.";
      notifyListeners();
      return false;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    _errorMessage = null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _logger.i("Fetched user details for $userId.");
        return UserModel.fromJson(doc.data()!);
      } else {
        _logger.w("User document not found for ID: $userId");
        return null;
      }
    } catch (e, s) {
      _logger.e('Error fetching user by ID: $userId', error: e, stackTrace: s);
      _errorMessage = "Failed to fetch user details.";
      notifyListeners();
      return null;
    }
  }
}
