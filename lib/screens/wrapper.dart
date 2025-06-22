// lib/screens/wrapper.dart
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/screens/auth/login_screen.dart';
import 'package:dyme_eat/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const Shell();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Something went wrong!\n$error'),
        ),
      ),
    );
  }
}
