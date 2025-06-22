// lib/screens/restaurant/restaurant_detail_screen.dart
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/screens/restaurant/add_tip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

final tipsStreamProvider = StreamProvider.autoDispose.family<List<PathfinderTip>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('pathfinderTips')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PathfinderTip.fromFirestore(doc)).toList());
});

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(tipsStreamProvider(restaurant.id));

    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Placeholder for Taste Signature visualization
          Card(
            child: Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text('Taste Signature (Radar Chart) - Coming Soon!'),
            ),
          ),
          const SizedBox(height: 24),
          
          // Pathfinder Tips Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pathfinder Tips", style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddTipScreen(restaurantId: restaurant.id)));
                },
              ),
            ],
          ),
          const Divider(),
          tipsAsync.when(
            data: (tips) {
              if (tips.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Be the first to leave a tip!"),
                ));
              }
              return Column(
                children: tips.map((tip) => ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(tip.tipContent),
                  subtitle: Text("shared ${timeago.format(tip.timestamp.toDate())}"),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text("Could not load tips.")),
          ),
        ],
      ),
    );
  }
}
