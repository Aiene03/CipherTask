import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  late encrypt.Key _key;
  late encrypt.IV _iv;

  EncryptionService(String base64Key) {
    _key = encrypt.Key.fromBase64(base64Key);
    // In a real app, you should use a unique IV for each encryption and store it.
    // For this lab, we'll use a deterministic IV derived from the key for simplicity.
    _iv = encrypt.IV.fromLength(16);
  }

  String encryptText(String text) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedBase64) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      return "Error decrypting note";
    }
  }
}
