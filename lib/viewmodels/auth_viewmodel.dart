import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:email_otp/email_otp.dart';
import 'dart:convert';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';

class AuthViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _simulatedOtp; // For simulation purposes
  String? get simulatedOtp => _simulatedOtp;

  AuthViewModel(this._keyStorage, this._sessionService) {
    _sessionService.onTimeout = logout;
  }

  Future<bool> sendOtp(String email) async {
    // For simulation: generate a random 6-digit OTP
    _simulatedOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    notifyListeners();
    return true;
  }

  bool verifyOtp(String otp) {
    return _simulatedOtp == otp;
  }

  Future<bool> login(String email, String password) async {
    // Check if user is registered
    Map<String, String> registeredUsers = await _getRegisteredUsers();
    if (registeredUsers.containsKey(email) && registeredUsers[email] == password) {
      await _keyStorage.saveValue('last_logged_in_user', email);
      await _keyStorage.saveValue('has_logged_in_once', 'true');
      _isLoggedIn = true;
      _sessionService.startTimer();
      notifyListeners();
      return true;
    }
    return false; // User not registered or wrong password
  }

  /// Persist or clear the remembered email. Passing `null` clears it.
  Future<void> setRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _keyStorage.deleteValue('remembered_email');
    } else {
      await _keyStorage.saveValue('remembered_email', email);
    }
  }

  Future<String?> getRememberedEmail() async {
    return await _keyStorage.readValue('remembered_email');
  }

  Future<void> clearRememberedEmail() async {
    await _keyStorage.deleteValue('remembered_email');
  }

  Future<bool> register(String email, String password) async {
    // Store user credentials
    Map<String, String> registeredUsers = await _getRegisteredUsers();
    registeredUsers[email] = password;
    await _saveRegisteredUsers(registeredUsers);
    return true;
  }

  Future<Map<String, String>> _getRegisteredUsers() async {
    String? usersJson = await _keyStorage.readValue('registered_users');
    if (usersJson == null) return {};
    try {
      Map<String, dynamic> usersMap = jsonDecode(usersJson);
      return usersMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveRegisteredUsers(Map<String, String> users) async {
    String usersJson = jsonEncode(users);
    await _keyStorage.saveValue('registered_users', usersJson);
  }

  Future<bool> authenticateWithBiometrics() async {
    final hasLoggedInOnce = await _keyStorage.readValue('has_logged_in_once');
    if (hasLoggedInOnce != 'true') return false;

    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) return false;

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CipherTask',
      );
      if (authenticated) {
        // Get the last logged in user email for biometric login
        final lastEmail = await _keyStorage.readValue('last_logged_in_user');
        if (lastEmail != null) {
          // Ensure the last logged in user is still set
          await _keyStorage.saveValue('last_logged_in_user', lastEmail);
        }
        _isLoggedIn = true;
        _sessionService.startTimer();
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getLoggedInUserEmail() async {
    // Try to get the last logged in email first
    final lastEmail = await _keyStorage.readValue('last_logged_in_user');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      return lastEmail;
    }

    // Fallback to registered email if last login email not found
    final registeredEmail = await _keyStorage.readValue('user_email');
    if (registeredEmail != null && registeredEmail.isNotEmpty) {
      return registeredEmail;
    }

    return null;
  }

  void logout() {
    _isLoggedIn = false;
    _sessionService.stopTimer();
    notifyListeners();
  }

  void handleUserInteraction() {
    if (_isLoggedIn) {
      _sessionService.resetTimer();
    }
  }
}
