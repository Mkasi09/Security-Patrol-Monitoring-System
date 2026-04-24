import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        // First set a temporary user with basic info
        _currentUser = User(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          role: 'guard', // Default role, will be updated from Firestore
          createdAt: DateTime.now(),
        );
        notifyListeners();
        
        // Then fetch complete user data from Firestore
        try {
          final userData = await _firestoreService.getUserById(user.uid);
          if (userData != null) {
            _currentUser = userData;
            notifyListeners();
          }
        } catch (e) {
          // If Firestore fetch fails, keep the default user
          debugPrint('Failed to fetch user data from Firestore: $e');
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> needsPasswordReset() async {
    if (_currentUser == null) return false;
    
    try {
      final user = await _firestoreService.getUserById(_currentUser!.id);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return !user.hasResetPassword && user.role == 'guard';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
