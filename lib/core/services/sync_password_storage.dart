import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eduportfolio/core/utils/logger.dart';

/// Service for securely storing and retrieving sync server password
///
/// Uses flutter_secure_storage to encrypt password on device.
class SyncPasswordStorage {
  static const String _passwordKey = 'sync_server_password';

  final FlutterSecureStorage _storage;

  SyncPasswordStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save server password securely
  ///
  /// Returns true if saved successfully, false otherwise.
  Future<bool> savePassword(String password) async {
    try {
      await _storage.write(key: _passwordKey, value: password);
      Logger.info('Server password saved securely');
      return true;
    } catch (e) {
      Logger.error('Error saving server password', e);
      return false;
    }
  }

  /// Get stored server password
  ///
  /// Returns password if found, null otherwise.
  Future<String?> getPassword() async {
    try {
      final password = await _storage.read(key: _passwordKey);
      if (password != null) {
        Logger.info('Server password retrieved');
      } else {
        Logger.info('No server password found');
      }
      return password;
    } catch (e) {
      Logger.error('Error reading server password', e);
      return null;
    }
  }

  /// Delete stored server password
  ///
  /// Returns true if deleted successfully, false otherwise.
  Future<bool> deletePassword() async {
    try {
      await _storage.delete(key: _passwordKey);
      Logger.info('Server password deleted');
      return true;
    } catch (e) {
      Logger.error('Error deleting server password', e);
      return false;
    }
  }

  /// Check if password is stored
  ///
  /// Returns true if password exists, false otherwise.
  Future<bool> hasPassword() async {
    try {
      final password = await _storage.read(key: _passwordKey);
      return password != null && password.isNotEmpty;
    } catch (e) {
      Logger.error('Error checking for password', e);
      return false;
    }
  }

  /// Clear all stored data
  ///
  /// Use with caution - this deletes ALL secure storage data.
  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      Logger.warning('All secure storage cleared');
      return true;
    } catch (e) {
      Logger.error('Error clearing secure storage', e);
      return false;
    }
  }
}
