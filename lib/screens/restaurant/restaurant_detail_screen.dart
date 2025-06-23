// lib/screens/restaurant/restaurant_detail_screen.dart
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/models/restaurant.dart';
import 'package:dyme_eat/models/review.dart'; // << IMPORT REVIEW
import 'package:dyme_eat/screens/restaurant/add_tip_screen.dart';
import 'package:fl_chart/fl_chart.dart'; // << IMPORT FL_CHART
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

// << NEW PROVIDER FOR REVIEWS >>
final reviewsStreamProvider = StreamProvider.autoDispose.family<List<Review>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
    .collection('reviews')
    .where('restaurantId', isEqualTo: restaurantId)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc.data())).toList());
});

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(tipsStreamProvider(restaurant.id));
    final reviewsAsync = ref.watch(reviewsStreamProvider(restaurant.id)); // << WATCH REVIEWS

    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Placeholder for Taste Signature visualization
          Card(
            child: SizedBox(
              height: 250, //Give the chart some space
              child: reviewsAsync.when(
                data: (reviews) => _buildTasteSignatureChart(context, reviews),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text("Can't load taste data")),
              ),
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

  // << NEW WIDGET FOR THE RADAR CHART >>
  Widget _buildTasteSignatureChart(BuildContext context, List<Review> reviews) {
    if (reviews.isEmpty) {
      return const Center(child: Text("No reviews yet. Be the first!"));
    }

    // --- Calculate Average Taste Data (Client-Side) ---
    final Map<String, double> aggregatedData = {};
    final Map<String, int> counts = {};

    for (var review in reviews) {
      review.tasteDialData.forEach((key, value) {
        aggregatedData[key] = (aggregatedData[key] ?? 0) + value;
        counts[key] = (counts[key] ?? 0) + 1;
      });
    }

    final tasteKeys = aggregatedData.keys.toList();
    final avgData = aggregatedData.map((key, value) => MapEntry(key, value / counts[key]!));
    
    // Ensure we have data to display
    if (tasteKeys.isEmpty) {
        return const Center(child: Text("No taste data recorded yet."));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: avgData.values.map((value) => RadarEntry(value: value)).toList(),
              borderColor: Theme.of(context).colorScheme.primary,
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.grey, width: 2),
          tickBorderData: const BorderSide(color: Colors.grey, width: 1),
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          getTitle: (index, angle) {
              return RadarChartTitle(
                text: tasteKeys[index],
                angle: angle,
              );
          },
          tickCount: 5, // Represents the 0-5 scale
          maxLimit: 5, // Explicitly set the max limit of the scale
        ),
      ),
    );
  }

}
