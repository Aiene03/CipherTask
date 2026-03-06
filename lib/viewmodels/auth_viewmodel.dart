import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:email_otp/email_otp.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';

class AuthViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthViewModel(this._keyStorage, this._sessionService) {
    _sessionService.onTimeout = logout;
  }

  Future<bool> sendOtp(String email) async {
    return await EmailOTP.sendOTP(email: email);
  }

  bool verifyOtp(String otp) {
    return EmailOTP.verifyOTP(otp: otp);
  }

  Future<bool> login(String email, String password) async {
    // Mocking successful login
    await _keyStorage.saveValue('last_logged_in_user', email);
    await _keyStorage.saveValue('has_logged_in_once', 'true');
    _isLoggedIn = true;
    _sessionService.startTimer();
    notifyListeners();
    return true;
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
    // Mocking successful registration
    await _keyStorage.saveValue('user_email', email);
    return true;
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
        _isLoggedIn = true;
        _sessionService.startTimer();
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      return false;
    }
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
