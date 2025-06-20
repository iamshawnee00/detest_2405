// lib/screens/profile/select_top_restaurants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';

class SelectTopRestaurantsScreen extends StatefulWidget {
  final List<String> currentSelectedIds; // Pass current selections
  final int maxSelectionCount;

  const SelectTopRestaurantsScreen({
    super.key,
    required this.currentSelectedIds,
    this.maxSelectionCount = 5,
  });

  @override
  State<SelectTopRestaurantsScreen> createState() => _SelectTopRestaurantsScreenState();
}

class _SelectTopRestaurantsScreenState extends State<SelectTopRestaurantsScreen> {
  late List<String> _selectedRestaurantIds;
  List<RestaurantModel> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRestaurantIds = List.from(widget.currentSelectedIds);
    // Load initial restaurants if search is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchController.text.isEmpty) {
        _performSearch('');
      }
    });
  }

  // Removed unused _fetchAllRestaurants method

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (query.isEmpty) {
      // If query is empty, show a default list or all loaded restaurants
      await restaurantProvider.loadRestaurants(limit: 20); // Load a default list
       if (mounted) {
          setState(() {
            _searchResults = restaurantProvider.restaurants;
          });
       }
    } else {
      await restaurantProvider.searchRestaurants(query);
       if (mounted) {
           setState(() {
            // Assuming searchRestaurants updates provider.restaurants or a specific search results list
            // If searchRestaurants updates provider.restaurants, this is fine.
            // If it updates a different list in the provider, adjust accordingly.
            _searchResults = restaurantProvider.restaurants; 
           });
       }
    }
     if (mounted) {
        setState(() {
          _isLoading = false;
        });
     }
  }

  void _toggleRestaurantSelection(String restaurantId) {
    setState(() {
      if (_selectedRestaurantIds.contains(restaurantId)) {
        _selectedRestaurantIds.remove(restaurantId);
      } else {
        if (_selectedRestaurantIds.length < widget.maxSelectionCount) {
          _selectedRestaurantIds.add(restaurantId);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can select a maximum of ${widget.maxSelectionCount} restaurants.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Top ${widget.maxSelectionCount} Restaurants'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedRestaurantIds);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Restaurants',
                hintText: 'Enter restaurant name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchController.text.isNotEmpty // Use _searchController.text
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Optional: Debounce search for better performance
                // For now, search on every change
                _performSearch(value);
              },
              onSubmitted: _performSearch, // Also search on submit
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Selected: ${_selectedRestaurantIds.length}/${widget.maxSelectionCount}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
             Expanded(
                child: Center(
                    child: Text('No restaurants found for "$_searchQuery".',
                        style: TextStyle(color: Colors.grey[600]))))
          else if (_searchResults.isEmpty && _searchQuery.isEmpty)
             Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Search for restaurants to select your top ${widget.maxSelectionCount}!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])
                      ),
                    ],
                  )
                )
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final restaurant = _searchResults[index];
                  final bool isSelected = _selectedRestaurantIds.contains(restaurant.id);
                  return ListTile(
                    leading: restaurant.images.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(restaurant.images.first),
                            onBackgroundImageError: (exception, stackTrace) {
                                // Optionally log error or show placeholder
                            },
                          )
                        : CircleAvatar(backgroundColor: Colors.grey[200], child: Icon(Icons.restaurant, color: Colors.grey[400])),
                    title: Text(restaurant.name),
                    subtitle: Text(restaurant.cuisineTypes.join(', ')),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleRestaurantSelection(restaurant.id);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    onTap: () {
                      _toggleRestaurantSelection(restaurant.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
