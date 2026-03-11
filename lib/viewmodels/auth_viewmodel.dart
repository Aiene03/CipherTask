import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../services/key_storage_service.dart';
import '../services/session_service.dart';
import '../utils/constants.dart';

class AuthViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  final SessionService _sessionService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // Login attempt tracking
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 15;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _authError;
  String? get authError => _authError;

  int _failedLoginAttempts = 0;
  int get failedLoginAttempts => _failedLoginAttempts;

  bool _isLockedOut = false;
  bool get isLockedOut => _isLockedOut;

  DateTime? _lockoutEndTime;
  DateTime? get lockoutEndTime => _lockoutEndTime;

  String? _currentUserId;

  AuthViewModel(this._keyStorage, this._sessionService) {
    _sessionService.onTimeout = logout;
    _checkInitialSession();
    _loadLoginAttemptStatus();
  }

  /// Load saved login attempt status from secure storage
  Future<void> _loadLoginAttemptStatus() async {
    final attemptsStr = await _keyStorage.readValue('failed_login_attempts');
    final lockoutStr = await _keyStorage.readValue('lockout_end_time');
    final lockedStr = await _keyStorage.readValue('is_locked_out');

    if (attemptsStr != null) {
      _failedLoginAttempts = int.tryParse(attemptsStr) ?? 0;
    }

    if (lockoutStr != null) {
      _lockoutEndTime = DateTime.tryParse(lockoutStr);
      if (_lockoutEndTime != null && DateTime.now().isAfter(_lockoutEndTime!)) {
        // Lockout has expired, reset
        await _resetLoginAttempts();
      }
    }

    if (lockedStr == 'true' &&
        _lockoutEndTime != null &&
        DateTime.now().isBefore(_lockoutEndTime!)) {
      _isLockedOut = true;
    }

    notifyListeners();
  }

  /// Reset failed login attempts
  Future<void> _resetLoginAttempts() async {
    _failedLoginAttempts = 0;
    _isLockedOut = false;
    _lockoutEndTime = null;
    await _keyStorage.deleteValue('failed_login_attempts');
    await _keyStorage.deleteValue('lockout_end_time');
    await _keyStorage.deleteValue('is_locked_out');
    notifyListeners();
  }

  /// Record a failed login attempt
  Future<void> _recordFailedAttempt() async {
    _failedLoginAttempts++;
    await _keyStorage.saveValue(
      'failed_login_attempts',
      _failedLoginAttempts.toString(),
    );

    if (_failedLoginAttempts >= _maxLoginAttempts) {
      // Lock out the account
      _isLockedOut = true;
      _lockoutEndTime = DateTime.now().add(
        Duration(minutes: _lockoutDurationMinutes),
      );
      await _keyStorage.saveValue('is_locked_out', 'true');
      await _keyStorage.saveValue(
        'lockout_end_time',
        _lockoutEndTime!.toIso8601String(),
      );
      _authError =
          'Too many failed attempts. Please try again after $_lockoutDurationMinutes minutes.';
    } else {
      _authError =
          'Invalid email or password. ${_maxLoginAttempts - _failedLoginAttempts} attempts remaining.';
    }
    notifyListeners();
  }

  /// Check if user is currently locked out
  bool isCurrentlyLockedOut() {
    if (_isLockedOut && _lockoutEndTime != null) {
      if (DateTime.now().isAfter(_lockoutEndTime!)) {
        // Lockout has expired
        _resetLoginAttempts();
        return false;
      }
      return true;
    }
    return false;
  }

  /// Get remaining lockout time
  String? getRemainingLockoutTime() {
    if (_lockoutEndTime != null && _isLockedOut) {
      final remaining = _lockoutEndTime!.difference(DateTime.now());
      if (remaining.isNegative) return null;
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return '$minutes min ${seconds}s';
    }
    return null;
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

      if (errorStr.contains('already registered') ||
          errorStr.contains('already exists')) {
        try {
          debugPrint('DEBUG: User exists, attempting resend fallback...');
          await _supabase.auth.resend(
            type: supabase.OtpType.signup,
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
        type: supabase.OtpType.signup,
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
        type: supabase.OtpType.signup,
        token: token,
        email: lowercaseEmail,
      );

      debugPrint(
        'OTP verification response session: ${response.session != null}',
      );
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

  /// Parse and format Supabase auth errors into user-friendly messages
  String _parseAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('invalid credentials') ||
        errorStr.contains('invalid login') ||
        errorStr.contains('wrong') ||
        errorStr.contains('invalid email or password')) {
      return 'Invalid email or password';
    }

    if (errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('host not found')) {
      return 'Network error. Please check your internet connection';
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Request timed out. Please try again';
    }

    if (errorStr.contains('user not found') ||
        errorStr.contains('no user') ||
        errorStr.contains('email not found')) {
      return 'No account found with this email';
    }

    if (errorStr.contains('user is disabled') ||
        errorStr.contains('disabled')) {
      return 'This account has been disabled';
    }

    if (errorStr.contains('too many requests') ||
        errorStr.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again';
    }

    // Default: return original error message without the exception prefix
    return error
        .toString()
        .replaceFirst('AuthException: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<bool> login(String email, String password) async {
    // Check if account is locked out
    if (isCurrentlyLockedOut()) {
      _isLockedOut = true;
      _authError =
          'Account is locked. Try again in ${getRemainingLockoutTime()}';
      notifyListeners();
      return false;
    }

    try {
      _authError = null;

      // Input sanitization - trim whitespace
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedPassword = password.trim();

      // Validate inputs
      if (sanitizedEmail.isEmpty) {
        _authError = 'Please enter your email';
        notifyListeners();
        return false;
      }

      if (sanitizedPassword.isEmpty) {
        _authError = 'Please enter your password';
        notifyListeners();
        return false;
      }

      debugPrint('Attempting login for: $sanitizedEmail');
      final response = await _supabase.auth.signInWithPassword(
        email: sanitizedEmail,
        password: sanitizedPassword,
      );

      debugPrint('Login response session: ${response.session != null}');
      if (response.session != null) {
        // Reset failed attempts on successful login
        await _resetLoginAttempts();

        await _keyStorage.saveValue('last_logged_in_user', sanitizedEmail);
        await _keyStorage.saveValue('has_logged_in_once', 'true');
        _isLoggedIn = true;

        final currentUser = _supabase.auth.currentUser;
        String? lastUserId;
        if (currentUser != null && currentUser.id.isNotEmpty) {
          _currentUserId = currentUser.id;
          lastUserId = currentUser.id;
        }
        if (lastUserId != null) {
          await _keyStorage.saveValue(
            AppConstants.lastLoggedInUserIdKey,
            lastUserId,
          );
        }

        _sessionService.startTimer();
        notifyListeners();
        return true;
      }

      // Login failed but no exception - record attempt
      await _recordFailedAttempt();
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');

      // Record failed attempt
      await _recordFailedAttempt();

      // Parse error into user-friendly message
      _authError = _parseAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _authError = null;
    try {
      // First attempt Firebase Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _authError = 'Google sign-in cancelled by user.';
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final String? email = userCredential.user?.email;
      final String? firebaseUserId = userCredential.user?.uid;

      if (email != null && email.isNotEmpty) {
        _isLoggedIn = true;
        _sessionService.startTimer();
        await _keyStorage.saveValue('last_logged_in_user', email);
        await _keyStorage.saveValue('has_logged_in_once', 'true');

        if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
          _currentUserId = firebaseUserId;
          await _keyStorage.saveValue(
            AppConstants.lastLoggedInUserIdKey,
            firebaseUserId,
          );
        }

        notifyListeners();
        return true;
      }

      _authError = 'Google sign-in succeeded but no email found.';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Firebase Google Sign-In error: $e');
      _authError = 'Error during Google sign-in. Please try again.';
      notifyListeners();

      // Still allow Supabase fallback if Firebase path fails and provider enabled
      try {
        final response = await _supabase.auth.signInWithOAuth(
          supabase.OAuthProvider.google,
          redirectTo: 'com.ciphertask.cipher_task://login-callback',
        );
        if (response) {
          _isLoggedIn = true;
          _sessionService.startTimer();
          await _keyStorage.saveValue('has_logged_in_once', 'true');
          notifyListeners();
          return true;
        }
      } catch (supabaseError) {
        debugPrint('Supabase fallback Google Sign-In error: $supabaseError');
      }

      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final hasLoggedInOnce = await _keyStorage.readValue('has_logged_in_once');
    if (hasLoggedInOnce != 'true') {
      _authError =
          'Biometric login is disabled until you sign in at least once.';
      notifyListeners();
      return false;
    }

    final biometricEnabled = await isBiometricEnabled();
    if (!biometricEnabled) {
      _authError = 'Biometric login is disabled. Enable it in Profile first.';
      notifyListeners();
      return false;
    }

    // Check device biometric capabilities.
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      _authError = 'Biometric authentication is not available on this device.';
      notifyListeners();
      return false;
    }

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CipherTask',
        biometricOnly: false,
      );

      if (authenticated) {
        _isLoggedIn = true;
        _sessionService.startTimer();
        _authError = null;
        notifyListeners();
      } else {
        _authError = 'Biometric authentication failed or was canceled.';
        notifyListeners();
      }

      return authenticated;
    } catch (e) {
      debugPrint('Biometric error: $e');
      _authError = 'Biometric error: ${e.toString()}';
      notifyListeners();
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

  Future<String?> getLoggedInUserId() async {
    final user = _supabase.auth.currentUser;
    if (user != null && user.id.isNotEmpty) {
      return user.id;
    }
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      return firebaseUser.uid;
    }
    return await _resolveCurrentUserId();
  }

  Future<String?> _resolveCurrentUserId() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty)
      return _currentUserId;

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      _currentUserId = firebaseUser.uid;
      return _currentUserId;
    }

    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser != null && supabaseUser.id.isNotEmpty) {
      _currentUserId = supabaseUser.id;
      return _currentUserId;
    }

    final rememberedId = await _keyStorage.readValue(
      AppConstants.lastLoggedInUserIdKey,
    );
    if (rememberedId != null && rememberedId.isNotEmpty) {
      _currentUserId = rememberedId;
      return _currentUserId;
    }

    final rememberedEmail = await _keyStorage.readValue('last_logged_in_user');
    if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
      _currentUserId = rememberedEmail;
      return _currentUserId;
    }

    return null;
  }

  Future<String?> _getCurrentUserId() async {
    return await _resolveCurrentUserId();
  }

  String _biometricKeyForUser(String userId) {
    return '${AppConstants.biometricEnabledKey}_$userId';
  }

  Future<bool> getBiometricEnabledForCurrentAccount() async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) return false;
    final key = _biometricKeyForUser(userId);
    final value = await _keyStorage.readValue(key);
    return value == 'true';
  }

  Future<bool> isBiometricEnabled() async {
    return getBiometricEnabledForCurrentAccount();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      _authError = 'No user found for biometric setting.';
      notifyListeners();
      return;
    }

    final key = _biometricKeyForUser(userId);
    await _keyStorage.saveValue(key, enabled ? 'true' : 'false');
    notifyListeners();
  }

  Future<bool> enableBiometricSetup() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();
    if (!canCheckBiometrics || !isDeviceSupported) {
      _authError = 'Biometric setup not available on this device.';
      notifyListeners();
      return false;
    }

    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometrics for CipherTask',
        biometricOnly: true,
      );
      if (authenticated) {
        await setBiometricEnabled(true);
        _authError = null;
        notifyListeners();
        return true;
      }
      _authError = 'Biometric setup was cancelled or failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Biometric setup error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, String>> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    final email = await getLoggedInUserEmail() ?? '';

    String firstName = '';
    String lastName = '';
    if (user != null) {
      firstName = user.userMetadata?['first_name']?.toString() ?? '';
      lastName = user.userMetadata?['last_name']?.toString() ?? '';
    }

    if (firstName.isEmpty) {
      firstName =
          await _keyStorage.readValue(AppConstants.profileFirstNameKey) ?? '';
    }
    if (lastName.isEmpty) {
      lastName =
          await _keyStorage.readValue(AppConstants.profileLastNameKey) ?? '';
    }

    final bio = await _keyStorage.readValue(AppConstants.profileBioKey) ?? '';

    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
    };
  }

  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    required String bio,
  }) async {
    await _keyStorage.saveValue(AppConstants.profileFirstNameKey, firstName);
    await _keyStorage.saveValue(AppConstants.profileLastNameKey, lastName);
    await _keyStorage.saveValue(AppConstants.profileBioKey, bio);

    // Persist in Supabase user metadata too, if available.
    try {
      // Update Firebase display name if using Firebase auth flow.
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final newDisplayName = [
          firstName,
          lastName,
        ].where((it) => it.isNotEmpty).join(' ');
        if (newDisplayName.isNotEmpty) {
          await user.updateDisplayName(newDisplayName);
          await user.reload();
        }
      }
    } catch (e) {
      debugPrint('Firebase profile update failed: $e');
    }

    try {
      await _supabase.auth.updateUser(
        supabase.UserAttributes(
          data: {'first_name': firstName, 'last_name': lastName, 'bio': bio},
        ),
      );
    } catch (e) {
      debugPrint('Supabase profile metadata update failed: $e');
      // still continue - local storage remains valid
    }

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // ignore
    }

    _isLoggedIn = false;
    _currentUserId = null;
    // keep last_logged_in_user and has_logged_in_once so biometric indirect state persists
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

  Future<String?> getRememberedEmail() async =>
      await _keyStorage.readValue('remembered_email');
}
