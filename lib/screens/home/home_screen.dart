// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/notification_provider.dart'; // Import NotificationProvider
import '../../widgets/mood_selector.dart';
// Make sure this is imported
import '../restaurant/restaurant_detail_screen.dart' as restaurant_detail;
import '../notifications/notifications_screen.dart'; // Import NotificationsScreen

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  HomeTabScreenState createState() => HomeTabScreenState();
}

class HomeTabScreenState extends State<HomeTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false); // Get NotificationProvider

      restaurantProvider.loadRestaurants();
      restaurantProvider.loadNearbyRestaurants(5.0);

      // Fetch notifications for the current user
      String? currentUserId = authProvider.userModel?.id;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        notificationProvider.fetchNotifications(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final restaurantProvider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${authProvider.userModel?.name ?? 'Foodie'}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'What would you like to eat today?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // START of the code snippet you provided
          IconButton(
            icon: Consumer<NotificationProvider>( // To show unread count badge
              builder: (context, notificationProvider, child) {
                // Replace with a proper Badge widget if you have one
                if (notificationProvider.unreadCount > 0) {
                  return Stack(
                    alignment: Alignment.center, // Center the icon and badge
                    children: [
                      const Icon(Icons.notifications),
                      Positioned(
                        top: 8, // Adjust position for better visual
                        right: 8, // Adjust position for better visual
                        child: Container(
                          padding: const EdgeInsets.all(2), // Adjusted padding
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8), // More rounded
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16), // Adjusted constraints
                          child: Text(
                            '${notificationProvider.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), // Adjusted style
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    ],
                  );
                }
                return const Icon(Icons.notifications_none_outlined);
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
              // Optionally, fetch notifications when opening the screen
              // This can be useful if the user hasn't opened the app for a while
              // Or if you want to ensure the latest notifications are shown upon entering the screen.
              // However, notifications are already fetched in initState.
              // String? currentUserId = Provider.of<AuthProvider>(context, listen: false).userModel?.id;
              // if (currentUserId != null && currentUserId.isNotEmpty) {
              //   Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(currentUserId);
              // }
            },
          ),
          // END of the code snippet you provided
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Selector
            MoodSelector(
              onMoodSelected: (mood) {
                restaurantProvider.loadMoodBasedRestaurants(mood);
              },
            ),
            const SizedBox(height: 24),

            // Nearby Restaurants
            Text(
              'Nearby Favorites',
              style: Theme.of(context).textTheme.headlineSmall, // Adjusted style
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220, // Slightly increased height
              child: restaurantProvider.isLoading && restaurantProvider.nearbyRestaurants.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : restaurantProvider.nearbyRestaurants.isEmpty
                      ? const Center(child: Text("No nearby restaurants found yet!"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: restaurantProvider.nearbyRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurantProvider.nearbyRestaurants[index];
                            return Container(
                              width: 170, // Slightly increased width
                              margin: const EdgeInsets.only(right: 12),
                              // Assuming you have a RestaurantCard widget defined elsewhere
                              // child: RestaurantCard(
                              //   restaurant: restaurant,
                              //   onTap: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder: (context) => RestaurantDetailScreen(
                              //           restaurant: restaurant,
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // ),
                              // Placeholder if RestaurantCard is not available in this exact context
                              child: Card(
                                child: Center(child: Text(restaurant.name)),
                              )
                            );
                          },
                        ),
            ),
            const SizedBox(height: 24),

            // Mood-based Recommendations
            if (restaurantProvider.moodBasedRestaurants.isNotEmpty) ...[
              Text(
                'Perfect for Your Mood',
                style: Theme.of(context).textTheme.headlineSmall, // Adjusted style
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220, // Slightly increased height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: restaurantProvider.moodBasedRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurantProvider.moodBasedRestaurants[index];
                    return Container(
                      width: 170, // Slightly increased width
                      margin: const EdgeInsets.only(right: 12),
                      // child: RestaurantCard(
                      //   restaurant: restaurant,
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => RestaurantDetailScreen(
                      //           restaurant: restaurant,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                       // Placeholder if RestaurantCard is not available in this exact context
                      child: Card(
                        child: Center(child: Text(restaurant.name)),
                      )
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Featured Restaurants
            Text(
              'Featured Restaurants',
              style: Theme.of(context).textTheme.headlineSmall, // Adjusted style
            ),
            const SizedBox(height: 12),
            restaurantProvider.isLoading && restaurantProvider.restaurants.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : restaurantProvider.restaurants.isEmpty
                    ? const Center(child: Text("No featured restaurants available."))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: restaurantProvider.restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurantProvider.restaurants[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            // child: RestaurantCard(
                            //   restaurant: restaurant,
                            //   onTap: () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => RestaurantDetailScreen(
                            //           restaurant: restaurant,
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // ),
                            // Placeholder if RestaurantCard is not available in this exact context
                            child: Card(
                              child: ListTile(
                                title: Text(restaurant.name),
                                onTap: () {
                                   Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => restaurant_detail.RestaurantDetailScreen(
                                          restaurant: restaurant,
                                        ),
                                      ),
                                    );
                                },
                              )
                            )
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}