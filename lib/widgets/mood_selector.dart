// widgets/mood_selector.dart
import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  final Function(String) onMoodSelected;

  const MoodSelector({super.key, required this.onMoodSelected});

  @override
  MoodSelectorState createState() => MoodSelectorState();
}

class MoodSelectorState extends State<MoodSelector> {
  String? selectedMood;

  final List<Map<String, dynamic>> moods = [
    {'name': 'Comfort Food', 'icon': Icons.favorite, 'tag': 'comfort-food'},
    {'name': 'Rainy Day', 'icon': Icons.cloud, 'tag': 'rainy-day'},
    {'name': 'Childhood', 'icon': Icons.child_care, 'tag': 'childhood-memories'},
    {'name': 'Celebration', 'icon': Icons.celebration, 'tag': 'celebration'},
    {'name': 'Quick Bite', 'icon': Icons.flash_on, 'tag': 'quick-bite'},
    {'name': 'Romantic', 'icon': Icons.favorite_border, 'tag': 'romantic'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = selectedMood == mood['tag'];
              
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedMood = mood['tag'];
                    });
                    widget.onMoodSelected(mood['tag']);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          mood['icon'],
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          mood['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}