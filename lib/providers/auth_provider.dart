// File: lib/providers/auth_provider.dart

import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Still needed for User type
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Import the logger package
import '../models/user_model.dart'; // Ensure this path is correct
import '../auth_service.dart';   // <<--- IMPORTANT: Make sure this imports your ACTUAL AuthService

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  StreamSubscription<User?>? _authStateSubscription;

  User? _firebaseUser;
  UserModel? _userModel;

  bool _isLoadingInitial = true;
  bool _isOperating = false;

  // Initialize the logger
  final Logger _logger = Logger(
    printer: PrettyPrinter(
        methodCount: 1, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        dateTimeFormat: DateTimeFormat.none // Replaced deprecated printTime: false
        ),
  );

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isOperating => _isOperating;

  AuthProvider({required AuthService authService}) : _authService = authService {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    _onAuthStateChanged(_auth.currentUser);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    bool wasAlreadyLoadingInitial = _isLoadingInitial;

    _firebaseUser = user;
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _userModel = null;
    }

    if (wasAlreadyLoadingInitial) {
      _setLoadingInitial(false);
    } else {
      notifyListeners();
    }
  }

  Future<void> _loadUserModel(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _userModel = UserModel.fromJson(doc.data()!);
      } else {
        _userModel = null;
        _logger.w('AuthProvider: User document does not exist for uid: $userId or data is null.');
      }
    } catch (e, s) {
      _logger.e('AuthProvider: Error loading user model', error: e, stackTrace: s);
      _userModel = null;
    }
  }

  void _setLoadingInitial(bool value) {
    if (_isLoadingInitial != value) {
      _isLoadingInitial = value;
      notifyListeners();
    }
  }

  void _setOperating(bool value) {
    if (_isOperating != value) {
      _isOperating = value;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _setOperating(true);
    try {
      await _authService.signUpWithEmailPassword(email, password, name);
    } on FirebaseAuthException catch (e, s) {
      _logger.e('AuthProvider: Sign up error (FirebaseAuthException)', error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      _logger.e('AuthProvider: Sign up error (General)', error: e, stackTrace: s);
      rethrow;
    } finally {
      _setOperating(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    _setOperating(true);
    try {
      await _authService.signInWithEmailPassword(email, password);
    } on FirebaseAuthException catch (e, s) {
      _logger.e('AuthProvider: Sign in error (FirebaseAuthException)', error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      _logger.e('AuthProvider: Sign in error (General)', error: e, stackTrace: s);
      rethrow;
    } finally {
      _setOperating(false);
    }
  }

  Future<void> signOut() async {
    _setOperating(true);
    try {
      await _authService.signOut();
    } catch (e, s) {
      _logger.e('AuthProvider: SignOut error', error: e, stackTrace: s);
      rethrow;
    } finally {
      _setOperating(false);
    }
  }

  Future<void> refreshUserModel() async {
    if (_firebaseUser != null) {
      _logger.i("AuthProvider: Refreshing user model for ${_firebaseUser!.uid}");
      // _setOperating(true); // Optional: set loading state if desired
      await _loadUserModel(_firebaseUser!.uid); // This loads from Firestore
      // _setOperating(false);
      notifyListeners(); // Notify listeners that userModel might have changed
    } else {
      _logger.w("AuthProvider: refreshUserModel called but no firebaseUser available.");
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _logger.i("AuthProvider disposed"); // Example of an info log
    super.dispose();
  }
}
