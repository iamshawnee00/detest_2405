// lib/screens/wrapper.dart
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/screens/auth/login_screen.dart';
import 'package:dyme_eat/screens/onboarding/onboarding_screen.dart';
import 'package:dyme_eat/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This provider will check if onboarding is complete
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboardingComplete') ?? false;
});


class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, now check if they've finished onboarding
          return onboardingComplete.when(
            data: (isComplete) {
              if (isComplete) {
                return const Shell(); // Go to main app
              } else {
                return const OnboardingScreen(); // Go to onboarding
              }
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Scaffold(body: Center(child: Text("Error loading onboarding status"))),
          );
        }
        // User is not logged in
        return const LoginScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Something went wrong!\n$error')),
      ),
    );
  }
}
