import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_service.dart';
import '../providers/auth_provider.dart';

class SecurityService {
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _sessionTimeoutKey = 'session_timeout'; // in minutes
  static const String _passcodeKey = 'user_passcode';
  
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  SecurityService._();

  // Security settings getters
  Future<bool> get isAppLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<int> get sessionTimeout async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionTimeoutKey) ?? 5; // Default 5 minutes
  }

  Future<DateTime?> get lastAuthTime async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastAuthTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<String?> get userPasscode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passcodeKey);
  }

  Future<bool> get hasPasscodeSet async {
    final passcode = await userPasscode;
    return passcode != null && passcode.isNotEmpty;
  }

  // Security settings setters
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  Future<void> setSessionTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionTimeoutKey, minutes);
  }

  Future<void> updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAuthTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> setUserPasscode(String passcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passcodeKey, passcode);
  }

  Future<bool> verifyPasscode(String passcode) async {
    final storedPasscode = await userPasscode;
    return storedPasscode == passcode;
  }

  // Update passcode via API and local storage
  Future<Map<String, dynamic>> updatePasscodeViaApi(String oldPasscode, String newPasscode) async {
    try {
      // First verify the old passcode locally
      final isOldPasscodeValid = await verifyPasscode(oldPasscode);
      if (!isOldPasscodeValid) {
        return {
          'success': false,
          'message': 'Current passcode is incorrect',
        };
      }

      // Get user credentials from AuthProvider
      final authProvider = AuthProvider();
      await authProvider.initialize();
      
      final email = await authProvider.getApiUserEmail();
      final tokenCode = await authProvider.getTokenCode();
      final contactID = await authProvider.getContactID();

      if (email.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        return {
          'success': false,
          'message': 'Missing user credentials. Please login again.',
        };
      }

      print('Updating passcode via API for ContactID: $contactID');

      // Call the API to update password
      final result = await ApiService.updateMemberPassword(
        email: email,
        tokenCode: tokenCode,
        contactID: contactID,
        oldPassword: oldPasscode,
        newPassword: newPasscode,
      );

      if (result['success'] == true) {
        // If API update successful, update local storage
        await setUserPasscode(newPasscode);
        return {
          'success': true,
          'message': result['message'] ?? 'Passcode updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to update passcode',
        };
      }
    } catch (e) {
      print('Error updating passcode via API: $e');
      return {
        'success': false,
        'message': 'Failed to update passcode: $e',
      };
    }
  }

  // Check if app lock is required
  Future<bool> isAppLockRequired() async {
    final appLockEnabled = await isAppLockEnabled;
    
    if (!appLockEnabled) {
      return false;
    }

    final lastAuth = await lastAuthTime;
    if (lastAuth == null) {
      return true;
    }

    final timeout = await sessionTimeout;
    final now = DateTime.now();
    final timeDifference = now.difference(lastAuth).inMinutes;
    
    return timeDifference >= timeout;
  }

  // Clear all security data (for logout)
  Future<void> clearSecurityData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAuthTimeKey);
    await prefs.remove(_passcodeKey);
  }
}
