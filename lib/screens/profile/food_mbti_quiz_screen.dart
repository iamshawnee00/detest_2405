// lib/screens/profile/food_mbti_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

// Define Food MBTI types conceptually for now
// In a more advanced version, these could come from a config or have more details
enum FoodMBTIType {
  adventurousEpicurean,
  classicComfortSeeker,
  healthConsciousGourmet,
  socialGrazer,
  spontaneousSnacker,
  balancedExplorer, // Added a general one
  unknown,
}

extension FoodMBTITypeExtension on FoodMBTIType {
  String get displayName {
    switch (this) {
      case FoodMBTIType.adventurousEpicurean:
        return 'Adventurous Epicurean';
      case FoodMBTIType.classicComfortSeeker:
        return 'Classic Comfort Seeker';
      case FoodMBTIType.healthConsciousGourmet:
        return 'Health-Conscious Gourmet';
      case FoodMBTIType.socialGrazer:
        return 'Social Grazer';
      case FoodMBTIType.spontaneousSnacker:
        return 'Spontaneous Snacker';
      case FoodMBTIType.balancedExplorer:
        return 'Balanced Explorer';
      case FoodMBTIType.unknown:
        return 'Not Yet Discovered';
    }
  }

  String get description {
    switch (this) {
      case FoodMBTIType.adventurousEpicurean:
        return 'You love trying new, exotic, and unique foods. Bold flavors and unusual ingredients excite you!';
      case FoodMBTIType.classicComfortSeeker:
        return 'You prefer familiar, traditional, and comforting dishes. Nostalgia and reliability in food are key for you.';
      case FoodMBTIType.healthConsciousGourmet:
        return 'You prioritize nutritious, fresh, and wholesome foods. Clean eating is important, but you still appreciate great flavor.';
      case FoodMBTIType.socialGrazer:
        return 'You enjoy food most in social settings. Sharing plates and trying a bit of everything is your style.';
      case FoodMBTIType.spontaneousSnacker:
        return 'You eat based on impulse and current cravings. Less about planned meals, more about what feels right in the moment.';
      case FoodMBTIType.balancedExplorer:
        return 'You enjoy a good mix of trying new things and sticking to beloved classics. Variety is your spice of life!';
      case FoodMBTIType.unknown:
        return 'Take the quiz to discover your foodie personality!';
    }
  }
}


class FoodMBTIQuizScreen extends StatefulWidget {
  final String currentFoodMBTI; // Pass the current MBTI to pre-select or show

  const FoodMBTIQuizScreen({super.key, required this.currentFoodMBTI});

  @override
  State<FoodMBTIQuizScreen> createState() => _FoodMBTIQuizScreenState();
}

class _FoodMBTIQuizScreenState extends State<FoodMBTIQuizScreen> {
  // For a real quiz, you'd have a list of questions and manage answers
  // For this placeholder, we'll just display the types and let user "select" one
  // or simulate a result.

  FoodMBTIType _selectedType = FoodMBTIType.unknown;
  bool _quizCompleted = false; // Simulate quiz completion

  // Placeholder questions - in a real app, these would be more interactive
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'When trying a new restaurant, you are most likely to:',
      'options': [
        {'text': 'Order the most unusual item', 'type': FoodMBTIType.adventurousEpicurean},
        {'text': 'Look for a dish you know and love', 'type': FoodMBTIType.classicComfortSeeker},
        {'text': 'Check for healthy options', 'type': FoodMBTIType.healthConsciousGourmet},
        {'text': 'Suggest sharing plates', 'type': FoodMBTIType.socialGrazer},
      ],
      'userAnswer': null, // To store user's choice index
    },
    {
      'question': 'Your ideal weekend meal involves:',
      'options': [
        {'text': 'Exploring a new food market', 'type': FoodMBTIType.adventurousEpicurean},
        {'text': 'A home-cooked comfort meal', 'type': FoodMBTIType.classicComfortSeeker},
        {'text': 'A light, fresh meal after a workout', 'type': FoodMBTIType.healthConsciousGourmet},
        {'text': 'A lively brunch with friends', 'type': FoodMBTIType.socialGrazer},
      ],
      'userAnswer': null,
    },
     {
      'question': 'When you think about "snacks", you imagine:',
      'options': [
        {'text': 'Something new from an international store', 'type': FoodMBTIType.spontaneousSnacker},
        {'text': 'Your go-to chips or cookies', 'type': FoodMBTIType.classicComfortSeeker},
        {'text': 'Fruits, nuts, or a protein bar', 'type': FoodMBTIType.healthConsciousGourmet},
        {'text': 'Whatever is being passed around at a party', 'type': FoodMBTIType.socialGrazer},
      ],
      'userAnswer': null,
    }
    // Add more questions
  ];

  int _currentQuestionIndex = 0;
  Map<FoodMBTIType, int> _scores = {};


  @override
  void initState() {
    super.initState();
    // Try to parse the current MBTI string to its enum value
    try {
      _selectedType = FoodMBTIType.values.firstWhere(
        (e) => e.displayName.toLowerCase() == widget.currentFoodMBTI.toLowerCase(),
        orElse: () => FoodMBTIType.unknown,
      );
    } catch (e) {
      _selectedType = FoodMBTIType.unknown;
    }
     _scores = { for (var type in FoodMBTIType.values) type : 0 };
  }

  void _answerQuestion(FoodMBTIType type) {
    setState(() {
      _scores[type] = (_scores[type] ?? 0) + 1; // Increment score for the chosen type's tendency
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _quizCompleted = true;
        _calculateResult();
      }
    });
  }

  void _calculateResult() {
    if (_scores.isEmpty) {
      _selectedType = FoodMBTIType.unknown;
      return;
    }
    // Find the type with the highest score
    FoodMBTIType resultType = _scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    setState(() {
      _selectedType = resultType;
    });
  }


  Future<void> _saveFoodMBTI() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Save the display name of the selected type
    bool success = await userProvider.updateUserFoodieCard(
      userId: currentUser.id,
      foodMBTI: _selectedType.displayName,
    );

    if (success) {
      await authProvider.refreshUserModel(); // Refresh global user model
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Food MBTI updated to: ${_selectedType.displayName}'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, _selectedType.displayName); // Pass back the selected MBTI
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.errorMessage ?? 'Failed to update Food MBTI.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Your Foodie Type'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: !_quizCompleted
            ? _buildQuizSection()
            : _buildResultSection(),
      ),
    );
  }

  Widget _buildQuizSection() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const Center(child: Text("Quiz loading or completed."));
    }
    final questionData = _questions[_currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          questionData['question'] as String,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        ...(questionData['options'] as List<Map<String,dynamic>>).map<Widget>((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // full width
                // backgroundColor: Colors.grey[200],
                // foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(option['text'] as String, textAlign: TextAlign.center),
              onPressed: () => _answerQuestion(option['type'] as FoodMBTIType),
            ),
          );
        }),
        const SizedBox(height: 20),
         LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          minHeight: 6,
        ),
      ],
    );
  }


  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Quiz Completed!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 20),
        Icon(
          _getIconForMBTI(_selectedType),
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Your Foodie Type is:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          _selectedType.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _selectedType.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save My Foodie Type'),
          onPressed: _saveFoodMBTI,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _currentQuestionIndex = 0;
              _quizCompleted = false;
              _scores = { for (var type in FoodMBTIType.values) type : 0 };
              _selectedType = FoodMBTIType.unknown;
            });
          },
          child: const Text('Retake Quiz'),
        ),
      ],
    );
  }

   IconData _getIconForMBTI(FoodMBTIType type) {
    switch (type) {
      case FoodMBTIType.adventurousEpicurean:
        return Icons.explore_outlined;
      case FoodMBTIType.classicComfortSeeker:
        return Icons.bakery_dining_outlined;
      case FoodMBTIType.healthConsciousGourmet:
        return Icons.eco_outlined;
      case FoodMBTIType.socialGrazer:
        return Icons.people_alt_outlined;
      case FoodMBTIType.spontaneousSnacker:
        return Icons.fastfood_outlined;
      case FoodMBTIType.balancedExplorer:
        return Icons.restaurant_menu_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
