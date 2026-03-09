import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';

class AuthViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _supabase = Supabase.instance.client;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  String? _authError;
  String? get authError => _authError;

  AuthViewModel(this._keyStorage, this._sessionService) {
    _sessionService.onTimeout = logout;
    _checkInitialSession();
  }

  /// Automatically check if there is a valid Supabase session on startup
  Future<void> _checkInitialSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _isLoggedIn = true;
      _sessionService.startTimer();
      notifyListeners();
    }
  }

  /// Sends a real OTP via Supabase SignUp
  Future<Map<String, dynamic>> sendOtp(String email, String password) async {
    try {
      _authError = null;
      final lowercaseEmail = email.toLowerCase();
      debugPrint('DEBUG: Attempting signUp for: $lowercaseEmail');
      
      final response = await _supabase.auth.signUp(
        email: lowercaseEmail,
        password: password,
      );
      
      debugPrint('DEBUG: signUp response user: ${response.user?.id}');
      debugPrint('DEBUG: signUp response session: ${response.session != null}');
      
      if (response.session != null) {
        // Confirmation is OFF, user is already logged in
        _isLoggedIn = true;
        _sessionService.startTimer();
        await _keyStorage.saveValue('last_logged_in_user', lowercaseEmail);
        await _keyStorage.saveValue('has_logged_in_once', 'true');
        notifyListeners();
        return {'status': 'logged_in'};
      }

      if (response.user != null) {
        // Confirmation is ON, OTP sent
        return {'status': 'otp_sent'};
      }

      _authError = 'Registration failed. Please try again.';
      notifyListeners();
      return {'status': 'error'};
    } catch (e) {
      debugPrint('DEBUG: Auth error in sendOtp: $e');
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('already registered') || errorStr.contains('already exists')) {
        try {
          debugPrint('DEBUG: User exists, attempting resend fallback...');
          await _supabase.auth.resend(
            type: OtpType.signup,
            email: email.toLowerCase(),
          );
          return {'status': 'otp_sent'};
        } catch (resendError) {
          debugPrint('DEBUG: Resend fallback failed: $resendError');
          // If resend fails, they might be already confirmed
          _authError = 'User already exists. Please login instead.';
          notifyListeners();
          return {'status': 'error'};
        }
      } else {
        _authError = e.toString().replaceFirst('AuthException: ', '');
        notifyListeners();
        return {'status': 'error'};
      }
    }
  }

  /// Resends the signup OTP
  Future<bool> resendOtp(String email) async {
    try {
      _authError = null;
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.toLowerCase(),
      );
      return true;
    } catch (e) {
      debugPrint('Resend error: $e');
      _authError = e.toString().replaceFirst('AuthException: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Verifies the 6-8 digit code sent to Gmail/Outlook
  Future<bool> verifyRegistrationOtp(String email, String token) async {
    try {
      _authError = null;
      final lowercaseEmail = email.toLowerCase();
      debugPrint('Verifying OTP for: $lowercaseEmail with token: $token');
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: token,
        email: lowercaseEmail,
      );
      
      debugPrint('OTP verification response session: ${response.session != null}');
      if (response.session != null) {
        _isLoggedIn = true;
        _sessionService.startTimer();
        await _keyStorage.saveValue('last_logged_in_user', lowercaseEmail);
        await _keyStorage.saveValue('has_logged_in_once', 'true');
        notifyListeners();
        return true;
      }
      _authError = 'Verification failed. Please check the code.';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('OTP Verification error: $e');
      _authError = e.toString().replaceFirst('AuthException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _authError = null;
      final lowercaseEmail = email.toLowerCase();
      debugPrint('Attempting login for: $lowercaseEmail');
      final response = await _supabase.auth.signInWithPassword(
        email: lowercaseEmail,
        password: password,
      );
      
      debugPrint('Login response session: ${response.session != null}');
      if (response.session != null) {
        await _keyStorage.saveValue('last_logged_in_user', lowercaseEmail);
        await _keyStorage.saveValue('has_logged_in_once', 'true');
        _isLoggedIn = true;
        _sessionService.startTimer();
        notifyListeners();
        return true;
      }
      _authError = 'Login failed. Please check your credentials.';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _authError = e.toString().replaceFirst('AuthException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final hasLoggedInOnce = await _keyStorage.readValue('has_logged_in_once');
    if (hasLoggedInOnce != 'true') return false;

    // Check if we still have a valid Supabase user session we can "unlock"
    // If the session is totally gone (e.g., after manual logout), 
    // we allow the unlock but note that Supabase features might be limited.
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
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<String?> getLoggedInUserEmail() async {
    final user = _supabase.auth.currentUser;
    if (user != null && user.email != null) {
      return user.email;
    }
    return await _keyStorage.readValue('last_logged_in_user');
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _isLoggedIn = false;
    _sessionService.stopTimer();
    notifyListeners();
  }

  void handleUserInteraction() {
    if (_isLoggedIn) {
      _sessionService.resetTimer();
    }
  }

  // Helper methods for email remembrance
  Future<void> setRememberedEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _keyStorage.deleteValue('remembered_email');
    } else {
      await _keyStorage.saveValue('remembered_email', email);
    }
  }

  Future<String?> getRememberedEmail() async => await _keyStorage.readValue('remembered_email');
}
