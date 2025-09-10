import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasswordStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Salvează parola pentru un email specific
  static Future<void> savePassword(String email, String password) async {
    try {
      await _storage.write(
        key: 'saved_password_$email',
        value: password,
      );
      print('✅ Password saved securely for: $email');
    } catch (e) {
      print('❌ Error saving password: $e');
    }
  }

  /// Returnează parola salvată pentru un email specific
  static Future<String?> getPassword(String email) async {
    try {
      final password = await _storage.read(key: 'saved_password_$email');
      if (password != null) {
        print('✅ Password retrieved for: $email');
      }
      return password;
    } catch (e) {
      print('❌ Error retrieving password: $e');
      return null;
    }
  }

  /// Șterge parola salvată pentru un email specific
  static Future<void> deletePassword(String email) async {
    try {
      await _storage.delete(key: 'saved_password_$email');
      print('✅ Password deleted for: $email');
    } catch (e) {
      print('❌ Error deleting password: $e');
    }
  }

  /// Verifică dacă există o parolă salvată pentru un email
  static Future<bool> hasPassword(String email) async {
    try {
      final password = await _storage.read(key: 'saved_password_$email');
      return password != null;
    } catch (e) {
      print('❌ Error checking password: $e');
      return false;
    }
  }

  /// Șterge toate parolele salvate (la logout)
  static Future<void> clearAllPasswords() async {
    try {
      await _storage.deleteAll();
      print('✅ All saved passwords cleared');
    } catch (e) {
      print('❌ Error clearing passwords: $e');
    }
  }
} 