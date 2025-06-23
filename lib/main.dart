// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Corrected import paths
import 'package:dyme_eat/firebase_options.dart'; // Correctly references the generated file
import 'package:dyme_eat/screens/wrapper.dart';
import 'package:dyme_eat/ui/theme.dart'; // Imports the new theme file

void main() async {
  // Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Wrap the app in a ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  // Added a const constructor for performance and to satisfy linter rules
  const MyApp({super.key});

  // Added the required @override annotation
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dyme Eat',
      // Use the new AppTheme class for theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
