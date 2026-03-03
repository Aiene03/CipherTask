import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showOtpField = false;
  bool _isSendingOtp = false;
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_showOtpField) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSendingOtp ? null : () async {
                  if (_emailController.text.contains('@')) {
                    setState(() => _isSendingOtp = true);
                    bool sent = await authViewModel.sendOtp(_emailController.text);
                    setState(() => _isSendingOtp = false);
                    if (sent) {
                      setState(() => _showOtpField = true);
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send OTP')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
                  }
                },
                child: _isSendingOtp ? const CircularProgressIndicator() : const Text('Send Verification Code'),
              ),
            ] else ...[
              const Text('MFA Verification: Enter 6-digit OTP sent to your email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  bool isValid = authViewModel.verifyOtp(_otpController.text);
                  if (isValid) {
                    bool success = await authViewModel.register(_emailController.text, _passwordController.text);
                    if (success && mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Registration successful! Please login.')));
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Invalid OTP. Check your email.')));
                  }
                },
                child: const Text('Register'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
