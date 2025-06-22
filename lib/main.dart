// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyme_eat/firebase_options.dart';
import 'package:dyme_eat/screens/wrapper.dart';
import 'package:dyme_eat/ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @Override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dyme Eat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
