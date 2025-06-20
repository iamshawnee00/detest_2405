// lib/screens/profile/edit_foodie_card_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart'; // To refresh user model after update
import 'food_mbti_quiz_screen.dart'; // Import the new quiz screen
import 'select_top_restaurants_screen.dart'; // We will create this screen next

class EditFoodieCardScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditFoodieCardScreen({super.key, required this.currentUser});

  @override
  State<EditFoodieCardScreen> createState() => _EditFoodieCardScreenState();
}

class _EditFoodieCardScreenState extends State<EditFoodieCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _bioController;
  
  late List<String> _currentPreferences;
  final TextEditingController _newPreferenceController = TextEditingController();
  late List<String> _currentAllergies;
  final TextEditingController _newAllergyController = TextEditingController();

  late TextEditingController _foodMBTIController;
  
  // For top restaurants, manage as a list of IDs with a chip editor
  late List<String> _currentTopRestaurantIds;
  final TextEditingController _newTopRestaurantIdController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _avatarUrlController = TextEditingController(text: widget.currentUser.avatarUrl);
    _bioController = TextEditingController(text: widget.currentUser.foodieCardBio);
    
    _currentPreferences = List<String>.from(widget.currentUser.preferences);
    _currentAllergies = List<String>.from(widget.currentUser.allergies);

    _foodMBTIController = TextEditingController(text: widget.currentUser.foodMBTI);
    _currentTopRestaurantIds = List<String>.from(widget.currentUser.topRestaurantIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    _newPreferenceController.dispose();
    _newAllergyController.dispose();
    _foodMBTIController.dispose();
    _newTopRestaurantIdController.dispose(); // Dispose the new controller
    super.dispose();
  }

  void _addPreference() {
    if (_newPreferenceController.text.trim().isNotEmpty) {
      setState(() {
        final newPref = _newPreferenceController.text.trim();
        if (!_currentPreferences.map((p) => p.toLowerCase()).contains(newPref.toLowerCase())) {
          _currentPreferences.add(newPref);
        }
        _newPreferenceController.clear();
      });
    }
  }

  void _removePreference(String preferenceToRemove) {
    setState(() {
      _currentPreferences.remove(preferenceToRemove);
    });
  }

  void _addAllergy() {
    if (_newAllergyController.text.trim().isNotEmpty) {
      setState(() {
        final newAllergy = _newAllergyController.text.trim();
        if (!_currentAllergies.map((a) => a.toLowerCase()).contains(newAllergy.toLowerCase())) {
          _currentAllergies.add(newAllergy);
        }
        _newAllergyController.clear();
      });
    }
  }

  void _removeAllergy(String allergyToRemove) {
    setState(() {
      _currentAllergies.remove(allergyToRemove);
    });
  }

  void _addTopRestaurantId() {
    if (_newTopRestaurantIdController.text.trim().isNotEmpty) {
      setState(() {
        final newId = _newTopRestaurantIdController.text.trim();
        // Basic check to avoid duplicates, consider more robust ID validation if needed
        if (!_currentTopRestaurantIds.contains(newId)) { 
          if (_currentTopRestaurantIds.length < 5) { // Limit to 5 top restaurants
             _currentTopRestaurantIds.add(newId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can add a maximum of 5 top restaurants.'), backgroundColor: Colors.orange),
            );
          }
        }
        _newTopRestaurantIdController.clear();
      });
    }
  }

  void _removeTopRestaurantId(String idToRemove) {
    setState(() {
      _currentTopRestaurantIds.remove(idToRemove);
    });
  }


  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await userProvider.updateUserFoodieCard(
        userId: widget.currentUser.id,
        name: _nameController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null,
        foodieCardBio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        preferences: _currentPreferences,
        allergies: _currentAllergies,
        foodMBTI: _foodMBTIController.text.trim().isNotEmpty ? _foodMBTIController.text.trim() : null,
        topRestaurantIds: _currentTopRestaurantIds, // Use the list directly
      );

      if (success) {
        await authProvider.refreshUserModel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foodie Card updated successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Pop with true to indicate save
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userProvider.errorMessage ?? 'Failed to update Foodie Card.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToFoodMBTIQuiz() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FoodMBTIQuizScreen(
          currentFoodMBTI: _foodMBTIController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _foodMBTIController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Foodie Card'),
        actions: [
          IconButton(
            icon: userProvider.isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : const Icon(Icons.save_outlined),
            onPressed: userProvider.isUpdating ? null : _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildSectionTitle(context, 'Basic Info'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(labelText: 'Avatar URL (Optional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Foodie Card Bio (Optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, 'Food Preferences'),
              _buildChipListEditor(
                context,
                items: _currentPreferences,
                controller: _newPreferenceController,
                onAdd: _addPreference,
                onRemove: _removePreference,
                label: 'Add Preference',
                hint: 'e.g., Spicy, Italian, Desserts',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, 'Allergies'),
               _buildChipListEditor(
                context,
                items: _currentAllergies,
                controller: _newAllergyController,
                onAdd: _addAllergy,
                onRemove: _removeAllergy,
                label: 'Add Allergy',
                hint: 'e.g., Peanuts, Gluten',
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, 'Food MBTI'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _foodMBTIController,
                      decoration: const InputDecoration(
                        labelText: 'Food MBTI',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: _navigateToFoodMBTIQuiz,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.psychology_outlined, size: 18),
                    label: const Text('Quiz'),
                    onPressed: _navigateToFoodMBTIQuiz,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16.5)),
                  )
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Your Top Picks (Max 5)'),
              if (_currentTopRestaurantIds.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _currentTopRestaurantIds.map((id) => Chip(
                    label: Text(id, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    // You might fetch restaurant names here for a better display, but for now IDs are fine
                  )).toList(),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: Text(_currentTopRestaurantIds.isEmpty ? 'Select Top Restaurants' : 'Change Top Restaurants (${_currentTopRestaurantIds.length}/5)'),
                onPressed: _navigateToSelectTopRestaurants,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: userProvider.isUpdating ? const SizedBox.shrink() : const Icon(Icons.save),
                label: userProvider.isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
                onPressed: userProvider.isUpdating ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildChipListEditor(
    BuildContext context, {
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items.map((item) => Chip(
              label: Text(item),
              onDeleted: () => onRemove(item),
              deleteIconColor: Theme.of(context).primaryColor.withAlpha((0.7 * 255).round()), // Corrected withOpacity
              backgroundColor: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()), // Corrected withOpacity
              labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).primaryColorDark : Theme.of(context).colorScheme.onSurface),
            )).toList(),
          ),
        if (items.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
              color: Theme.of(context).primaryColor,
              tooltip: 'Add $label',
            ),
          ],
        ),
      ],
    );
  }
}
