import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _userBoxName = 'user_data';
  static const String _settingsBoxName = 'app_settings';
  
  Box? _userBox;
  Box? _settingsBox;

  Future<void> initialize() async {
    try {
      // Only initialize if not already initialized
      if (_userBox == null || !_userBox!.isOpen) {
        _userBox = await Hive.openBox(_userBoxName);
      }
      if (_settingsBox == null || !_settingsBox!.isOpen) {
        _settingsBox = await Hive.openBox(_settingsBoxName);
      }
      print('Storage service initialized successfully');
    } catch (e) {
      print('Storage initialization error: $e');
      rethrow;
    }
  }

  // User Data Methods
  Future<void> saveUserData(String key, dynamic value) async {
    try {
      await _userBox?.put(key, value);
      print('Saved to storage - Key: $key, Value type: ${value.runtimeType}');
      
      // Verify the data was saved
      final savedData = _userBox?.get(key);
      print('Verification - Retrieved: ${savedData != null ? 'SUCCESS' : 'FAILED'}');
    } catch (e) {
      print('Error saving user data for key $key: $e');
      rethrow;
    }
  }

  dynamic getUserData(String key) {
    try {
      final data = _userBox?.get(key);
      print('Retrieved from storage - Key: $key, Found: ${data != null}');
      return data;
    } catch (e) {
      print('Error getting user data for key $key: $e');
      return null;
    }
  }

  Future<void> removeUserData(String key) async {
    await _userBox?.delete(key);
  }

  Future<void> clearUserData() async {
    await _userBox?.clear();
  }

  // Settings Methods
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  dynamic getSetting(String key) {
    return _settingsBox?.get(key);
  }

  Future<void> removeSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  // Auth Token Methods
  Future<void> saveAuthToken(String token) async {
    await saveUserData('auth_token', token);
  }

  String? getAuthToken() {
    return getUserData('auth_token');
  }

  Future<void> removeAuthToken() async {
    await removeUserData('auth_token');
  }

  // User Profile Methods
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await saveUserData('user_profile', profile);
  }

  Map<String, dynamic>? getUserProfile() {
    final data = getUserData('user_profile');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> removeUserProfile() async {
    await removeUserData('user_profile');
  }
}
