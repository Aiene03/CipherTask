class UserModel {
  final String email;
  final bool isBiometricEnabled;

  UserModel({
    required this.email,
    this.isBiometricEnabled = false,
  });
}
