import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_mobile_app/data/models/user_model.dart';
import 'package:my_mobile_app/data/repositories/auth_repository.dart';
import 'package:my_mobile_app/data/services/cloudinary_service.dart';

class UserProvider extends ChangeNotifier {
  static const String _userKey = 'current_user';
  final AuthRepository _authRepository = AuthRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> saveUser(UserModel user) async {
    _user = user;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(user.toMap()));
    notifyListeners();
  }

  Future<void> loadUser() async {
    final preferences = await SharedPreferences.getInstance();
    final userJson = preferences.getString(_userKey);
    if (userJson != null) {
      try {
        _user = UserModel.fromMap(jsonDecode(userJson));
      } catch (e) {
        _user = null;
        await preferences.remove(_userKey);
      }
    }
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userKey);
    notifyListeners();
  }

  Future<bool> uploadProfileImage(XFile imageFile) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      // Switched to Cloudinary as requested
      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'shopify/profiles',
      );
      
      if (imageUrl.isNotEmpty) {
        await _authRepository.updateUserImage(uid: _user!.uid, imageUrl: imageUrl);
        _user = _user!.copyWith(userImage: imageUrl);
        await saveUser(_user!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Upload Profile Image Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
