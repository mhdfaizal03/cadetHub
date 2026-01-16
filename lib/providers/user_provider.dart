import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _userSubscription?.cancel();
      if (user != null) {
        // User is logged in, start listening to their profile stream
        _userSubscription = _authService.getUserStream().listen((userData) {
          _user = userData;
          notifyListeners();
        });
      } else {
        // User logged out
        _user = null;
        notifyListeners();
      }
    });
  }

  // Manual setter might still be useful for optimistic updates or initial splash load
  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _userSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
