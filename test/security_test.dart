import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_task/services/encryption_service.dart';
import 'package:cipher_task/models/todo_model.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  group('Security & Model Tests', () {
    // Generate a valid 32-byte base64 key for testing
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final testKey = base64Url.encode(values);
    
    final encryptionService = EncryptionService(testKey);

    test('AES-256 Encryption/Decryption should match original text', () {
      const originalText = "Sensitive Executive Note 123";
      
      final encrypted = encryptionService.encryptText(originalText);
      final decrypted = encryptionService.decryptText(encrypted);
      
      expect(encrypted, isNot(originalText));
      expect(decrypted, originalText);
      print('Encryption Test Passed: $originalText -> $encrypted -> $decrypted');
    });

    test('TodoModel toMap and fromMap should preserve data integrity', () {
      final todo = TodoModel(
        id: 1,
        title: "Test Task",
        encryptedSecretNotes: "EncryptedData",
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      final map = todo.toMap();
      final fromMap = TodoModel.fromMap(map);

      expect(fromMap.id, todo.id);
      expect(fromMap.title, todo.title);
      expect(fromMap.isCompleted, true);
      print('Model Integrity Test Passed');
    });
  });
}
