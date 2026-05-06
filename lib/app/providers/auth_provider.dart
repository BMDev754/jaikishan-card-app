import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';
import '../services/wallet_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _phoneNumber;
  String? _email;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      print('=== AuthProvider Initialization Started ===');
      
      // Ensure storage is initialized before checking auth status
      await _storageService.initialize();
      
      // Check authentication status and load stored data
      await checkAuthStatus();
      
      // If user is logged in but has no API data, set a flag to refresh on next screen load
      if (_isLoggedIn) {
        final hasApiData = await hasApiProfileData();
        print('User logged in: $_isLoggedIn, Has API data: $hasApiData');
        
        if (!hasApiData) {
          print('User is logged in but no API data found - screens will load with fallback data');
        }
      }
      
      // Force refresh of API data for all screens when app starts
      await refreshApiDataForAllScreens();
      
      _isInitialized = true;
      print('=== AuthProvider Initialization Complete ===');
      notifyListeners();
    } catch (e) {
      print('Error during AuthProvider initialization: $e');
      _isInitialized = true; // Still mark as initialized to prevent blocking
      notifyListeners();
    }
  }

  // Method to refresh API data and notify all listeners
  Future<void> refreshApiDataForAllScreens() async {
    try {
      print('=== Refreshing API Data for All Screens ===');
      
      // Check if we have API data in storage
      final hasData = await hasApiProfileData();
      if (hasData) {
        print('API data found in storage - notifying all screens');
        // Small delay to ensure all widgets are built before notifying
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
      } else {
        print('No API data in storage - screens will need to load fresh data');
      }
      
      print('=== API Data Refresh Complete ===');
    } catch (e) {
      print('Error refreshing API data: $e');
    }
  }

  Future<void> loginWithPhone(String phoneNumber) async {
    try {
      _isLoggedIn = true;
      _userId = 'user_${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}';
      _userName = 'User';
      _phoneNumber = phoneNumber;
      
      // Save login state to storage
      await _storageService.saveUserData('is_logged_in', true);
      await _storageService.saveUserData('user_id', _userId);
      await _storageService.saveUserData('user_name', _userName);
      await _storageService.saveUserData('phone_number', _phoneNumber);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<void> loginWithEmail(String email) async {
    try {
      _isLoggedIn = true;
      _userId = 'user_${email.replaceAll('@', '_').replaceAll('.', '_')}';
      _userName = 'User';
      _phoneNumber = null; // No phone number for email login
      _email = email;
      
      // Save login state to storage
      await _storageService.saveUserData('is_logged_in', true);
      await _storageService.saveUserData('user_id', _userId);
      await _storageService.saveUserData('user_name', _userName);
      await _storageService.saveUserData('email', email);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<void> loginWithEmailData(String email, String userName, String tokenCode, {Map<String, dynamic>? additionalData}) async {
    try {
      _isLoggedIn = true;
      _userId = 'user_${email.replaceAll('@', '_').replaceAll('.', '_')}';
      _userName = userName.isNotEmpty ? userName : 'User';
      _phoneNumber = null; // No phone number for email login
      _email = email;
      
      // Save login state to storage
      await _storageService.saveUserData('is_logged_in', true);
      await _storageService.saveUserData('user_id', _userId);
      await _storageService.saveUserData('user_name', _userName);
      await _storageService.saveUserData('email', email);
      await _storageService.saveUserData('token_code', tokenCode);
      
      // Save additional profile data from API if provided
      if (additionalData != null) {
        await _storageService.saveUserData('api_profile_data', additionalData);
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<void> loginWithV2CApiData(Map<String, dynamic> loginDetails) async {
    try {
      _isLoggedIn = true;
      
      // Extract data from V2C API response
      final tokenCode = loginDetails['TokenCode'] ?? '';
      final email = loginDetails['Email'] ?? '';
      final name = loginDetails['Name'] ?? 'User';
      final mobile = loginDetails['Mobile'] ?? '';
      final address = loginDetails['Address'] ?? '';
      final cardNo = loginDetails['CardNo'] ?? '';
      final contactId = loginDetails['ContactID'] ?? '';
      
      // Set provider properties
      _userId = contactId.isNotEmpty ? contactId : 'user_${mobile.replaceAll('+', '').replaceAll(' ', '')}';
      _userName = name.isNotEmpty ? name : 'User';
      _phoneNumber = mobile.isNotEmpty ? '+91$mobile' : null;
      _email = email;
      
      // Save login state to storage
      await _storageService.saveUserData('is_logged_in', true);
      await _storageService.saveUserData('user_id', _userId);
      await _storageService.saveUserData('user_name', _userName);
      await _storageService.saveUserData('phone_number', _phoneNumber);
      await _storageService.saveUserData('email', _email);
      await _storageService.saveUserData('token_code', tokenCode);
      
      // Save the complete API profile data
      await _storageService.saveUserData('api_profile_data', loginDetails);
      
      print('=== V2C API Login Successful ===');
      print('Name: $name');
      print('Mobile: $mobile');
      print('Email: $email');
      print('Card No: $cardNo');
      print('Contact ID: $contactId');
      print('====================================');
      
      notifyListeners();
    } catch (e) {
      print('Error in V2C API login: $e');
      throw Exception('Login failed');
    }
  }

  // Method to get API profile data
  Future<Map<String, dynamic>?> getApiProfileData() async {
    try {
      // Ensure storage is initialized
      await _storageService.initialize();
      
      final data = _storageService.getUserData('api_profile_data');
      
      if (data is Map<String, dynamic>) {
        return data;
      }
      
      // Try to convert if it's a different Map type
      if (data is Map) {
        try {
          final convertedData = Map<String, dynamic>.from(data);
          return convertedData;
        } catch (e) {
          print('Error converting API profile data: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting API profile data: $e');
      return null;
    }
  }

  // Get profile name from API data, fallback to stored username
  Future<String> getProfileName() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String apiName = apiData['Name'] ?? '';
        if (apiName.isNotEmpty) {
          return apiName;
        }
      }
      return _userName ?? 'Guest User';
    } catch (e) {
      return _userName ?? 'Guest User';
    }
  }

  // Get profile email from API data, fallback to stored email
  Future<String> getProfileEmail() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String apiEmail = apiData['Email'] ?? apiData['email'] ?? ''; // Check both capital and lowercase
        if (apiEmail.isNotEmpty) {
          return apiEmail;
        }
      }
      return _email ?? '';
    } catch (e) {
      return _email ?? '';
    }
  }

  // Get profile mobile from API data, fallback to stored phone
  Future<String> getProfileMobile() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String apiMobile = apiData['Mobile'] ?? '';
        if (apiMobile.isNotEmpty) {
          // Clean mobile number - remove +91 prefix if present
          if (apiMobile.startsWith('+91')) {
            apiMobile = apiMobile.substring(3).trim();
          }
          return apiMobile;
        }
      }
      
      // Fallback to stored phone
      String phone = _phoneNumber ?? '';
      if (phone.startsWith('+91')) {
        phone = phone.substring(3).trim();
      }
      return phone;
    } catch (e) {
      String phone = _phoneNumber ?? '';
      if (phone.startsWith('+91')) {
        phone = phone.substring(3).trim();
      }
      return phone;
    }
  }

  // Get token code for API calls
  Future<String> getTokenCode() async {
    try {
      final tokenCode = await _storageService.getUserData('token_code');
      print('=== getTokenCode Debug ===');
      print('Token code found: ${tokenCode ?? 'null'}');
      print('==========================');
      return tokenCode ?? '';
    } catch (e) {
      print('Error getting token code: $e');
      return '';
    }
  }

  // Get contact ID for API calls
  Future<String> getContactID() async {
    try {
      final apiData = await getApiProfileData();
      print('=== getContactID Debug ===');
      print('API Data available: ${apiData != null}');
      if (apiData != null) {
        print('API Data keys: ${apiData.keys.toList()}');
        final contactID = apiData['ContactID'] ?? '';
        print('ContactID found: $contactID');
        return contactID;
      }
      print('No API data found');
      return '';
    } catch (e) {
      print('Error getting ContactID: $e');
      return '';
    }
  }

  // Getter methods for API profile data
  Future<String> getApiUserName() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        final apiName = apiData['Name'] ?? '';
        return apiName.isNotEmpty ? apiName : (_userName ?? 'Guest User');
      }
      return _userName ?? 'Guest User';
    } catch (e) {
      print('Error getting API user name: $e');
      return _userName ?? 'Guest User';
    }
  }

  Future<String> getApiUserEmail() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        final apiEmail = apiData['email'] ?? '';
        return apiEmail.isNotEmpty ? apiEmail : (_email ?? '');
      }
      return _email ?? '';
    } catch (e) {
      print('Error getting API user email: $e');
      return _email ?? '';
    }
  }

  Future<String> getApiUserMobile() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String apiMobile = apiData['Mobile'] ?? '';
        // Clean mobile number - remove +91 prefix if present
        if (apiMobile.startsWith('+91')) {
          apiMobile = apiMobile.substring(3).trim();
        }
        
        // Fallback to stored phone number if API mobile is empty
        if (apiMobile.isEmpty) {
          String authPhone = _phoneNumber ?? '';
          if (authPhone.startsWith('+91')) {
            authPhone = authPhone.substring(3).trim();
          }
          return authPhone;
        }
        return apiMobile;
      }
      
      // Fallback to stored phone number
      String authPhone = _phoneNumber ?? '';
      if (authPhone.startsWith('+91')) {
        authPhone = authPhone.substring(3).trim();
      }
      return authPhone;
    } catch (e) {
      print('Error getting API user mobile: $e');
      String authPhone = _phoneNumber ?? '';
      if (authPhone.startsWith('+91')) {
        authPhone = authPhone.substring(3).trim();
      }
      return authPhone;
    }
  }

  // Get card number from API data
  Future<String> getCardNumber() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String cardNo = apiData['CardNo'] ?? '';
        if (cardNo.isNotEmpty) {
          return cardNo;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting card number: $e');
      return '';
    }
  }

  // Get card CVV from API data
  Future<String> getCardCVV() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String cardCVV = apiData['CardCVV'] ?? '';
        if (cardCVV.isNotEmpty) {
          return cardCVV;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting card CVV: $e');
      return '';
    }
  }

  // Get card validity from API data
  Future<String> getCardValidity() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String cardValidity = apiData['CardValidity'] ?? '';
        if (cardValidity.isNotEmpty) {
          return cardValidity;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting card validity: $e');
      return '';
    }
  }

  // Get date of birth from API data
  Future<String> getDateOfBirth() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String dob = apiData['DateofBirth'] ?? '';
        if (dob.isNotEmpty) {
          return dob;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting date of birth: $e');
      return '';
    }
  }

  // Get gender from API data
  Future<String> getGender() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String gender = apiData['Gender'] ?? '';
        if (gender.isNotEmpty) {
          return gender;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting gender: $e');
      return '';
    }
  }

  // Get address from API data
  Future<String> getAddress() async {
    try {
      final apiData = await getApiProfileData();
      if (apiData != null) {
        String address = apiData['Address'] ?? '';
        if (address.isNotEmpty) {
          return address;
        }
      }
      return ''; // Empty if not available
    } catch (e) {
      print('Error getting address: $e');
      return '';
    }
  }

  // Update specific fields in stored API profile data
  Future<void> updateApiProfileData(Map<String, dynamic> updates) async {
    try {
      final currentApiData = await getApiProfileData();
      if (currentApiData != null) {
        // Merge updates with existing data
        final updatedData = Map<String, dynamic>.from(currentApiData);
        updatedData.addAll(updates);
        
        // Save updated data back to storage
        await _storageService.saveUserData('api_profile_data', updatedData);
        
        print('=== Updated API Profile Data ===');
        print('Updates applied: $updates');
        print('================================');
        
        notifyListeners();
      }
    } catch (e) {
      print('Error updating API profile data: $e');
    }
  }

  // Update the user's email both in memory and storage
  Future<void> updateUserEmail(String newEmail) async {
    try {
      _email = newEmail;
      await _storageService.saveUserData('email', newEmail);
      print('=== Updated User Email ===');
      print('New email: $newEmail');
      print('=========================');
      notifyListeners();
    } catch (e) {
      print('Error updating user email: $e');
    }
  }

  // Check if API profile data is available
  Future<bool> hasApiProfileData() async {
    try {
      final apiData = await getApiProfileData();
      return apiData != null && apiData.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Debug method to check storage directly
  Future<dynamic> debugGetStorageData(String key) async {
    try {
      await _storageService.initialize();
      return _storageService.getUserData(key);
    } catch (e) {
      print('Error in debug storage check: $e');
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      _isLoggedIn = true;
      _userId = 'user_123';
      _userName = 'John Doe';
      
      // Save login state to storage
      await _storageService.saveUserData('is_logged_in', true);
      await _storageService.saveUserData('user_id', _userId);
      await _storageService.saveUserData('user_name', _userName);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    _phoneNumber = null;
    _email = null;
    
    // Clear login state from storage
    await _storageService.removeUserData('is_logged_in');
    await _storageService.removeUserData('user_id');
    await _storageService.removeUserData('user_name');
    await _storageService.removeUserData('phone_number');
    await _storageService.removeUserData('email');
    await _storageService.removeUserData('token_code');
    await _storageService.removeUserData('api_profile_data');  // Clear API profile data
    await _storageService.removeAuthToken();
    
    // Clear security data
    await SecurityService.instance.clearSecurityData();
    
    // Clear wallet data
    await WalletService.instance.clearWalletData();
    
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      print('=== checkAuthStatus Started ===');
      
      // Debug: Show all storage contents
      await debugStorageContents();
      
      // Check if user is already logged in by reading from storage
      final isLoggedIn = _storageService.getUserData('is_logged_in') ?? false;
      final userId = _storageService.getUserData('user_id');
      final userName = _storageService.getUserData('user_name');
      final phoneNumber = _storageService.getUserData('phone_number');
      final email = _storageService.getUserData('email');
      
      print('Storage data retrieved:');
      print('- isLoggedIn: $isLoggedIn');
      print('- userId: $userId');
      print('- userName: $userName');
      print('- phoneNumber: $phoneNumber');
      print('- email: $email');
      
      if (isLoggedIn && userId != null) {
        _isLoggedIn = true;
        _userId = userId;
        _userName = userName;
        _phoneNumber = phoneNumber;
        _email = email;
        
        // Load API profile data if available
        final hasApiData = await hasApiProfileData();
        final apiData = await getApiProfileData();
        
        print('=== Auth Status Check ===');
        print('User logged in: $_isLoggedIn');
        print('User ID: $_userId');
        print('User Name: $_userName');
        print('Phone: $_phoneNumber');
        print('Email: $_email');
        print('Has API Data: $hasApiData');
        if (apiData != null) {
          print('API Data available with keys: ${apiData.keys.toList()}');
          print('API Name: ${apiData['Name']}');
          print('API Email: ${apiData['email']}');
          print('API Mobile: ${apiData['Mobile']}');
          
          // If we have cached API data but the user restarted the app,
          // trigger a notification to update all widgets that depend on this data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        } else {
          print('API Data is null - screens may need to reload data');
        }
        print('=========================');
      } else {
        print('User not logged in or missing userId');
        _isLoggedIn = false;
        _userId = null;
        _userName = null;
        _phoneNumber = null;
        _email = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error checking auth status: $e');
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Debug method to check all storage keys
  Future<void> debugStorageContents() async {
    try {
      await _storageService.initialize();
      print('=== Storage Debug ===');
      print('All user data keys in storage:');
      
      // Get specific keys we care about
      final keys = ['is_logged_in', 'user_id', 'user_name', 'phone_number', 'email', 'api_profile_data', 'token_code'];
      for (final key in keys) {
        final value = _storageService.getUserData(key);
        print('- $key: ${value != null ? value.runtimeType : 'null'} = $value');
      }
      print('====================');
    } catch (e) {
      print('Error debugging storage: $e');
    }
  }
}
