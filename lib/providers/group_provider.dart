// File: lib/providers/group_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Import the logger package
import '../models/group_model.dart'; // Ensure this path is correct
import '../models/restaurant_model.dart'; // For recommendation logic
import '../models/group_rating_model.dart'; // Import the new model


class GroupProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize the logger
  final Logger _logger = Logger(
    printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none),
  );

  List<GroupModel> _userGroups = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupModel> get userGroups => _userGroups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserGroups(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId) // Ensure 'memberIds' index exists
          .get();

      _userGroups = querySnapshot.docs
          .map((doc) => GroupModel.fromJson(doc.data()))
          .toList();
    } catch (e, s) {
      _logger.e('Error loading user groups', error: e, stackTrace: s);
      _errorMessage = "Failed to load user groups.";
      _userGroups = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createGroup(GroupModel group) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      DocumentReference groupRef = _firestore.collection('groups').doc();
      GroupModel groupToSave = group.copyWith(
        id: groupRef.id,
        memberIds: group.memberIds.contains(group.adminId)
            ? List.from(group.memberIds)
            : List.from([...group.memberIds, group.adminId]), // Ensure admin is a member
      );

      
  
      // Ensure createdAt is set if not provided.
      // This assumes GroupModel's createdAt field is nullable or has a default in its constructor/fromJson.
      // The analyzer warning was about `group.createdAt ?? DateTime.now()` if group.createdAt is non-nullable.
      // We will rely on the GroupModel's structure to handle default createdAt.
      final DateTime creationTimestamp = group.createdAt ?? DateTime.now();


      if (group.id.isEmpty) { // Let Firestore generate ID
        groupRef = _firestore.collection('groups').doc();
        groupToSave = GroupModel(
            id: groupRef.id, // Use the generated ID
            name: group.name,
            description: group.description,
            avatar: group.avatar,
            adminId: group.adminId,
            memberIds: group.memberIds.contains(group.adminId) ? List.from(group.memberIds) : List.from([...group.memberIds, group.adminId]), // Ensure admin is a member and list is modifiable
            groupPreferences: group.groupPreferences,
            groupAllergies: group.groupAllergies,
            createdAt: creationTimestamp
            );
      } else { // Use provided ID
        groupRef = _firestore.collection('groups').doc(group.id);
        groupToSave = GroupModel(
            id: group.id,
            name: group.name,
            description: group.description,
            avatar: group.avatar,
            adminId: group.adminId,
            memberIds: group.memberIds.contains(group.adminId) ? List.from(group.memberIds) : List.from([...group.memberIds, group.adminId]),
            groupPreferences: group.groupPreferences,
            groupAllergies: group.groupAllergies,
            createdAt: creationTimestamp
            );
      }
      await groupRef.set(groupToSave.toJson());
      _userGroups.add(groupToSave); // Add the saved group (with potentially new ID)

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error creating group', error: e, stackTrace: s);
      _errorMessage = "Failed to create group.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<RestaurantModel>> generateGroupRecommendations(String groupId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    List<RestaurantModel> recommendations = [];

    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists || groupDoc.data() == null) {
        _errorMessage = "Group not found.";
        _logger.w("generateGroupRecommendations: Group not found for ID $groupId");
        _isLoading = false;
        notifyListeners();
        return [];
      }

      final group = GroupModel.fromJson(groupDoc.data()!);

      if (group.groupPreferences.isEmpty) {
        _errorMessage = "Group has no preferences set for recommendations.";
        _logger.i("generateGroupRecommendations: Group $groupId has no preferences.");
        _isLoading = false;
        notifyListeners();
        return [];
      }

      Query query = _firestore.collection('restaurants');

      // Ensure groupPreferences is not empty before using it in a query
      if (group.groupPreferences.isNotEmpty) {
        query = query.where('cuisineTypes', arrayContainsAny: group.groupPreferences);
      } else {
         // Handle case where there are no preferences, maybe fetch top-rated or popular
         // For now, this means no preference-based filtering if list is empty.
         _logger.i("generateGroupRecommendations: No group preferences to filter by for group $groupId. Consider alternative recommendation logic.");
      }
      
      // Consider adding more filters or complex logic here
      // For example, filtering out based on groupAllergies would require careful data modeling in restaurants collection

      query = query.orderBy('ratingGoogle', descending: true).limit(10); // Assuming 'ratingGoogle' field exists

      final querySnapshot = await query.get();

      recommendations = querySnapshot.docs
          .map((doc) => RestaurantModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      _logger.e('Error generating group recommendations', error: e, stackTrace: s);
      _errorMessage = "Failed to generate recommendations.";
    }
    _isLoading = false;
    notifyListeners();
    return recommendations;
  }

  Future<bool> addMemberToGroup(String groupId, String userIdToAdd) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      DocumentReference groupRef = _firestore.collection('groups').doc(groupId);
      await groupRef.update({
        'memberIds': FieldValue.arrayUnion([userIdToAdd])
      });

      int groupIndex = _userGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        // Ensure the local list is modifiable and then add
        List<String> updatedMemberIds = List.from(_userGroups[groupIndex].memberIds);
        if (!updatedMemberIds.contains(userIdToAdd)) {
          updatedMemberIds.add(userIdToAdd);
          // Manually reconstruct GroupModel if copyWith is not available
          // It's highly recommended to add a copyWith method to your GroupModel
          _userGroups[groupIndex] = GroupModel(
            id: _userGroups[groupIndex].id,
            name: _userGroups[groupIndex].name,
            description: _userGroups[groupIndex].description,
            avatar: _userGroups[groupIndex].avatar,
            adminId: _userGroups[groupIndex].adminId,
            memberIds: updatedMemberIds, // The updated list
            groupPreferences: _userGroups[groupIndex].groupPreferences,
            groupAllergies: _userGroups[groupIndex].groupAllergies,
            createdAt: _userGroups[groupIndex].createdAt,
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error adding member to group', error: e, stackTrace: s);
      _errorMessage = "Failed to add member.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(String groupId, String userIdToRemove, String currentUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      DocumentReference groupRef = _firestore.collection('groups').doc(groupId);
      DocumentSnapshot groupSnapshot = await groupRef.get();

      if (!groupSnapshot.exists || groupSnapshot.data() == null) {
        _errorMessage = "Group not found.";
        _logger.w("removeMemberFromGroup: Group not found for ID $groupId");
        _isLoading = false;
        notifyListeners();
        return false;
      }

      GroupModel group = GroupModel.fromJson(groupSnapshot.data() as Map<String, dynamic>);

      // Prevent admin from being removed if they are the last member or by someone else if specific logic is needed
      // Current logic: Admin cannot remove themselves if they are the admin and other members exist.
      // This might need refinement based on desired behavior (e.g., admin transfer).
      if (group.adminId == userIdToRemove && group.memberIds.length > 1 && userIdToRemove == currentUserId) {
        _errorMessage = "Admin cannot remove themselves if other members exist. Transfer admin rights first.";
         _logger.w("Admin $userIdToRemove attempted to remove themselves from group $groupId with other members present.");
        _isLoading = false;
        notifyListeners();
        return false;
      }
      // Allow admin to remove others, or users to remove themselves (if not admin and last member)
      if (group.adminId != currentUserId && userIdToRemove == currentUserId) { // User removing themselves
         // Allow self-removal
      } else if (group.adminId == currentUserId && userIdToRemove != currentUserId) { // Admin removing another member
         // Allow admin to remove others
      } else if (group.adminId == currentUserId && userIdToRemove == currentUserId && group.memberIds.length == 1) { // Admin removing themselves as last member
         // Allow admin to remove themselves if they are the last one
      }
      else if (group.adminId != currentUserId && userIdToRemove != currentUserId) { // Non-admin trying to remove another non-admin
        _errorMessage = "You do not have permission to remove this member.";
        _logger.w("User $currentUserId (not admin) attempted to remove $userIdToRemove from group $groupId.");
        _isLoading = false;
        notifyListeners();
        return false;
      }


      await groupRef.update({
        'memberIds': FieldValue.arrayRemove([userIdToRemove])
      });

      // Update local state
      int groupIndex = _userGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        List<String> updatedMemberIds = List.from(_userGroups[groupIndex].memberIds);
        updatedMemberIds.remove(userIdToRemove);
        
        // Manually reconstruct GroupModel if copyWith is not available
        // It's highly recommended to add a copyWith method to your GroupModel
        _userGroups[groupIndex] = GroupModel(
            id: _userGroups[groupIndex].id,
            name: _userGroups[groupIndex].name,
            description: _userGroups[groupIndex].description,
            avatar: _userGroups[groupIndex].avatar,
            adminId: _userGroups[groupIndex].adminId,
            memberIds: updatedMemberIds, // The updated list
            groupPreferences: _userGroups[groupIndex].groupPreferences,
            groupAllergies: _userGroups[groupIndex].groupAllergies,
            createdAt: _userGroups[groupIndex].createdAt,
        );
        
        if (_userGroups[groupIndex].memberIds.isEmpty) {
          _userGroups.removeAt(groupIndex);
          // Optionally, delete the group from Firestore if it becomes empty
          // await groupRef.delete();
          // _logger.i("Group $groupId deleted as it became empty after member removal.");
        }
      } else if (userIdToRemove == currentUserId) {
         // If the group wasn't in _userGroups (e.g. loaded by another means) but user removed themselves
         // This case might be redundant if loadUserGroups is the only source.
      }


      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.e('Error removing member from group', error: e, stackTrace: s);
      _errorMessage = "Failed to remove member.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  
  // --- NEW RATING METHODS ---

  // Fetches the leaderboard of rated restaurants for a group
  Future<List<GroupRatingModel>> fetchGroupRatings(String groupId) async {
    if (groupId.isEmpty) return [];
    _logger.i("Fetching ratings for group $groupId");
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('ratings')
          .orderBy('averageRating', descending: true) // This creates the leaderboard
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) => GroupRatingModel.fromJson(doc.data())).toList();
    } catch (e, s) {
      _logger.e('Error fetching group ratings for $groupId', error: e, stackTrace: s);
      return []; // Return empty list on error
    }
  }

  // Submits a rating for a restaurant from a user within a group
  Future<bool> rateRestaurantInGroup({
    required String groupId,
    required String userId,
    required RestaurantModel restaurant, // Pass the whole model to get denormalized data
    required double rating,
  }) async {
    if (groupId.isEmpty || userId.isEmpty || restaurant.id.isEmpty) return false;
    _logger.i("User $userId is rating restaurant ${restaurant.id} in group $groupId with score $rating");

    final ratingRef = _firestore.collection('groups').doc(groupId).collection('ratings').doc(restaurant.id);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(ratingRef);
        
        if (!doc.exists) {
          // If it's the first rating for this restaurant in this group
          final newRating = GroupRatingModel(
            restaurantId: restaurant.id,
            restaurantName: restaurant.name,
            restaurantImageUrl: restaurant.images.isNotEmpty ? restaurant.images.first : null,
            memberRatings: {userId: rating},
            averageRating: rating,
            lastRatedAt: DateTime.now(),
          );
          transaction.set(ratingRef, newRating.toJson());
        } else {
          // If the restaurant has been rated before, update the rating
          final existingData = doc.data()!;
          final Map<String, double> memberRatings = Map<String, double>.from(existingData['memberRatings'] ?? {});
          
          memberRatings[userId] = rating; // Add or update the user's rating

          // Recalculate average
          double total = 0;
          memberRatings.forEach((key, value) {
            total += value;
          });
          double newAverage = total / memberRatings.length;

          transaction.update(ratingRef, {
            'memberRatings': memberRatings,
            'averageRating': newAverage,
            'lastRatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      _logger.i("Successfully submitted rating.");
      return true;
    } catch (e, s) {
      _logger.e("Failed to submit rating for restaurant ${restaurant.id} in group $groupId", error: e, stackTrace: s);
      return false;
    }
  }

}
