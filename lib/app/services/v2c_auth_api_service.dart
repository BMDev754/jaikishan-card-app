import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class V2CAuthApiService {
  static const String baseUrl = 'https://api.v2cbazar.com/api/Response';
  static const String cCode = 'V2CBAZAR';
  static const String companyId = '000001';
  
  /// Initialize and ensure FCM token is available before login
  /// Call this before initiating login flow
  static Future<String> initializeFCMTokenForLogin() async {
    try {
      // First try to get from shared preferences
      final prefs = await SharedPreferences.getInstance();
      String fcmToken = prefs.getString('fcm_token') ?? '';
      
      if (fcmToken.isNotEmpty) {
        print('✓ FCM token already available: $fcmToken');
        return fcmToken;
      }

      // If not in storage, get from Firebase Messaging
      print('Getting FCM token from Firebase...');
      final firebaseToken = await NotificationService.instance.getFCMToken();
      
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        // Save to shared preferences for future use
        await prefs.setString('fcm_token', firebaseToken);
        print('✓ FCM token obtained and saved: $firebaseToken');
        return firebaseToken;
      } else {
        print('⚠ Warning: Could not obtain FCM token, will send empty token');
        return '';
      }
    } catch (e) {
      print('✗ Error initializing FCM token: $e');
      return '';
    }
  }
  
  /// Send OTP to phone number
  /// API: ProcessPhoneOTPRequestForMember/000001
  static Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      final url = Uri.parse('$baseUrl/ProcessPhoneOTPRequestForMember/$companyId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'PhoneNumber': phoneNumber,
          'CCode': cCode,
        },
      );
      
      print('Send OTP Response Status: ${response.statusCode}');
      print('Send OTP Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Check if response structure is as expected
        if (data.containsKey('RESPONSE') && data['RESPONSE'] is List) {
          final responseData = data['RESPONSE'][0];
          
          if (responseData['ResponseCode'] == '200') {
            return {
              'success': true,
              'message': responseData['ResponseMessage'] ?? 'OTP sent successfully',
              'data': data,
            };
          } else {
            return {
              'success': false,
              'message': responseData['ResponseMessage'] ?? 'Failed to send OTP',
              'data': data,
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format',
            'data': data,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'error': e.toString(),
      };
    }
  }
  
  /// Verify OTP and login
  /// API: ProcessValidatePhoneOTPLoginForMember/000001
  static Future<Map<String, dynamic>> validatePhoneOTPLogin(String phoneNumber, String otp) async {
    try {
      // Ensure FCM token is initialized
      String fcmToken = await initializeFCMTokenForLogin();
      
      if (fcmToken.isEmpty) {
        print('⚠ Warning: FCM token is empty, attempting to get it now...');
        fcmToken = await NotificationService.instance.getFCMToken() ?? '';
      }

      print('=== V2C PHONE OTP LOGIN DEBUG ===');
      print('Phone Number: $phoneNumber');
      print('OTP: $otp');
      print('FCM Token: $fcmToken');
      print('==================================');

      final url = Uri.parse('$baseUrl/ProcessValidatePhoneOTPLoginForMember/$companyId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'PhoneNumber': phoneNumber,
          'CCode': cCode,
          'OTP': otp,
          'fcmToken': fcmToken, 
        },
      );
      
      print('Validate OTP Response Status: ${response.statusCode}');
      print('Validate OTP Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Check if response structure is as expected
        if (data.containsKey('RESPONSE') && data['RESPONSE'] is List) {
          final responseData = data['RESPONSE'][0];
          
          if (responseData['ResponseCode'] == '200') {
            // ✓ Save FCM token to shared preferences on successful login
            if (fcmToken.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('fcm_token', fcmToken);
              print('✓ FCM Token saved to SharedPreferences after successful phone OTP login: $fcmToken');
            }
            
            // Check UserCount for multiple users
            final loginDetailsList = data.containsKey('LoginDetails') && data['LoginDetails'] is List 
                ? data['LoginDetails'] as List
                : [];
            final userCount = loginDetailsList.length;
            
            print('=== V2C API SERVICE DEBUG ===');
            print('User count from V2C API: $userCount');
            print('Login details count: ${loginDetailsList.length}');
            print('=============================');
            
            // TEMPORARY TEST: Force multiple users for testing
            // Remove this condition after testing
            if (userCount >= 1 && loginDetailsList.isNotEmpty) {
              print('TESTING: Forcing multiple users for V2C API testing purposes');
              final originalUser = loginDetailsList[0] as Map<String, dynamic>;
              return {
                'success': true,
                'message': responseData['ResponseMessage'] ?? 'Login successful',
                'userCount': 2, // Force userCount to 2 for testing
                'multipleUsers': true,
                'users': [
                  originalUser,
                  {
                    'TokenCode': 'test_v2c_token_2',
                    'Name': '${originalUser['Name'] ?? 'User'} (Account 2)',
                    'Email': originalUser['Email'] ?? '',
                    'Mobile': originalUser['Mobile'] ?? '',
                    'Address': '${originalUser['Address'] ?? ''} - Branch 2',
                    'Gender': originalUser['Gender'] ?? '',
                    'DateofBirth': originalUser['DateofBirth'] ?? '',
                    'CardNo': 'V2C-CARD-002',
                    'ContactID': 'v2c_contact_2',
                  }
                ],
                'data': data,
              };
            }
            
            if (userCount > 1) {
              print('Multiple users detected in V2C API, returning user selection data');
              // Multiple users found - return all users for selection
              return {
                'success': true,
                'message': responseData['ResponseMessage'] ?? 'Login successful',
                'userCount': userCount,
                'multipleUsers': true,
                'users': loginDetailsList.map((user) => user as Map<String, dynamic>).toList(),
                'data': data,
              };
            } else {
              print('Single user detected in V2C API, proceeding with normal login');
              // Single user - proceed normally
              Map<String, dynamic>? loginDetails;
              if (loginDetailsList.isNotEmpty) {
                loginDetails = loginDetailsList[0];
              }
              
              return {
                'success': true,
                'message': responseData['ResponseMessage'] ?? 'Login successful',
                'userCount': userCount,
                'multipleUsers': false,
                'data': data,
                'loginDetails': loginDetails,
              };
            }
          } else {
            return {
              'success': false,
              'message': responseData['ResponseMessage'] ?? 'Invalid OTP',
              'data': data,
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format',
            'data': data,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Validate OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'error': e.toString(),
      };
    }
  }
  
  /// Helper method to validate phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or special characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if it's a 10-digit Indian mobile number
    return cleanNumber.length == 10 && cleanNumber.startsWith(RegExp(r'[6-9]'));
  }
  
  /// Helper method to format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length == 10) {
      return '+91 ${cleanNumber.substring(0, 5)} ${cleanNumber.substring(5)}';
    }
    return phoneNumber;
  }
}
