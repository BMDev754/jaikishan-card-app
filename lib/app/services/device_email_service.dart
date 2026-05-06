import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DeviceEmailService {
  static final DeviceEmailService _instance = DeviceEmailService._internal();
  factory DeviceEmailService() => _instance;
  DeviceEmailService._internal();

  static const MethodChannel _channel = MethodChannel('com.jaykisan.jaykisan_card/device_accounts');
  
  List<String> _cachedEmails = [];
  bool _permissionGranted = false;
  
  // Google Sign-In instance for fallback account access
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// Get all email addresses from device contacts and accounts
  Future<List<String>> getDeviceEmails() async {
    try {
      // If we already have cached emails and permission, return them
      if (_cachedEmails.isNotEmpty && _permissionGranted) {
        return _cachedEmails;
      }

      // Request contacts permission
      final permission = await Permission.contacts.request();
      _permissionGranted = permission == PermissionStatus.granted;

      if (!_permissionGranted) {
        if (kDebugMode) {
          print('Contacts permission denied - Status: $permission');
        }
        return _getFallbackEmails();
      }

      if (kDebugMode) {
        print('Contacts permission granted, fetching contacts...');
      }

      // Get contacts with email addresses
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (kDebugMode) {
        print('Found ${contacts.length} total contacts');
      }

      // Extract unique email addresses
      Set<String> emailSet = {};
      
      for (final contact in contacts) {
        for (final email in contact.emails) {
          if (email.address.isNotEmpty && _isValidEmail(email.address)) {
            emailSet.add(email.address.toLowerCase().trim());
          }
        }
      }

      if (kDebugMode) {
        print('Found ${emailSet.length} email addresses from contacts');
      }

      // Add common device account emails (these are typically system accounts)
      emailSet.addAll(await _getSystemAccountEmails());

      _cachedEmails = emailSet.toList();
      
      // Sort with Google accounts first, then alphabetically
      _cachedEmails.sort((a, b) {
        final aIsGoogle = _isGoogleAccount(a);
        final bIsGoogle = _isGoogleAccount(b);
        
        if (aIsGoogle && !bIsGoogle) return -1;
        if (!aIsGoogle && bIsGoogle) return 1;
        return a.compareTo(b);
      });

      if (kDebugMode) {
        print('Found ${_cachedEmails.length} email addresses from device');
        final googleAccounts = _cachedEmails.where(_isGoogleAccount).toList();
        print('Found ${googleAccounts.length} Google accounts: $googleAccounts');
      }

      return _cachedEmails;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device emails: $e');
      }
      return _getFallbackEmails();
    }
  }

  /// Get system account emails (Gmail, Outlook, etc.)
  Future<List<String>> _getSystemAccountEmails() async {
    List<String> systemEmails = [];
    
    try {
      // First, request accounts permission through platform channel
      final permissionGranted = await _channel.invokeMethod('requestAccountsPermission');
      
      if (permissionGranted == true) {
        // Get device accounts through platform channel
        final List<dynamic> accounts = await _channel.invokeMethod('getDeviceAccounts');
        
        for (final account in accounts) {
          if (account is String && _isValidEmail(account)) {
            systemEmails.add(account.toLowerCase().trim());
          }
        }
        
        if (kDebugMode) {
          print('Found ${systemEmails.length} system account emails: $systemEmails');
        }
      } else {
        if (kDebugMode) {
          print('GET_ACCOUNTS permission denied');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting system account emails: $e');
      }
    }
    
    // Fallback: Try Google Sign-In for Google accounts
    if (systemEmails.isEmpty) {
      try {
        final googleAccounts = await getGoogleAccountsViaSignIn();
        systemEmails.addAll(googleAccounts);
        
        if (kDebugMode) {
          print('Found ${googleAccounts.length} Google accounts via fallback: $googleAccounts');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting Google accounts via fallback: $e');
        }
      }
    }
    
    // Additional fallback: Try to detect common patterns in contacts
    if (systemEmails.isEmpty) {
      try {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        
        for (final contact in contacts) {
          for (final email in contact.emails) {
            final emailAddress = email.address.toLowerCase();
            
            // Check if this looks like a primary account email
            if (_isPrimaryAccountEmail(emailAddress, contact)) {
              systemEmails.add(emailAddress);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting fallback system account emails: $e');
        }
      }
    }
    
    return systemEmails;
  }

  /// Check if an email looks like a primary device account
  bool _isPrimaryAccountEmail(String email, Contact contact) {
    // Logic to identify primary device accounts
    // This is simplified - in reality you'd check against actual device accounts
    
    // Check if contact name suggests it's the device owner
    final name = contact.displayName.toLowerCase();
    final emailPrefix = email.split('@')[0].toLowerCase();
    
    // If the email prefix matches the contact name, it's likely a primary account
    if (name.contains(emailPrefix) || emailPrefix.contains(name.split(' ')[0])) {
      return true;
    }
    
    // Check for common primary account patterns
    if (email.contains('gmail.com') || 
        email.contains('outlook.com') || 
        email.contains('icloud.com') ||
        email.contains('yahoo.com')) {
      // Additional logic could be added here
      return contact.emails.length == 1; // Likely primary if only email
    }
    
    return false;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if email is a Google account (Gmail)
  bool _isGoogleAccount(String email) {
    return email.toLowerCase().contains('@gmail.com');
  }

  /// Get specifically Google accounts from the device
  Future<List<String>> getGoogleAccounts() async {
    final allEmails = await getDeviceEmails();
    return allEmails.where(_isGoogleAccount).toList();
  }

  /// Get account type for display
  String getAccountType(String email) {
    if (_isGoogleAccount(email)) return 'Google Account';
    if (email.contains('@outlook.com') || email.contains('@hotmail.com') || email.contains('@live.com')) {
      return 'Microsoft Account';
    }
    if (email.contains('@icloud.com')) return 'Apple ID';
    if (email.contains('@yahoo.com')) return 'Yahoo Account';
    return 'Email Account';
  }

  /// Get account icon for display
  String getAccountIcon(String email) {
    if (_isGoogleAccount(email)) return '🔴'; // Google red
    if (email.contains('@outlook.com') || email.contains('@hotmail.com') || email.contains('@live.com')) {
      return '🔵'; // Microsoft blue
    }
    if (email.contains('@icloud.com')) return '⚪'; // Apple white/gray
    if (email.contains('@yahoo.com')) return '🟣'; // Yahoo purple
    return '📧'; // Generic email
  }

  /// Fallback emails when permission is denied or error occurs
  List<String> _getFallbackEmails() {
    if (!_permissionGranted) {
      return [
        'Permission required to access contacts',
        'Tap to grant contacts permission',
      ];
    }
    return [
      'No email addresses found in contacts',
      'Add contacts with email addresses to your device',
    ];
  }

  /// Clear cached emails (useful for refresh)
  void clearCache() {
    _cachedEmails.clear();
    _permissionGranted = false;
  }

  /// Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    final status = await Permission.contacts.status;
    return status == PermissionStatus.granted;
  }

  /// Request contacts permission
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    _permissionGranted = status == PermissionStatus.granted;
    return _permissionGranted;
  }

  /// Request accounts permission specifically for device accounts
  Future<bool> requestAccountsPermission() async {
    try {
      final permissionGranted = await _channel.invokeMethod('requestAccountsPermission');
      return permissionGranted == true;
    } catch (e) {
      if (kDebugMode) {
        print('Platform channel not available for accounts permission: $e');
        print('Falling back to Google Sign-In method');
      }
      
      // If platform channel fails, try Google Sign-In as alternative
      try {
        final googleAccounts = await getGoogleAccountsViaSignIn();
        return googleAccounts.isNotEmpty;
      } catch (googleError) {
        if (kDebugMode) {
          print('Google Sign-In fallback also failed: $googleError');
        }
        return false;
      }
    }
  }

  /// Get Google accounts using Google Sign-In as fallback
  Future<List<String>> getGoogleAccountsViaSignIn() async {
    try {
      // Get already signed-in account without showing picker
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      if (currentUser != null && currentUser.email.isNotEmpty) {
        if (kDebugMode) {
          print('Found current Google account: ${currentUser.email}');
        }
        return [currentUser.email];
      }
      
      // Try to silently sign in to get saved accounts
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      if (account != null && account.email.isNotEmpty) {
        if (kDebugMode) {
          print('Found Google account via silent sign-in: ${account.email}');
        }
        return [account.email];
      }
      
      if (kDebugMode) {
        print('No Google accounts found via silent sign-in');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting Google accounts via sign-in: $e');
      }
      return [];
    }
  }

  /// Show Google account picker for user to select account
  Future<String?> showGoogleAccountPicker() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null && account.email.isNotEmpty) {
        if (kDebugMode) {
          print('User selected Google account: ${account.email}');
        }
        return account.email;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error showing Google account picker: $e');
      }
      return null;
    }
  }
}
