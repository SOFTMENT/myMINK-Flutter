import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  // Generate Encryption Key function using PBKDF2
  String generateEncryptionKey(String password) {
    final salt = utf8.encode('random_salt'); // Use a secure random salt
    final keyBytes =
        _pbkdf2(password, Uint8List.fromList(salt), 10000, 32); // 32-byte key
    return base64Encode(keyBytes);
  }

  // PBKDF2 function to derive a key
  Uint8List _pbkdf2(
      String password, Uint8List salt, int iterations, int keyLength) {
    final key = utf8.encode(password);
    final hmac = Hmac(sha256, key); // HMAC with SHA-256
    Uint8List output = Uint8List(keyLength);
    Uint8List block = Uint8List.fromList(salt + [1]);

    for (int i = 0; i < iterations; i++) {
      block = Uint8List.fromList(hmac.convert(block).bytes);
      for (int j = 0; j < output.length; j++) {
        output[j] ^= block[j];
      }
    }
    return output;
  }

  // Encrypt message function with IV handling
  String encryptMessage(String message, String encryptionKey) {
    final key = encrypt.Key.fromBase64(encryptionKey);
    final iv = encrypt.IV.fromLength(16); // Generate a random 16-byte IV

    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    final encrypted = encrypter.encrypt(message, iv: iv);

    // Combine IV and encrypted data and return as base64
    return base64Encode(iv.bytes + encrypted.bytes);
  }

  // Decrypt message function with IV extraction
  String? decryptMessage(String encryptedMessage, String encryptionKey) {
    try {
      final key = encrypt.Key.fromBase64(encryptionKey);
      final encryptedData = base64Decode(encryptedMessage);

      // Extract IV and encrypted data
      final iv =
          encrypt.IV(encryptedData.sublist(0, 16)); // First 16 bytes are the IV
      final encryptedBytes =
          encryptedData.sublist(16); // The rest are the encrypted message

      final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
      final decrypted =
          encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
      return decrypted;
    } catch (e) {
      return null;
    }
  }
}
