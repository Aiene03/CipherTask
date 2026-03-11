import 'package:flutter/material.dart';
import '../services/key_storage_service.dart';

class ThemeViewModel extends ChangeNotifier {
  final KeyStorageService _keyStorage;
  static const String _themeKey = 'selected_theme_mode';

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  ThemeViewModel(this._keyStorage) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadThemeMode() async {
    final value = await _keyStorage.readValue(_themeKey);
    if (value != null) {
      _isDarkMode = value == 'dark';
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _keyStorage.saveValue(_themeKey, value ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}
