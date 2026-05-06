import 'api/api_service.dart';

class EmailOTPService {
  // Storage for OTP verification (temporary - in production use secure storage)
  static final Map<String, String> _storedOTPs = {};
  static final Map<String, DateTime> _otpTimestamps = {};
  static const Duration _otpValidityDuration = Duration(minutes: 5);

  /// Send OTP to email address
  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      // Call the API to send OTP
      final result = await ApiService.sendEmailOTP(email);
      
      if (result['success']) {
        // Store OTP and timestamp for validation
        final otp = result['otp'] ?? '';
        if (otp.isNotEmpty) {
          _storedOTPs[email] = otp;
          _otpTimestamps[email] = DateTime.now();
        }
        
        return {
          'success': true,
          'otp': otp, // For development - remove in production
          'message': result['message'] ?? 'OTP sent successfully',
        };
      } else {
        // If API fails, use fallback for development
        if (result['message']?.contains('405') == true || 
            result['message']?.contains('Method') == true) {
          return _sendOTPFallback(email);
        }
        
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      // Use fallback for development
      return _sendOTPFallback(email);
    }
  }

  /// Fallback OTP generation for development/testing
  static Future<Map<String, dynamic>> _sendOTPFallback(String email) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate random 6-digit OTP
    final otp = (100000 + (999999 - 100000) * (DateTime.now().millisecondsSinceEpoch % 900000) / 900000).floor().toString();
    
    // Store OTP for verification
    _storedOTPs[email] = otp;
    _otpTimestamps[email] = DateTime.now();
    
    return {
      'success': true,
      'otp': otp,
      'message': 'OTP sent successfully (Development Mode - API issue detected)',
    };
  }

  /// Verify OTP for email address
  static Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      // First check if OTP exists locally (for fallback mode)
      if (_storedOTPs.containsKey(email)) {
        final timestamp = _otpTimestamps[email];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) > _otpValidityDuration) {
          // OTP expired
          _storedOTPs.remove(email);
          _otpTimestamps.remove(email);
          return {
            'success': false,
            'message': 'OTP has expired. Please request a new one.',
          };
        }

        // Check local OTP first
        if (_storedOTPs[email] == otp) {
          // Clear stored OTP after successful validation
          _storedOTPs.remove(email);
          _otpTimestamps.remove(email);
          
          // Try API validation, but don't fail if API is down
          try {
            final apiResult = await ApiService.validateEmailOTP(email, otp);
            if (apiResult['success']) {
              print('=== EMAIL OTP SERVICE DEBUG ===');
              print('API result keys: ${apiResult.keys}');
              print('multipleUsers: ${apiResult['multipleUsers']}');
              print('==============================');
              return apiResult; // Return API response if successful (may contain multiple users)
            }
          } catch (e) {
            // API failed, but local validation passed
            print('API validation failed, using local validation: $e');
          }
          
          // Return success with fallback data
          return {
            'success': true,
            'message': 'Login successful',
            'userPersonName': 'User', // Fallback name
            'email': email,
            'tokenCode': 'fallback_token_${DateTime.now().millisecondsSinceEpoch}',
            'latitude': '0.0',
            'longitude': '0.0',
            'buildingRadius': '100.0',
          };
        }
      }

      // If no local OTP, try API validation
      final result = await ApiService.validateEmailOTP(email, otp);
      
      print('=== EMAIL OTP SERVICE FINAL DEBUG ===');
      print('Final result keys: ${result.keys}');
      print('Final result success: ${result['success']}');
      print('Final result multipleUsers: ${result['multipleUsers']}');
      print('====================================');
      
      if (result['success']) {
        return result;
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying OTP: ${e.toString()}',
      };
    }
  }

  /// Clear stored OTP for email (for resend functionality)
  static void clearOTP(String email) {
    _storedOTPs.remove(email);
    _otpTimestamps.remove(email);
  }

  /// Check if OTP is valid locally (without API call)
  static bool isOTPValid(String email, String otp) {
    if (!_storedOTPs.containsKey(email)) return false;
    
    final timestamp = _otpTimestamps[email];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) > _otpValidityDuration) {
      // OTP expired
      _storedOTPs.remove(email);
      _otpTimestamps.remove(email);
      return false;
    }
    
    return _storedOTPs[email] == otp;
  }

  /// Get remaining time for OTP validity
  static Duration? getRemainingTime(String email) {
    final timestamp = _otpTimestamps[email];
    if (timestamp == null) return null;
    
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = _otpValidityDuration - elapsed;
    
    return remaining.isNegative ? null : remaining;
  }
}
