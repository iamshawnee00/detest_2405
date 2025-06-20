import 'package:flutter/material.dart';

// Dummy Restaurant class definition (replace with your actual model or import)
class Restaurant {
  final String name;
  final String imageUrl;
  // Add other fields as needed

  Restaurant({required this.name, required this.imageUrl});
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isHorizontal;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.isHorizontal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the card with GestureDetector to handle onTap
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              restaurant.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                restaurant.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}