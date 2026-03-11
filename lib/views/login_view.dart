import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/transitions.dart';
import 'register_view.dart';
import 'todo_list_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricEnabled = false;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final enabled = await authViewModel.isBiometricEnabled();
      if (mounted) setState(() => _isBiometricEnabled = enabled);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    try {
      bool success = await authViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final enabled = await authViewModel.isBiometricEnabled();
        setState(() => _isBiometricEnabled = enabled);

        Navigator.pushReplacement(
          context,
          FadePageTransition(child: const TodoListView()),
        );
      } else if (mounted) {
        _showSnackBar(
          authViewModel.authError ??
              'Login failed. Please check your credentials.',
          const Color(0xFFEF4444), // Soft professional red
        );
      }
    } catch (e) {
      if (mounted)
        _showSnackBar('An error occurred: $e', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _getInputDecoration({
    required String label,
    required IconData icon,
    required bool isDarkMode,
    Widget? suffixIcon,
  }) {
    // Colors derived from the image's layout but translated to a "Light Cyber" theme
    final textColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFFE2E8F0);
    final fillColor = isDarkMode
        ? const Color(0xFF1E293B).withOpacity(0.4)
        : const Color(0xFFF8FAFC);
    final focusedColor = isDarkMode
        ? const Color(0xFF00F2FF) // The bright cyan from the image
        : const Color(0xFF0EA5E9); // A bright professional blue for light mode
    final iconColor = isDarkMode
        ? const Color(0xFF00F2FF).withOpacity(0.8)
        : const Color(0xFF64748B);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focusedColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? const [Color(0xFF0F172A), Color(0xFF020617)]
                  : const [
                      Color(0xFFF1F5F9), // Light slate gray background
                      Color(0xFFFFFFFF),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle background circle from the image
              Positioned(
                top: -120,
                left: -20,
                child: CircleAvatar(
                  radius: 180,
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E293B).withOpacity(0.1)
                      : const Color(0xFF0EA5E9).withOpacity(0.03),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Branding as seen in the image
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDarkMode
                                      ? const Color(0xFF1E293B)
                                      : const Color(
                                          0xFF1E293B,
                                        ), // Keeping the dark icon container for brand contrast
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'CIPHERTASK',
                                style: GoogleFonts.orbitron(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'SECURE AUTHENTICATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 2,
                                  color: isDarkMode
                                      ? const Color(0xFF00F2FF).withOpacity(0.7)
                                      : const Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          _buildLockoutBanner(),

                          // Form Container (Similar to the card in the image)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: isDarkMode
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _getInputDecoration(
                                      label: 'Email Address',
                                      icon: Icons.mail_outline_rounded,
                                      isDarkMode: isDarkMode,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Email required';
                                      if (!_emailRegex.hasMatch(value.trim()))
                                        return 'Invalid format';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    decoration: _getInputDecoration(
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      isDarkMode: isDarkMode,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.grey.withOpacity(0.6),
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                        ? 'Password required'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDarkMode
                                            ? const Color(0xFF00F2FF)
                                            : const Color(0xFF00F2FF),
                                        foregroundColor: const Color(
                                          0xFF0F172A,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Color(0xFF0F172A),
                                              ),
                                            )
                                          : const Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildSocialSignInButtons(),
                          const SizedBox(height: 20),
                          _buildBiometricButton(),
                          const SizedBox(height: 48),
                          _buildRegisterLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockoutBanner() {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        if (!authVM.isLockedOut) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'System Locked: ${authVM.getRemainingLockoutTime()}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialSignInButtons() {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        return _socialButton(
          'Google',
          Icons.g_mobiledata_rounded,
          const Color(0xFFEA4335),
          () async {
            setState(() => _isLoading = true);
            final success = await authVM.signInWithGoogle();
            setState(() => _isLoading = false);
            if (success && mounted) {
              Navigator.pushReplacement(
                context,
                FadePageTransition(child: const TodoListView()),
              );
            } else if (mounted) {
              _showSnackBar(
                authVM.authError ?? 'Sign-In failed.',
                const Color(0xFFEF4444),
              );
            }
          },
        );
      },
    );
  }

  Widget _socialButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDarkMode
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final enabled = _isBiometricEnabled;
    final accentColor = isDarkMode
        ? const Color(0xFF00F2FF)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: enabled
          ? _handleBiometricLogin
          : () => _showSnackBar(
              'Biometrics disabled. Check Profile.',
              const Color(0xFFF59E0B),
            ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? accentColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              color: enabled ? accentColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              enabled ? 'USE BIOMETRIC AUTH' : 'ENABLE BIOS IN PROFILE',
              style: GoogleFonts.orbitron(
                color: enabled ? accentColor : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(FadePageTransition(child: const RegisterView())),
          child: Text(
            'REGISTER NOW',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF00F2FF)
                  : const Color(0xFF0EA5E9),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    try {
      bool success = await authViewModel.authenticateWithBiometrics();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          FadePageTransition(child: const TodoListView()),
        );
      } else if (mounted) {
        _showSnackBar(
          authViewModel.authError ?? 'Biometric login failed.',
          const Color(0xFFEF4444),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
