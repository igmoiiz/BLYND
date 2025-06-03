import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/Model/user_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentUser() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await ApiService.getCurrentUser();
      _user = user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    Uint8List? profileImage,
  }) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedUser = await ApiService.updateProfile(
        name: name,
        bio: bio,
        profileImage: profileImage,
      );

      // Update the local user data with the response
      _user = updatedUser;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow; // Re-throw to handle in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Call backend logout endpoint
      await ApiService.logout();

      // Clear local storage
      await prefs.clear();

      // Clear token from ApiService
      ApiService.setToken(null);

      // Clear user data
      _user = null;
      _isLoading = false;
      _error = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out from backend: $e');
      // Even if backend call fails, clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ApiService.setToken(null);
      _user = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
