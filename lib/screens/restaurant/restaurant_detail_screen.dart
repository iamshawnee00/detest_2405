// screens/restaurant/restaurant_detail_screen.dart
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart'; // Import UserProvider

class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}  

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Future<Map<String, List<UserModel>>>? _friendsOpinionsFuture;

  @override
  Void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _friendsOpinionsFuture = _fetchFriendsOpinions();
  });
  }

  void _fetchFriendsOpinions(){
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    // Get all user IDs from the restaurant's interactions
    final allInteractionUserIds = widget.restaurant.userInteractions.keys.toList();
    // Find which of those are friends of the current user
    final friendIdsWhoInteracted = allInteractionUserIds
        .where((userId) => currentUser.friends.contains(userId))
        .toList();

    if (friendIdsWhoInteracted.isNotEmpty) {
      setState(() {
        _friendsOpinionsFuture = _groupAndFetchUsers(friendIdsWhoInteracted, userProvider);
      });
    }
  }

  // Helper method to fetch users and group them by their interaction
  Future<Map<String, List<UserModel>>> _groupAndFetchUsers(List<String> userIds, UserProvider userProvider) async {
    final List<UserModel?> fetchedUsers = await userProvider.getUsersByIds(userIds);
    final Map<String, List<UserModel>> groupedOpinions = {
      'liked': [],
      'yiked': [],
    };

    for (var user in fetchedUsers) {
      if (user != null) {
        final interaction = widget.restaurant.userInteractions[user.id];
        if (interaction == 1) {
          groupedOpinions['liked']!.add(user);
        } else if (interaction == -1) {
          groupedOpinions['yiked']!.add(user);
        }
      }
    }
    return groupedOpinions;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        final int interactionState = user?.restaurantInteractions[widget.restaurant.id] ?? 0;
        final bool isLiked = interactionState == 1;
        final bool isYiked = interactionState == -1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              title: Text(widget.restaurant.name, style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
              background: widget.restaurant.images.isNotEmpty
                 ? CachedNetworkImage(imageUrl: widget.restaurant.images.first, fit: BoxFit.cover)
      : Container(color: Colors.grey[300], child: const Icon(Icons.restaurant, size: 50, color: Colors.grey)),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        restaurant.priceRange,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Rating and Reviews
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: restaurant.rating,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${restaurant.rating} (${restaurant.totalRatings} reviews)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Cuisine Types
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: restaurant.cuisineTypes.map((cuisine) {
                      return Chip(
                        label: Text(
                          cuisine,
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Description
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 16),

                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Mood Tags
                  if (restaurant.moodTags.isNotEmpty) ...[
                    Text(
                      'Perfect for',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: restaurant.moodTags.map((tag) {
                        return Chip(
                          label: Text(
                            tag.replaceAll('-', ' ').toUpperCase(),
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha((0.1 * 255).toInt()),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Allergen Info
                  if (restaurant.allergenInfo.isNotEmpty) ...[
                    Text(
                      'Allergen Information',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha((0.3 * 255).toInt())),
                      ),
                      child: Text(
                        'Contains: ${restaurant.allergenInfo.join(', ')}',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Like/Yike Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            restaurantProvider.likeRestaurant(restaurant.id, userId);
                          },
                          icon: Icon(Icons.thumb_up),
                          label: Text('Like'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            restaurantProvider.yikeRestaurant(restaurant.id, userId);
                          },
                          icon: Icon(Icons.thumb_down),
                          label: Text('Yike'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Visit Restaurant Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement navigation or booking
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Visit Restaurant'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}