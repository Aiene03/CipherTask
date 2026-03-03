import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class KeyStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getOrCreateDatabaseKey(String keyName) async {
    String? key = await _storage.read(key: keyName);
    if (key == null) {
      key = _generateSecureKey();
      await _storage.write(key: keyName, value: key);
    }
    return key;
  }

  Future<void> saveValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readValue(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }

  String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
