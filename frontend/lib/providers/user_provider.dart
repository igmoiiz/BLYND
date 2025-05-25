import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/Model/user_model.dart';
import 'package:frontend/services/api_service.dart';

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
      throw e; // Re-throw to handle in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
