import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _showOtpField = false;
  bool _isSendingOtp = false;
  bool _isLoading = false;
  bool _isResendingOtp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _otpTimerSeconds = 0;
  bool _isOtpExpired = false;
  Timer? _otpTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Password validation regex: at least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
  final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _isPasswordValid() {
    return _passwordRegex.hasMatch(_passwordController.text);
  }

  bool _doPasswordsMatch() {
    return _confirmPasswordController.text == _passwordController.text &&
        _confirmPasswordController.text.isNotEmpty;
  }

  InputDecoration _getInputDecoration({
    required String label,
    required IconData icon,
    required bool isDarkMode,
    Widget? suffixIcon,
  }) {
    final labelColor = isDarkMode ? Colors.white70 : const Color(0xFF475569);
    final borderColor = isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0);
    final fillColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF1F5F9);
    final focusedColor = isDarkMode
        ? Colors.cyanAccent
        : const Color(0xFF0E62DD);
    final iconColor = isDarkMode
        ? Colors.cyanAccent.withOpacity(0.7)
        : const Color(0xFF0E62DD);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor, fontSize: 14),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _otpTimerSeconds = 120;
      _isOtpExpired = false;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_otpTimerSeconds <= 1) {
        timer.cancel();
        setState(() {
          _otpTimerSeconds = 0;
          _isOtpExpired = true;
        });
      } else {
        setState(() => _otpTimerSeconds -= 1);
      }
    });
  }

  Future<void> _sendOtp(AuthViewModel auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingOtp = true;
    });

    final result = await auth.sendOtp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    if (result['status'] == 'logged_in') {
      Navigator.of(context).pushNamedAndRemoveUntil('/todos', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to CipherTask.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result['status'] == 'otp_sent') {
      setState(() {
        _showOtpField = true;
      });
      _startOtpTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A verification code has been sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.authError ?? 'Failed to send verification code.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp(AuthViewModel auth) async {
    setState(() {
      _isResendingOtp = true;
    });
    bool success = await auth.resendOtp(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _isResendingOtp = false;
      });
      if (success) {
        _startOtpTimer();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Verification code resent!'
                : (auth.authError ?? 'Failed to resend code.'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _register(AuthViewModel auth) async {
    setState(() {
      _isLoading = true;
    });
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    bool success = await auth.verifyRegistrationOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    if (success && mounted) {
      navigator.pushNamedAndRemoveUntil('/todos', (route) => false);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to CipherTask.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(auth.authError ?? 'Invalid code or session expired.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? const [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ]
                  : const [
                      Color(0xFFF0F4FB),
                      Color(0xFFE0E8F4),
                      Color(0xFFD0DFF0),
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -60,
                child: CircleAvatar(
                  radius: 150,
                  backgroundColor: Colors.cyanAccent.withOpacity(0.03),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),

                          // Branding circle (matching Login style)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.2),
                              ),
                              color: Colors.white.withOpacity(0.04),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'CIPHERTASK',
                            style: GoogleFonts.orbitron(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Secure task manager, one click away',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Create your account',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 2,
                              color: isDarkMode
                                  ? Colors.cyanAccent.withOpacity(0.75)
                                  : const Color(0xFF0F172A).withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.16),
                                  ),
                                  boxShadow: isDarkMode
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.blueGrey.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  children: [
                                    if (!_showOtpField) ...[
                                      TextFormField(
                                        controller: _emailController,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: _getInputDecoration(
                                          label: 'Email Address',
                                          icon: Icons.email_outlined,
                                          isDarkMode: isDarkMode,
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Please enter email';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(v)) {
                                            return 'Invalid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                        decoration: _getInputDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline,
                                          isDarkMode: isDarkMode,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: isDarkMode
                                                  ? Colors.white.withOpacity(
                                                      0.4,
                                                    )
                                                  : Colors.blueGrey.withOpacity(
                                                      0.8,
                                                    ),
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: _validatePassword,
                                        onChanged: (value) {
                                          setState(
                                            () {},
                                          ); // Trigger rebuild for live validation
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // Password strength indicator
                                      if (_passwordController.text.isNotEmpty &&
                                          !_isPasswordValid()) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              _passwordController.text.length >=
                                                      8
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  _passwordController
                                                          .text
                                                          .length >=
                                                      8
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'At least 8 characters',
                                              style: TextStyle(
                                                color:
                                                    _passwordController
                                                            .text
                                                            .length >=
                                                        8
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              RegExp(r'[A-Z]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  RegExp(r'[A-Z]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'One uppercase letter',
                                              style: TextStyle(
                                                color:
                                                    RegExp(r'[A-Z]').hasMatch(
                                                      _passwordController.text,
                                                    )
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              RegExp(r'[a-z]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  RegExp(r'[a-z]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'One lowercase letter',
                                              style: TextStyle(
                                                color:
                                                    RegExp(r'[a-z]').hasMatch(
                                                      _passwordController.text,
                                                    )
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              RegExp(r'\d').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  RegExp(r'\d').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'One number',
                                              style: TextStyle(
                                                color:
                                                    RegExp(r'\d').hasMatch(
                                                      _passwordController.text,
                                                    )
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              RegExp(r'[@$!%*?&]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  RegExp(r'[@$!%*?&]').hasMatch(
                                                    _passwordController.text,
                                                  )
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'One special character (@\$!%*?&)',
                                              style: TextStyle(
                                                color:
                                                    RegExp(
                                                      r'[@$!%*?&]',
                                                    ).hasMatch(
                                                      _passwordController.text,
                                                    )
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                        decoration: _getInputDecoration(
                                          label: 'Confirm Password',
                                          icon: Icons.lock_outline,
                                          isDarkMode: isDarkMode,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: isDarkMode
                                                  ? Colors.white.withOpacity(
                                                      0.4,
                                                    )
                                                  : Colors.blueGrey.withOpacity(
                                                      0.8,
                                                    ),
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: _validateConfirmPassword,
                                        onChanged: (value) {
                                          setState(
                                            () {},
                                          ); // Trigger rebuild for live validation
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isSendingOtp || _isLoading
                                              ? null
                                              : () => _sendOtp(auth),
                                          style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.cyanAccent,
                                                foregroundColor: const Color(
                                                  0xFF0F172A,
                                                ),
                                                disabledForegroundColor:
                                                    Colors.white70,
                                                disabledBackgroundColor:
                                                    Colors.white10,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ).copyWith(
                                                overlayColor:
                                                    MaterialStateProperty.all(
                                                      Colors.white.withOpacity(
                                                        0.2,
                                                      ),
                                                    ),
                                              ),
                                          child: _isSendingOtp
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  'Send Verification Code',
                                                ),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Enter the verification code sent to \n${_emailController.text}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : const Color(
                                                  0xFF0F172A,
                                                ).withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TextFormField(
                                        controller: _otpController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 8,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                          fontSize: 24,
                                          letterSpacing: 4,
                                        ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          labelText: 'Verification Code',
                                          hintText: '********',
                                          hintStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white.withOpacity(0.3)
                                                : const Color(
                                                    0xFF64748B,
                                                  ).withOpacity(0.6),
                                          ),
                                          labelStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : const Color(0xFF64748B),
                                          ),
                                          counterStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : const Color(0xFF64748B),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.confirmation_num_outlined,
                                            color: isDarkMode
                                                ? Colors.white54
                                                : const Color(
                                                    0xFF0F172A,
                                                  ).withOpacity(0.65),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: isDarkMode
                                                  ? Colors.white.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.blue.shade200,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: isDarkMode
                                              ? Colors.black.withOpacity(0.2)
                                              : Colors.blue.shade50,
                                        ),
                                        onChanged: (v) {
                                          // Auto-submit removed to prevent premature validation errors
                                          // for variable length codes (6-8 digits).
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      if (_otpTimerSeconds > 0) ...[
                                        Text(
                                          'Code valid for: ${(_otpTimerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_otpTimerSeconds % 60).toString().padLeft(2, '0')}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ] else ...[
                                        Text(
                                          'Code has expired. Please resend to continue.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _isOtpExpired
                                              ? null
                                              : () {
                                                  if (_otpController
                                                          .text
                                                          .length <
                                                      6) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Enter a valid verification code',
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    _register(auth);
                                                  }
                                                },
                                          style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor: _isOtpExpired
                                                    ? Colors.grey
                                                    : Colors.cyanAccent,
                                                foregroundColor: const Color(
                                                  0xFF0F172A,
                                                ),
                                                disabledForegroundColor:
                                                    Colors.white70,
                                                disabledBackgroundColor:
                                                    Colors.white10,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ).copyWith(
                                                overlayColor:
                                                    MaterialStateProperty.all(
                                                      Colors.white.withOpacity(
                                                        0.2,
                                                      ),
                                                    ),
                                              ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  _isOtpExpired
                                                      ? 'Code expired'
                                                      : 'Register',
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showOtpField = false;
                                                _otpController.clear();
                                              });
                                            },
                                            child: const Text(
                                              'Change Email',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                (_isResendingOtp ||
                                                    !_isOtpExpired)
                                                ? null
                                                : () => _resendOtp(auth),
                                            child: _isResendingOtp
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Resend Code',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
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
}
