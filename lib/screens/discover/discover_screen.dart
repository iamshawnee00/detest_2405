// lib/screens/discover/discover_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/screens/restaurant/restaurant_detail_screen.dart'; // << IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider remains the same...
final restaurantStreamProvider = StreamProvider<List<Restaurant>>((ref) {
  // ...
});

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsyncValue = ref.watch(restaurantStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Restaurants')),
      body: restaurantsAsyncValue.when(
        data: (restaurants) {
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return ListTile(
                title: Text(restaurant.name),
                subtitle: Text(restaurant.address),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // << UPDATE THIS to navigate
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
