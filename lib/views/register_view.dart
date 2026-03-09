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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Password validation regex: at least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Verification code resent!' 
            : (auth.authError ?? 'Failed to resend code.')),
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

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
          ),
          child: SafeArea(
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

                      // Plain logo circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'CIPHERTASK',
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (!_showOtpField) ...[
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.2),
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
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter a strong password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _passwordController.text.isNotEmpty
                                          ? (_isPasswordValid()
                                              ? Colors.green.withValues(alpha: 0.5)
                                              : Colors.red.withValues(alpha: 0.5))
                                          : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isPasswordValid()
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.2),
                                ),
                                validator: _validatePassword,
                                onChanged: (value) {
                                  setState(() {}); // Trigger rebuild for live validation
                                },
                              ),
                              const SizedBox(height: 8),
                              // Password strength indicator
                              if (_passwordController.text.isNotEmpty && !_isPasswordValid()) ...[
                                Row(
                                  children: [
                                    Icon(
                                      _passwordController.text.length >= 8
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _passwordController.text.length >= 8
                                          ? Colors.green
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'At least 8 characters',
                                      style: TextStyle(
                                        color: _passwordController.text.length >= 8
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
                                      RegExp(r'[A-Z]').hasMatch(_passwordController.text)
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: RegExp(r'[A-Z]').hasMatch(_passwordController.text)
                                          ? Colors.green
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'One uppercase letter',
                                      style: TextStyle(
                                        color: RegExp(r'[A-Z]').hasMatch(_passwordController.text)
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
                                      RegExp(r'[a-z]').hasMatch(_passwordController.text)
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: RegExp(r'[a-z]').hasMatch(_passwordController.text)
                                          ? Colors.green
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'One lowercase letter',
                                      style: TextStyle(
                                        color: RegExp(r'[a-z]').hasMatch(_passwordController.text)
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
                                      RegExp(r'\d').hasMatch(_passwordController.text)
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: RegExp(r'\d').hasMatch(_passwordController.text)
                                          ? Colors.green
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'One number',
                                      style: TextStyle(
                                        color: RegExp(r'\d').hasMatch(_passwordController.text)
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
                                      RegExp(r'[@$!%*?&]').hasMatch(_passwordController.text)
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: RegExp(r'[@$!%*?&]').hasMatch(_passwordController.text)
                                          ? Colors.green
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'One special character (@\$!%*?&)',
                                      style: TextStyle(
                                        color: RegExp(r'[@$!%*?&]').hasMatch(_passwordController.text)
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
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Re-enter your password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _confirmPasswordController.text.isNotEmpty
                                          ? (_doPasswordsMatch()
                                              ? Colors.green.withValues(alpha: 0.5)
                                              : Colors.red.withValues(alpha: 0.5))
                                          : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _doPasswordsMatch()
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.2),
                                ),
                                validator: _validateConfirmPassword,
                                onChanged: (value) {
                                  setState(() {}); // Trigger rebuild for live validation
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A1A2E),
                                    disabledForegroundColor: Colors.white70,
                                    disabledBackgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Send Verification Code'),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Enter the verification code sent to \n${_emailController.text}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: 4,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Verification Code',
                                  hintText: '********',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  counterStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: Icon(
                                    Icons.confirmation_num_outlined,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.2),
                                ),
                                onChanged: (v) {
                                  // Auto-submit removed to prevent premature validation errors
                                  // for variable length codes (6-8 digits).
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          if (_otpController.text.length < 6) {
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A1A2E),
                                    disabledForegroundColor: Colors.white70,
                                    disabledBackgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Register'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isResendingOtp ? null : () => _resendOtp(auth),
                                    child: _isResendingOtp 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text(
                                          'Resend Code',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
        ),
      ),
    );
  }
}
