import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_models.dart';
import '../notification_service.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

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

  // Send Email OTP
  static Future<Map<String, dynamic>> sendEmailOTP(String email) async {
    try {
      // Use the correct API endpoint
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/ProcessEmailOTPRequestForMember/000001');
      
      final response = await http.get(
        uri,
        headers: {
          'EmailID': email,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
        },
      ).timeout(_timeout);

      print('Send OTP Response Status: ${response.statusCode}');
      print('Send OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final emailOTPResponse = EmailOTPResponse.fromJson(responseData);
        
        if (emailOTPResponse.response.isNotEmpty && 
            emailOTPResponse.response.first.isSuccess) {
          
          // Extract OTP from response
          String otp = '';
          if (emailOTPResponse.loginEmailOTP.isNotEmpty) {
            otp = emailOTPResponse.loginEmailOTP.first.otp;
          }
          
          return {
            'success': true,
            'otp': otp,
            'message': emailOTPResponse.response.first.responseMessage,
          };
        } else {
          return {
            'success': false,
            'message': emailOTPResponse.response.isNotEmpty 
                ? emailOTPResponse.response.first.responseMessage 
                : 'Failed to send OTP',
          };
        }
      } else if (response.statusCode == 405) {
        // If GET doesn't work, try POST with different body format
        return await _sendEmailOTPPost(email);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    } catch (e) {
      print('Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
      };
    }
  }

  // Alternative POST method
  static Future<Map<String, dynamic>> _sendEmailOTPPost(String email) async {
    try {
      // Try with minimal body format
      final response = await http.post(
        Uri.parse(ApiConfig.emailOTPUrl),
        headers: {
          ...ApiConfig.headers,
          'EmailID': email,
          'CCode': 'V2CBAZAR',
        },
        body: jsonEncode({
          'EmailID': email,
          'CCode': 'V2CBAZAR',
        }),
      ).timeout(_timeout);

      print('Send OTP POST Response Status: ${response.statusCode}');
      print('Send OTP POST Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final emailOTPResponse = EmailOTPResponse.fromJson(responseData);
        
        if (emailOTPResponse.response.isNotEmpty && 
            emailOTPResponse.response.first.isSuccess) {
          
          // Extract OTP from response
          String otp = '';
          if (emailOTPResponse.loginEmailOTP.isNotEmpty) {
            otp = emailOTPResponse.loginEmailOTP.first.otp;
          }
          
          return {
            'success': true,
            'otp': otp,
            'message': emailOTPResponse.response.first.responseMessage,
          };
        } else {
          return {
            'success': false,
            'message': emailOTPResponse.response.isNotEmpty 
                ? emailOTPResponse.response.first.responseMessage 
                : 'Failed to send OTP',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
      };
    }
  }

  // Validate Email OTP and Login
  static Future<Map<String, dynamic>> validateEmailOTP(String email, String otp) async {
    try {
      // Ensure FCM token is initialized
      String fcmToken = await initializeFCMTokenForLogin();
      
      if (fcmToken.isEmpty) {
        print('⚠ Warning: FCM token is empty, attempting to get it now...');
        fcmToken = await NotificationService.instance.getFCMToken() ?? '';
      }

      print('=== LOGIN API DEBUG ===');
      print('Email: $email');
      print('OTP: $otp');
      print('FCM Token: $fcmToken');
      print('======================');

      // Use the correct API endpoint
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/ProcessValidateEmailOTPLoginForMember/000001');

      final response = await http.get(
        uri,
        headers: {
          'EmailID': email,
          'OTP': otp,
          'fcmToken': fcmToken, 
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
        },
      ).timeout(_timeout);

      print('Validate OTP Response Status: ${response.statusCode}');
      print('Validate OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final validateOTPResponse = ValidateOTPResponse.fromJson(responseData);
        
        if (validateOTPResponse.response.isNotEmpty && 
            validateOTPResponse.response.first.isSuccess) {
          
          // ✓ Save FCM token to shared preferences on successful login
          if (fcmToken.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fcm_token', fcmToken);
            print('✓ FCM Token saved to SharedPreferences after successful login: $fcmToken');
          }
          
          // Check UserCount for multiple users
          final userCount = validateOTPResponse.loginDetails.length;
          
          print('=== API SERVICE DEBUG ===');
          print('User count from API: $userCount');
          print('Login details count: ${validateOTPResponse.loginDetails.length}');
          print('========================');
          
          // TEMPORARY TEST: Force multiple users for testing
          // Remove this condition after testing
          // if (userCount >= 1) {
          //   print('TESTING: Forcing multiple users for testing purposes');
          //   // Create a test scenario with multiple users
          //   final originalUser = validateOTPResponse.loginDetails.first;
          //   return {
          //     'success': true,
          //     'message': validateOTPResponse.response.first.responseMessage,
          //     'userCount': 2, // Force userCount to 2 for testing
          //     'multipleUsers': true,
          //     'users': [
          //       {
          //         'tokenCode': originalUser.tokenCode,
          //         'Name': originalUser.name,
          //         'email': originalUser.email,
          //         'Mobile': originalUser.mobile,
          //         'Address': originalUser.address,
          //         'Gender': originalUser.gender,
          //         'DateofBirth': originalUser.dateOfBirth,
          //         'CardNo': originalUser.cardNo,
          //         'ContactID': originalUser.contactID,
          //         'latitude': originalUser.latitude,
          //         'longitude': originalUser.longitude,
          //         'buildingRadius': originalUser.buildingRadius,
          //       },
          //       {
          //         'tokenCode': 'test_token_2',
          //         'Name': '${originalUser.name} (Account 2)',
          //         'email': originalUser.email,
          //         'Mobile': originalUser.mobile,
          //         'Address': '${originalUser.address} - Branch 2',
          //         'Gender': originalUser.gender,
          //         'DateofBirth': originalUser.dateOfBirth,
          //         'CardNo': 'TEST-CARD-002',
          //         'ContactID': 'contact_2',
          //         'latitude': originalUser.latitude,
          //         'longitude': originalUser.longitude,
          //         'buildingRadius': originalUser.buildingRadius,
          //       }
          //     ],
          //   };
          // }
          
          if (userCount > 1) {
            print('Multiple users detected, returning user selection data');
            // Multiple users found - return all users for selection
            return {
              'success': true,
              'message': validateOTPResponse.response.first.responseMessage,
              'userCount': userCount,
              'multipleUsers': true,
              'users': validateOTPResponse.loginDetails.map((user) => {
                'tokenCode': user.tokenCode,
                'Name': user.name,
                'email': user.email,
                'Mobile': user.mobile,
                'Address': user.address,
                'Gender': user.gender,
                'DateofBirth': user.dateOfBirth,
                'CardNo': user.cardNo,
                'ContactID': user.contactID,
                'latitude': user.latitude,
                'longitude': user.longitude,
                'buildingRadius': user.buildingRadius,
              }).toList(),
            };
          } else {
            print('Single user detected, proceeding with normal login');
            // Single user - proceed normally
            LoginDetails? loginDetails;
            if (validateOTPResponse.loginDetails.isNotEmpty) {
              loginDetails = validateOTPResponse.loginDetails.first;
            }
            
            return {
              'success': true,
              'message': validateOTPResponse.response.first.responseMessage,
              'userCount': userCount,
              'multipleUsers': false,
              'loginDetails': loginDetails,
              'tokenCode': loginDetails?.tokenCode ?? '',
              'Name': loginDetails?.name ?? '',
              'email': loginDetails?.email ?? '',
              'Mobile': loginDetails?.mobile ?? '',
              'Address': loginDetails?.address ?? '',
              'Gender': loginDetails?.gender ?? '',
              'DateofBirth': loginDetails?.dateOfBirth ?? '',
              'CardNo': loginDetails?.cardNo ?? '',
              'ContactID': loginDetails?.contactID ?? '',
              'latitude': loginDetails?.latitude ?? '',
              'longitude': loginDetails?.longitude ?? '',
              'buildingRadius': loginDetails?.buildingRadius ?? '',
            };
          }
        } else {
          return {
            'success': false,
            'message': validateOTPResponse.response.isNotEmpty 
                ? validateOTPResponse.response.first.responseMessage 
                : 'Invalid OTP',
          };
        }
      } else if (response.statusCode == 405) {
        // If GET doesn't work, try POST
        return await _validateEmailOTPPost(email, otp);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    } catch (e) {
      print('Validate OTP Error: $e');
      return {
        'success': false,
        'message': 'Failed to validate OTP: ${e.toString()}',
      };
    }
  }

  // Alternative POST method for validation
  static Future<Map<String, dynamic>> _validateEmailOTPPost(String email, String otp) async {
    try {
      // Get FCM token
      String fcmToken = await initializeFCMTokenForLogin();
      if (fcmToken.isEmpty) {
        fcmToken = await NotificationService.instance.getFCMToken() ?? '';
      }

      final response = await http.post(
        Uri.parse(ApiConfig.validateOTPUrl),
        headers: {
          ...ApiConfig.headers,
          'EmailID': email,
          'OTP': otp,
          'fcmToken': fcmToken, // MANDATORY: Pass FCM token in header
          'CCode': 'V2CBAZAR',
        },
        body: jsonEncode({
          'EmailID': email,
          'OTP': otp,
          'CCode': 'V2CBAZAR',
        }),
      ).timeout(_timeout);

      print('Validate OTP POST Response Status: ${response.statusCode}');
      print('Validate OTP POST Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final validateOTPResponse = ValidateOTPResponse.fromJson(responseData);
        
        if (validateOTPResponse.response.isNotEmpty && 
            validateOTPResponse.response.first.isSuccess) {
          
          // ✓ Save FCM token to shared preferences on successful login
          if (fcmToken.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fcm_token', fcmToken);
            print('✓ FCM Token saved to SharedPreferences after successful POST login: $fcmToken');
          }
          
          // Extract login details
          LoginDetails? loginDetails;
          if (validateOTPResponse.loginDetails.isNotEmpty) {
            loginDetails = validateOTPResponse.loginDetails.first;
          }
          
          return {
            'success': true,
            'message': validateOTPResponse.response.first.responseMessage,
            'loginDetails': loginDetails,
            'tokenCode': loginDetails?.tokenCode ?? '',
            'Name': loginDetails?.name ?? '',
            'email': loginDetails?.email ?? '',
            'Mobile': loginDetails?.mobile ?? '',
            'Address': loginDetails?.address ?? '',
            'Gender': loginDetails?.gender ?? '',
            'DateofBirth': loginDetails?.dateOfBirth ?? '',
            'CardNo': loginDetails?.cardNo ?? '',
            'ContactID': loginDetails?.contactID ?? '',
            'latitude': loginDetails?.latitude ?? '',
            'longitude': loginDetails?.longitude ?? '',
            'buildingRadius': loginDetails?.buildingRadius ?? '',
          };
        } else {
          return {
            'success': false,
            'message': validateOTPResponse.response.isNotEmpty 
                ? validateOTPResponse.response.first.responseMessage 
                : 'Invalid OTP',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to validate OTP: ${e.toString()}',
      };
    }
  }

  // Get Recent Ledger Contacts
  static Future<Map<String, dynamic>> getRecentLedger(String email, String tokenCode, String contactID) async {
    try {
      print('Getting recent ledger for ContactID: $contactID');
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestGetRecentLedger/000001');

      final response = await http.get(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
          'ContactID': contactID,
        },
      ).timeout(_timeout);

      print('Recent Ledger Response Status: ${response.statusCode}');
      print('Recent Ledger Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response structure is valid
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final responseItem = responseList.first;
            final responseCode = responseItem['ResponseCode']?.toString() ?? '';
            
            if (responseCode == '200') {
              // Extract recent ledger data
              final recentLedger = responseData['recentLedger'] as List? ?? [];
              
              return {
                'success': true,
                'message': responseItem['ResponseMessage'] ?? 'Data retrieved successfully',
                'recentLedger': recentLedger,
                'count': recentLedger.length,
              };
            } else {
              return {
                'success': false,
                'message': responseItem['ResponseMessage'] ?? 'Failed to retrieve data',
                'recentLedger': [],
                'count': 0,
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format',
          'recentLedger': [],
          'count': 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'recentLedger': [],
          'count': 0,
        };
      }
    } catch (e) {
      print('Error getting recent ledger: $e');
      return {
        'success': false,
        'message': 'Failed to get recent contacts: ${e.toString()}',
        'recentLedger': [],
        'count': 0,
      };
    }
  }

  // Get Ledger Balance By ID
  static Future<Map<String, dynamic>> getLedgerBalanceByID(String email, String tokenCode, String contactID) async {
    try {
      print('Getting ledger balance for ContactID: $contactID');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/RequestGetLedgerBalanceByID/000001'),
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
          'ContactID': contactID,
        },
      ).timeout(_timeout);

      print('Balance API Response status: ${response.statusCode}');
      print('Balance API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Check if response is successful
        if (data['RESPONSE'] != null && data['RESPONSE'] is List && data['RESPONSE'].isNotEmpty) {
          final responseInfo = data['RESPONSE'][0];
          if (responseInfo['ResponseCode'] == '200') {
            return {
              'success': true,
              'data': data,
              'message': responseInfo['ResponseMessage'] ?? 'Balance retrieved successfully'
            };
          }
        }
        
        return {
          'success': false,
          'data': null,
          'message': 'Invalid response format'
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error getting ledger balance: $e');
      return {
        'success': false,
        'data': null,
        'message': 'Failed to get balance: $e'
      };
    }
  }

  // Get Member Details By ContactID
  static Future<Map<String, dynamic>> getMemberByID(String email, String tokenCode, String contactID,String requestedByContactID) async {
    try {
      print('Getting member details for ContactID: $contactID');
      
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestGetMemberByID/000001');

      final response = await http.get(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
          'RequestedByContactID': requestedByContactID,
          'ContactID': contactID,
        },
      ).timeout(_timeout);

      print('Member Details Response Status: ${response.statusCode}');
      print('Member Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response structure is valid
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final responseItem = responseList.first;
            final responseCode = responseItem['ResponseCode']?.toString() ?? '';
            
            if (responseCode == '200') {
              // Extract member details and recent ledger
              final memberDetails = responseData['memberDetail'] as List? ?? [];
              final recentLedger = responseData['recentLedger'] as List? ?? [];
              
              return {
                'success': true,
                'memberDetail': memberDetails,
                'recentLedger': recentLedger, // Include recent ledger data
                'message': responseItem['ResponseMessage'] ?? 'Member details retrieved successfully',
              };
            } else {
              return {
                'success': false,
                'memberDetail': [],
                'recentLedger': [], // Include empty recent ledger for consistency
                'message': responseItem['ResponseMessage'] ?? 'Failed to retrieve member details',
              };
            }
          }
        }
        
        return {
          'success': false,
          'memberDetail': [],
          'message': 'Invalid response format',
        };
      } else {
        return {
          'success': false,
          'memberDetail': [],
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'memberDetail': [],
        'message': 'No internet connection',
      };
    } on http.ClientException {
      return {
        'success': false,
        'memberDetail': [],
        'message': 'Network error occurred',
      };
    } catch (e) {
      print('Error getting member details: $e');
      return {
        'success': false,
        'memberDetail': [],
        'message': 'Failed to get member details: $e',
      };
    }
  }

  // Update Member Password/Passcode
  static Future<Map<String, dynamic>> updateMemberPassword({
    required String email,
    required String tokenCode,
    required String contactID,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('Updating member password for ContactID: $contactID');
      
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestUpdateMemberPassword/000001');

      final requestBody = {
        'OldPassword': oldPassword,
        'NewPassWord': newPassword,
        'ContactID': contactID,
      };

      print('Update Password Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      print('Update Password Response Status: ${response.statusCode}');
      print('Update Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response structure is valid
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final responseItem = responseList.first;
            final responseCode = responseItem['ResponseCode']?.toString() ?? '';
            final responseMessage = responseItem['ResponseMessage']?.toString() ?? '';
            
            if (responseCode == '200') {
              return {
                'success': true,
                'message': responseMessage,
              };
            } else {
              return {
                'success': false,
                'message': responseMessage.isNotEmpty ? responseMessage : 'Failed to update password',
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    } catch (e) {
      print('Error updating member password: $e');
      return {
        'success': false,
        'message': 'Failed to update password: $e',
      };
    }
  }

  // Send Amount To Member API
  static Future<Map<String, dynamic>> sendAmountToMember({
    required String email,
    required String tokenCode,
    required String senderContactID,
    required String receiverContactID,
    required String amount,
    required String remarks,
  }) async {
    try {
      print('Sending amount: $amount from $senderContactID to $receiverContactID');
      
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestSendAmountToMember/000001');

      final body = {
        'SenderContactID': senderContactID,
        'ReceiverContactID': receiverContactID,
        'Amount': amount,
        'Remarks': remarks,
      };

      print('Send money request body: $body');

      final response = await http.post(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      print('Send money response status: ${response.statusCode}');
      print('Send money response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response structure is valid
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final responseItem = responseList.first;
            final responseCode = responseItem['ResponseCode']?.toString() ?? '';
            
            if (responseCode == '200') {
              // Extract transaction details
              final tranDetails = responseData['TranDetails'] as List? ?? [];
              
              return {
                'success': true,
                'message': responseItem['ResponseMessage'] ?? 'Transaction successfully completed',
                'tranDetails': tranDetails,
                'voucherNumber': tranDetails.isNotEmpty ? tranDetails.first['VoucherNumber'] : '',
                'voucherID': tranDetails.isNotEmpty ? tranDetails.first['VoucherID'] : '',
                'voucherDate': tranDetails.isNotEmpty ? tranDetails.first['VoucherDate'] : '',
                'transactionAmount': tranDetails.isNotEmpty ? tranDetails.first['Amount'] : 0.0,
              };
            } else {
              return {
                'success': false,
                'message': responseItem['ResponseMessage'] ?? 'Transaction failed',
                'responseCode': responseCode,
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('Error sending amount: $e');
      return {
        'success': false,
        'message': 'Failed to send amount: $e',
      };
    }
  }

  // Get Ledger Summary API
  static Future<Map<String, dynamic>> getLedgerSummary(String email, String tokenCode, String contactID) async {
    try {
      print('Getting ledger summary for user: $email');
      print('Using ContactID: $contactID');
      
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestGetLedgerSummary/000001');

      final response = await http.get(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
          'ContactID': contactID,
        },
      ).timeout(_timeout);

      print('Ledger summary response status: ${response.statusCode}');
      print('Ledger summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response structure is valid
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final responseItem = responseList.first;
            final responseCode = responseItem['ResponseCode']?.toString() ?? '';
            
            if (responseCode == '200') {
              // Extract ledger summary
              final ledgerSummary = responseData['Ledgersummary'] as List? ?? [];
              
              return {
                'success': true,
                'message': responseItem['ResponseMessage'] ?? 'Ledger summary retrieved successfully',
                'ledgerSummary': ledgerSummary,
                'count': ledgerSummary.length,
              };
            } else {
              return {
                'success': false,
                'message': responseItem['ResponseMessage'] ?? 'Failed to retrieve ledger summary',
                'ledgerSummary': [],
                'count': 0,
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'ledgerSummary': [],
          'count': 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'ledgerSummary': [],
          'count': 0,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'ledgerSummary': [],
        'count': 0,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
        'ledgerSummary': [],
        'count': 0,
      };
    } catch (e) {
      print('Error getting ledger summary: $e');
      return {
        'success': false,
        'message': 'Failed to get ledger summary: $e',
        'ledgerSummary': [],
        'count': 0,
      };
    }
  }

  // Get Member Details by ContactID (for QR Code scanning)
  static Future<Map<String, dynamic>> getMemberByContactID({
    required String email,
    required String tokenCode,
    required String contactID,
  }) async {
    try {
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestGetMemberByID/000001');
      
      final response = await http.get(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
          'ContactID': contactID,
        },
      ).timeout(_timeout);

      print('Get Member Response Status: ${response.statusCode}');
      print('Get Member Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if we have member details and response
        if (responseData['memberDetail'] != null && 
            responseData['RESPONSE'] != null &&
            responseData['RESPONSE'].isNotEmpty) {
          
          final responseInfo = responseData['RESPONSE'][0];
          
          if (responseInfo['ResponseCode'] == '200') {
            final memberDetails = responseData['memberDetail'];
            
            if (memberDetails.isNotEmpty) {
              final member = memberDetails[0];
              return {
                'success': true,
                'member': {
                  'name': member['Name'] ?? '',
                  'mobile': member['Mobile'] ?? '',
                  'joiningDate': member['Joiningdate'] ?? '',
                  'imageUrl': member['ImageUrl'],
                  'contactID': member['ContactID'] ?? '',
                },
                'message': responseInfo['ResponseMessage'] ?? 'Member found successfully',
              };
            } else {
              return {
                'success': false,
                'message': 'No member details found',
              };
            }
          } else {
            return {
              'success': false,
              'message': responseInfo['ResponseMessage'] ?? 'Failed to get member details',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('Error getting member details: $e');
      return {
        'success': false,
        'message': 'Failed to get member details: $e',
      };
    }
  }

  // Update Member Profile
  static Future<Map<String, dynamic>> updateMemberProfile({
    required String email,
    required String tokenCode,
    required String contactID,
    required String contactName,
    required String contEmail,
    required String phoneTelNo,
    required String gender,
    required String dateOfBirth,
    required String contAddDetails,
    required String occupation,
  }) async {
    try {
      print('=== Update Profile API Call ===');
      print('URL: https://api.v2cbazar.com/api/Response/RequestUpdateMemberProfile/000001');
      print('ContactID: $contactID');
      print('ContactName: $contactName');
      print('Email: $contEmail');
      print('Phone: $phoneTelNo');
      print('Gender: $gender');
      print('DateOfBirth: $dateOfBirth');
      print('Address: $contAddDetails');
      print('Occupation: $occupation');
      
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/RequestUpdateMemberProfile/000001');
      
      final body = {
        "ContactID": contactID,
        "ContactName": contactName,
        "ContEMail": contEmail,
        "PhoneTelNo": phoneTelNo,
        "Gender": gender,
        "DateOfBirth": dateOfBirth,
        "ContAddDetails": contAddDetails,
        "Occupation": occupation,
      };
      
      print('Request Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'V2CBAZAR',
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      print('Update Profile Response Status: ${response.statusCode}');
      print('Update Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['RESPONSE'] != null && responseData['RESPONSE'].isNotEmpty) {
          final responseItem = responseData['RESPONSE'][0];
          final responseCode = responseItem['ResponseCode']?.toString() ?? '';
          final responseMessage = responseItem['ResponseMessage']?.toString() ?? '';
          
          if (responseCode == '200') {
            return {
              'success': true,
              'message': responseMessage,
              'responseCode': responseCode,
            };
          } else {
            return {
              'success': false,
              'message': responseMessage.isNotEmpty ? responseMessage : 'Failed to update profile',
              'responseCode': responseCode,
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      print('Update profile timeout');
      return {
        'success': false,
        'message': 'Request timeout. Please try again.',
      };
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  // Get Multiple Account List For Member
  static Future<Map<String, dynamic>> getMultipleAccountListForMember({
    required String email,
    required String tokenCode,
    required String phoneNumber,
  }) async {
    try {
      final uri = Uri.parse('https://api.v2cbazar.com/api/Response/ProcessGetMultipleAccountListForMember/000001');

      print('=== GET MULTIPLE ACCOUNT LIST API ===');
      print('URL: $uri');
      print('Email: $email');
      print('TokenCode: $tokenCode');
      print('PhoneNumber: $phoneNumber');

      final response = await http.get(
        uri,
        headers: {
          'Email': email,
          'TokenCode': tokenCode,
          'Content-Type': 'application/json',
          'CCode': 'JAIKISAN',
          'PhoneNumber': phoneNumber,
        },
      ).timeout(_timeout);

      print('Multiple Account List Response Status: ${response.statusCode}');
      print('Multiple Account List Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if response has the expected structure
        if (responseData.containsKey('RESPONSE') && responseData['RESPONSE'] is List) {
          final responseList = responseData['RESPONSE'] as List;
          if (responseList.isNotEmpty) {
            final firstResponse = responseList[0];
            
            if (firstResponse['ResponseCode'] == '200' || firstResponse['IsSuccess'] == true) {
              print('=== API Parsing Debug ===');
              print('Response has MemberList: ${responseData.containsKey('MemberList')}');
              print('MemberList is List: ${responseData['MemberList'] is List}');
              
              // Extract member list from the actual API response structure
              final memberList = responseData.containsKey('MemberList') && responseData['MemberList'] is List 
                  ? responseData['MemberList'] as List
                  : [];
              
              print('Found ${memberList.length} members in MemberList');
              print('Raw MemberList: $memberList');
              
              final mappedAccounts = memberList.map((member) => {
                // Map the member data to match expected user selection screen format
                'Name': member['ContactName'] ?? '',
                'ContactID': member['ContactID'] ?? '',
                'ContactNumber': member['ContactNumber'] ?? '',
                'APIUserName': member['APIUserName'] ?? '',
                // Keep original fields as well
                ...member as Map<String, dynamic>,
              }).toList();
              
              print('Mapped accounts count: ${mappedAccounts.length}');
              print('First mapped account: ${mappedAccounts.isNotEmpty ? mappedAccounts[0] : 'None'}');
              print('========================');
              
              return {
                'success': true,
                'message': firstResponse['ResponseMessage'] ?? 'Account list retrieved successfully',
                'accountCount': memberList.length,
                'accounts': mappedAccounts,
                'rawData': responseData,
              };
            } else {
              return {
                'success': false,
                'message': firstResponse['ResponseMessage'] ?? 'Failed to get account list',
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'Invalid response format',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error getting multiple account list: $e');
      return {
        'success': false,
        'message': 'Failed to get account list: ${e.toString()}',
      };
    }
  }
  // Get User Notification Topics
  static Future<List<String>> getUserTopics({
    required String email,
    required String tokenCode,
    required String contactID,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://api.v2cbazar.com/api/Response/RequestGetUserTopics/000001"),
        headers: {
          "Email": email,
          "TokenCode": tokenCode,
          "ContactID": contactID,
          "Content-Type": "application/json",
          "CCode": "V2CBAZAR",
        },
      );

      if (response.statusCode == 200) {

        final jsonData = jsonDecode(response.body);

        List<String> topics = [];

        if (jsonData["topics"] != null) {

          for (var item in jsonData["topics"]) {

            topics.add(item["NotificactionCode"]);

          }

        }

        print("Topics : $topics");

        return topics;
      }

      return [];

    } catch (e) {

      print(e);

      return [];

    }
  }
}
