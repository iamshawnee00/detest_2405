// lib/screens/profile/profile_screen.dart
import 'package:flutter/foundation.dart'; // For listEquals
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/user_model.dart';
import '../../models/restaurant_model.dart';
import 'edit_foodie_card_screen.dart';
import '../restaurant/restaurant_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<RestaurantModel>>? _topRestaurantsFuture;
  List<String>? _previousTopRestaurantIds;

  @override
  void initState() {
    super.initState();
    // Initial load can be triggered in didChangeDependencies
    // or here if not dependent on an InheritedWidget that might change before first build.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method is called when dependencies change, including when the widget is first built.
    // It's a good place to load data that depends on InheritedWidgets like Provider.
    _initiateTopRestaurantLoading();
  }
  
  void _initiateTopRestaurantLoading() {
    final authProvider = Provider.of<AuthProvider>(context); // listen: true is appropriate here if UI depends on userModel

    if (authProvider.userModel != null) {
      final currentUserTopIds = authProvider.userModel!.topRestaurantIds;
      // Check if the IDs have actually changed or if the future hasn't been initialized yet for current IDs.
      if (!listEquals(_previousTopRestaurantIds, currentUserTopIds) || (_topRestaurantsFuture == null && currentUserTopIds.isNotEmpty) ) {
        _loadTopRestaurantDetails(currentUserTopIds);
        _previousTopRestaurantIds = List.from(currentUserTopIds); // Update for next comparison
      } else if (currentUserTopIds.isEmpty && (_topRestaurantsFuture != null || _previousTopRestaurantIds?.isNotEmpty == true) ) {
        // If IDs became empty, clear the future and previous IDs
        if (mounted){
             setState(() {
                _topRestaurantsFuture = Future.value([]);
                _previousTopRestaurantIds = [];
            });
        }
      }
    } else if (_topRestaurantsFuture != null || _previousTopRestaurantIds != null) {
      // User logged out or userModel became null
      if (mounted){
        setState(() {
            _topRestaurantsFuture = Future.value([]);
            _previousTopRestaurantIds = null;
        });
      }
    }
  }


  void _loadTopRestaurantDetails(List<String> topIds) {
    // This method should now be called with the specific IDs to fetch
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (topIds.isNotEmpty) {
      if(mounted){
        setState(() { // This setState will rebuild with the new future
          _topRestaurantsFuture = restaurantProvider.getRestaurantsByIds(topIds);
        });
      }
    } else {
      // If there are no top IDs, set the future to an empty list
      if(mounted){
          setState(() {
            _topRestaurantsFuture = Future.value([]);
          });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.firebaseUser == null || authProvider.userModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    final UserModel currentUser = authProvider.userModel!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Foodie Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
             final result = await Navigator.push<bool>( 
                context,
                MaterialPageRoute(
                  builder: (context) => EditFoodieCardScreen(currentUser: currentUser),
                ),
              );
              // After editing, AuthProvider.refreshUserModel() is called in EditFoodieCardScreen.
              // This will trigger AuthProvider to notify listeners.
              // didChangeDependencies in this screen should then pick up the change in userModel.topRestaurantIds
              // and call _initiateTopRestaurantLoading which then calls _loadTopRestaurantDetails if IDs changed.
              // So, no explicit call to _loadTopRestaurantDetails needed here if didChangeDependencies is robust.
              if (result == true && mounted) {
                // Optionally, force a re-evaluation if there's a chance didChangeDependencies might not catch it
                // or if you want immediate feedback without relying solely on provider notification triggering didChange.
                // For now, relying on didChangeDependencies.
                 _initiateTopRestaurantLoading(); // Force reload if needed
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildProfileHeader(context, currentUser),
            const SizedBox(height: 24),
            _buildFoodieCardSection(context, currentUser, _topRestaurantsFuture),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodieCardSection(BuildContext context, UserModel user, Future<List<RestaurantModel>>? topRestaurantsFuture) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Foodie Card',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_2_outlined, color: Theme.of(context).primaryColor),
                  onPressed: () => _showQrCode(context, user.id),
                )
              ],
            ),
            const Divider(height: 20, thickness: 1),
            
            _buildCardDetailRow(context, Icons.favorite_border, 'Preferences', user.preferences.join(', ')),
            _buildCardDetailRow(context, Icons.warning_amber_outlined, 'Allergies', user.allergies.join(', ')),
            _buildCardDetailRow(context, Icons.psychology_outlined, 'Food MBTI', user.foodMBTI ?? 'Not set'),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.restaurant_menu_outlined, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Restaurants', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (user.topRestaurantIds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('Add your top picks!', style: Theme.of(context).textTheme.bodyMedium),
                          )
                        else
                          FutureBuilder<List<RestaurantModel>>(
                            future: topRestaurantsFuture, // Use the future from the state
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && (snapshot.data == null || snapshot.data!.isEmpty) ) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                );
                              }
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red[700])),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                 // This case might be hit if IDs exist but fetch returned empty or is still null (and not waiting)
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text('Could not load details for top restaurants.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                                );
                              }
                              final topRestaurantsDetails = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: topRestaurantsDetails.map((restaurant) {
                                  return _TopRestaurantListItem(restaurant: restaurant, onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                                      ),
                                    );
                                  });
                                }).toList(),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (user.foodieCardBio != null && user.foodieCardBio!.isNotEmpty)
              _buildCardDetailRow(context, Icons.article_outlined, 'Bio', user.foodieCardBio!),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('Add to Wallet'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add to Wallet - Coming Soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : 'Not specified', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrCode(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Scan to Connect!', textAlign: TextAlign.center),
          content: SizedBox(
            width: 250,
            height: 250,
            child: Center(
              child: QrImageView(
                data: 'foodieapp://user?id=$data',
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _TopRestaurantListItem extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const _TopRestaurantListItem({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: restaurant.images.isNotEmpty
                  ? Image.network(
                      restaurant.images.first,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(width:40, height:40, color: Colors.grey[200], child: const Icon(Icons.restaurant, size: 20, color: Colors.grey)),
                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(width: 40, height: 40, color: Colors.grey[200], child: const Icon(Icons.restaurant, size: 20, color: Colors.grey)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if(restaurant.cuisineTypes.isNotEmpty)
                    Text(
                      restaurant.cuisineTypes.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
