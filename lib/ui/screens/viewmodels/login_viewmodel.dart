import 'package:flutter/material.dart';
import 'package:my_mobile_app/data/models/user_model.dart';
import 'package:my_mobile_app/data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  LoginViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerificationEmail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resendVerificationEmail();
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.forgotPassword(email: email);
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(Object error) {
    final message = error.toString();
    if (message.contains('invalid-credential') || message.contains('wrong-password') || message.contains('invalid-email')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('user-not-found')) {
      return 'No account exists with this email.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later.';
    }
    if (message.contains('verify your email')) {
      return 'Please verify your email before logging in.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
