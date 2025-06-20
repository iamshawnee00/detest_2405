// screens/discover/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart'; // Assuming this path is correct
import '../../models/restaurant_model.dart'; // Assuming this path is correct

// Placeholder for the Restaurant Detail Screen
class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  restaurant.images.first,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text(
              restaurant.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(restaurant.rating.toString(), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cuisine: ${restaurant.cuisineTypes.join(', ')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Address: ${restaurant.address}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
             Text(
              'Hours: ${restaurant.openingHours}', // Assuming openingHours is a displayable string
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              restaurant.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  DiscoverScreenState createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All', 'Italian', 'Chinese', 'Mexican', 'Japanese', 'Indian', 'American'
    // Consider fetching these dynamically or from a config
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial restaurants and also apply the default "All" filter.
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      restaurantProvider.loadRestaurants().then((_) {
        // Ensure filter is applied after initial load if _restaurants list is populated
        if (restaurantProvider.restaurants.isNotEmpty) {
            restaurantProvider.filterByCategory(null); // 'All' means null category
        }
      });
    });
  }

  void _onSearchChanged(String query) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (query.isEmpty) {
      // If search is cleared, reload all and apply current filter
      restaurantProvider.loadRestaurants().then((_) {
         restaurantProvider.filterByCategory(_selectedFilter == 'All' ? null : _selectedFilter);
      });
    } else {
      restaurantProvider.searchRestaurants(query);
      // After search, the filter might need to be reapplied or handled differently
      // For now, search results will override filter.
      // Or, you might want search to work ON TOP of existing filters.
      // If so, `searchRestaurants` would need to take current `_filteredRestaurants` as input
      // or `filterByCategory` should be called on `provider.restaurants` from search.
      // For simplicity, let's assume search shows its own results.
      // If you want to maintain filter, you might need to adjust RestaurantProvider's search logic
      // or re-apply filter on the search results client-side if searchRestaurants populates _restaurants.
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Food'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120), // Increased height for padding
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search restaurants, cuisines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SizedBox(
                  height: 40, // Explicit height for the chips row
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              // Clear search when a filter is applied
                              _searchController.clear();
                              // Load all restaurants first, then filter.
                              // This ensures filter works on the complete dataset.
                              restaurantProvider.loadRestaurants().then((_) {
                                restaurantProvider.filterByCategory(
                                  filter == 'All' ? null : filter
                                );
                              });
                            });
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor.withAlpha((0.3 * 255).toInt()),
                        checkmarkColor: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                        labelStyle: TextStyle(
                          color: _selectedFilter == filter
                              ? Theme.of(context).primaryColorDark // Or a contrasting color
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.filteredRestaurants.isEmpty && _searchController.text.isEmpty) {
            // Show loading only if filteredRestaurants is empty and not during a search loading
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.filteredRestaurants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // When retrying, clear search and apply current filter
                        _searchController.clear();
                        provider.loadRestaurants().then((_) {
                           provider.filterByCategory(_selectedFilter == 'All' ? null : _selectedFilter);
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final restaurantsToDisplay = (_searchController.text.isNotEmpty && !provider.isLoading)
              ? provider.restaurants // If searching, display results from provider.restaurants (assuming search populates this)
              : provider.filteredRestaurants; // Otherwise, display filtered restaurants

          if (restaurantsToDisplay.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No restaurants found',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'Try a different search term.'
                          : 'Try adjusting your filters or check back later!',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurantsToDisplay.length,
            itemBuilder: (context, index) {
              final restaurant = restaurantsToDisplay[index];
              return RestaurantCard(
                restaurant: restaurant,
                onTap: () {
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap; // Changed from Null Function()

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap, // onTap is now a VoidCallback
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap, // Use the passed onTap callback
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            Container(
              height: 180, // Adjusted height
              width: double.infinity,
              color: Colors.grey[200], // Placeholder color
              child: restaurant.images.isNotEmpty
                  ? Image.network(
                      restaurant.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.restaurant, size: 64, color: Colors.grey[600]),
                        );
                      },
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Center(child: Icon(Icons.restaurant, size: 64, color: Colors.grey[600])),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18), // Adjusted size
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toStringAsFixed(1), // Format rating
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Cuisine Type
                  if (restaurant.cuisineTypes.isNotEmpty)
                    Text(
                      restaurant.cuisineTypes.join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // Address (brief)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address.split(',').first, // Show only first part of address for brevity
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  // Description (optional, if too long for card)
                  // const SizedBox(height: 8),
                  // Text(
                  //   restaurant.description,
                  //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  //         color: Colors.grey[600],
                  //       ),
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
