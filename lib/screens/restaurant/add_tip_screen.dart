// lib/screens/restaurant/add_tip_screen.dart
import 'package:dyme_eat/models/pathfinder_tip.dart';
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTipScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const AddTipScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<AddTipScreen> createState() => _AddTipScreenState();
}

class _AddTipScreenState extends ConsumerState<AddTipScreen> {
  final _tipController = TextEditingController();
  TipType _selectedTipType = TipType.general;
  bool _isLoading = false;

  Future<void> _submitTip() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null || _tipController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final newTip = PathfinderTip(
      id: '', // Will be set by Firestore
      authorId: user.uid,
      restaurantId: widget.restaurantId,
      tipType: _selectedTipType,
      tipContent: _tipController.text,
      timestamp: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('pathfinderTips').add(newTip.toFirestore());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tip submitted! Verification pending.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit tip: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Pathfinder Tip')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<TipType>(
                    value: _selectedTipType,
                    items: TipType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedTipType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Tip Category'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tipController,
                    decoration: const InputDecoration(labelText: 'Your Tip', hintText: 'e.g., Park behind the building after 6 PM'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitTip,
                    child: const Text('Submit Tip'),
                  )
                ],
              ),
            ),
    );
  }
}