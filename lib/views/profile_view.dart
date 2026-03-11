import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false; // Controls if fields are editable
  bool _biometricEnabled = false;

  // Colors - Friendly Cyber Theme
  final Color primaryCyan = const Color(0xFF2CC6D7);
  final Color electricBlue = const Color(0xFF00D2FF);
  final Color deepNavy = const Color(0xFF0D1117);
  final Color cardBackground = const Color(0xFF161B22);
  final Color errorRed = const Color(0xFFFF5252);

  // Light Mode Variants
  final Color lightBackground = const Color(0xFFF8FAFC);
  final Color lightCard = Colors.white;
  final Color lightText = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuad),
        );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final email = await authViewModel.getLoggedInUserEmail();
    final profile = await authViewModel.getUserProfile();

    final biometricEnabled = await authViewModel.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _email = email ?? 'user@ciphertask.com';
        _firstNameController.text = profile['firstName'] ?? '';
        _lastNameController.text = profile['lastName'] ?? '';
        _biometricEnabled = biometricEnabled;
        _isLoading = false;
      });
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(bool isDarkMode) async {
    final Color bgColor = isDarkMode ? cardBackground : lightCard;
    final Color textColor = isDarkMode ? Colors.white : lightText;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your secure session?',
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white70 : lightText.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.saveUserProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        bio: "",
      );
      if (mounted) {
        setState(() {
          _isEditMode = false; // Exit edit mode on success
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryCyan,
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: errorRed,
            content: Text(
              'Error updating profile: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);
    final isDarkMode = themeViewModel.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? deepNavy : lightBackground,
      appBar: _buildAppBar(isDarkMode),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryCyan))
          : Stack(
              children: [
                if (!isDarkMode)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE5F4FF), Color(0xFFF8FAFC)],
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildAvatarSection(isDarkMode),
                          const SizedBox(height: 40),
                          _buildThemeToggle(
                            isDarkMode,
                            themeViewModel,
                          ), // Theme Toggle Section
                          const SizedBox(height: 32),
                          _buildProfileForm(),
                          if (_isEditMode) ...[
                            const SizedBox(height: 40),
                            _buildSaveButton(),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : lightText;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'My Profile',
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout_rounded, color: errorRed.withOpacity(0.8)),
          tooltip: 'Logout',
          onPressed: () => _handleLogout(isDarkMode),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatarSection(bool isDarkMode) {
    String fullName = "${_firstNameController.text} ${_lastNameController.text}"
        .trim();
    if (fullName.isEmpty) fullName = "New User";

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.08).animate(_pulseController),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryCyan.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryCyan, electricBlue],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryCyan.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isEditMode
                        ? primaryCyan
                        : (isDarkMode ? cardBackground : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? deepNavy : lightBackground,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isEditMode ? Icons.close_rounded : Icons.edit_rounded,
                    color: _isEditMode ? Colors.black87 : primaryCyan,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          fullName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : lightText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email.isNotEmpty ? _email : 'no-email@ciphertask.com',
          style: GoogleFonts.inter(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        // Removed account ID display per request
        const SizedBox(height: 0),
      ],
    );
  }

  Widget _buildThemeToggle(bool isDarkMode, ThemeViewModel themeViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PREFERENCES'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : lightText,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isDarkMode
                          ? 'Conserve battery & reduce eye strain'
                          : 'Bright interface for high visibility',
                      style: GoogleFonts.inter(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.38)
                            : Colors.black.withOpacity(0.38),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDarkMode,
                activeColor: primaryCyan,
                onChanged: (value) {
                  themeViewModel.setDarkMode(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildBiometricToggle(isDarkMode),
      ],
    );
  }

  Widget _buildBiometricToggle(bool isDarkMode) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric login',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : lightText,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _biometricEnabled
                      ? 'Enabled. Use fingerprint to sign in.'
                      : 'Disabled. Enable to use biometrics at login.',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _biometricEnabled,
            activeColor: primaryCyan,
            onChanged: (value) async {
              if (value) {
                bool setupSuccess = await authViewModel.enableBiometricSetup();
                if (mounted) {
                  setState(() {
                    _biometricEnabled = setupSuccess;
                  });
                }
                if (!setupSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authViewModel.authError ??
                            'Failed to enable biometric login',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                await authViewModel.setBiometricEnabled(false);
                if (mounted) {
                  setState(() {
                    _biometricEnabled = false;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('IDENTITY DETAILS'),
          _buildModernField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline_rounded,
            enabled: _isEditMode,
          ),
          const SizedBox(height: 16),
          _buildModernField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline_rounded,
            enabled: _isEditMode,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            value: _email,
            label: 'Email Address',
            icon: Icons.email_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primaryCyan.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.02))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? primaryCyan.withOpacity(0.2)
              : (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.inter(
          color: isDark
              ? (enabled ? Colors.white : Colors.white.withOpacity(0.6))
              : (enabled ? lightText : Colors.black.withOpacity(0.54)),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: isDark
                ? Colors.white.withOpacity(0.38)
                : Colors.black.withOpacity(0.38),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? primaryCyan : primaryCyan.withOpacity(0.3),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          floatingLabelStyle: TextStyle(
            color: enabled
                ? primaryCyan
                : (isDark
                      ? Colors.white.withOpacity(0.38)
                      : Colors.black.withOpacity(0.38)),
          ),
        ),
        onChanged: (_) => setState(() {}), // Refresh full name display
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.03),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? Colors.white.withOpacity(0.24)
                : Colors.black.withOpacity(0.24),
            size: 22,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withOpacity(0.24)
                      : Colors.black.withOpacity(0.26),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withOpacity(0.54)
                      : Colors.black.withOpacity(0.54),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.black87,
          elevation: 8,
          shadowColor: primaryCyan.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'SAVE CHANGES',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  String _getInitials() {
    String first = _firstNameController.text.isNotEmpty
        ? _firstNameController.text[0].toUpperCase()
        : '';
    String last = _lastNameController.text.isNotEmpty
        ? _lastNameController.text[0].toUpperCase()
        : '';
    return (first + last).isEmpty ? '?' : first + last;
  }
}
