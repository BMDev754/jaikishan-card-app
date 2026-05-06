import 'dart:math';

class TwilioSmsService {
  // NOTE: For development purposes, we're using a mock service
  // In production, you would need valid Twilio credentials and phone number
  static const String accountSid = 'AC7537d4a4f0d8f9a65efdc8093d7ca239';
  static const String authToken = '495ea61c74a9e9786ff41640a12b155b';
  static const String twilioPhoneNumber = '8455943905'; // This is invalid - need real Twilio number
  
  // Base URL for Twilio API
  static const String baseUrl = 'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json';
  
  // Store OTPs temporarily (in production, use a proper database)
  static final Map<String, String> _otpStorage = {};
  
  /// Generate a 6-digit OTP
  static String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  /// Send OTP via mock SMS service (for development)
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Generate OTP
      final otp = _generateOtp();
      
      // Store OTP for verification
      _otpStorage[phoneNumber] = otp;
      
      // For development: Print OTP to console instead of sending SMS
      print('🔐 DEVELOPMENT MODE - OTP for $phoneNumber: $otp');
      print('📱 In production, this would be sent via SMS to +91$phoneNumber');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Return success with OTP for development
      return {
        'success': true,
        'otp': otp,
        'message': 'OTP sent successfully'
      };
      
    } catch (e) {
      print('Error in mock SMS service: $e');
      return {
        'success': false,
        'otp': null,
        'message': 'Failed to send OTP'
      };
    }
  }
  
  /// Verify OTP
  static bool verifyOtp(String phoneNumber, String enteredOtp) {
    final storedOtp = _otpStorage[phoneNumber];
    
    if (storedOtp == null) {
      print('No OTP found for phone number: $phoneNumber');
      return false;
    }
    
    if (storedOtp == enteredOtp) {
      // Remove OTP after successful verification
      _otpStorage.remove(phoneNumber);
      print('OTP verified successfully for $phoneNumber');
      return true;
    } else {
      print('Invalid OTP for $phoneNumber');
      return false;
    }
  }
  
  /// Clear stored OTP (for resend functionality)
  static void clearOtp(String phoneNumber) {
    _otpStorage.remove(phoneNumber);
  }
  
  /// Check if OTP exists for a phone number
  static bool hasOtp(String phoneNumber) {
    return _otpStorage.containsKey(phoneNumber);
  }
}

// Mock service for development/testing without actual Twilio integration
class MockSmsService {
  static final Map<String, String> _otpStorage = {};
  
  /// Generate a 6-digit OTP
  static String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  /// Send OTP (mock implementation)
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate and store OTP
      final otp = _generateOtp();
      _otpStorage[phoneNumber] = otp;
      
      // Print OTP to console for testing (remove in production)
      print('📱 SMS to +91$phoneNumber: Your Jaikisan Card verification code is: $otp');
      
      return {
        'success': true,
        'otp': otp,
        'message': 'OTP sent successfully'
      };
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'otp': null,
        'message': 'Failed to send OTP'
      };
    }
  }
  
  /// Verify OTP
  static bool verifyOtp(String phoneNumber, String enteredOtp) {
    final storedOtp = _otpStorage[phoneNumber];
    
    if (storedOtp == null) {
      print('No OTP found for phone number: $phoneNumber');
      return false;
    }
    
    if (storedOtp == enteredOtp) {
      // Remove OTP after successful verification
      _otpStorage.remove(phoneNumber);
      print('✅ OTP verified successfully for $phoneNumber');
      return true;
    } else {
      print('❌ Invalid OTP for $phoneNumber. Expected: $storedOtp, Got: $enteredOtp');
      return false;
    }
  }
  
  /// Clear stored OTP
  static void clearOtp(String phoneNumber) {
    _otpStorage.remove(phoneNumber);
  }
  
  /// Get stored OTP for testing purposes
  static String? getStoredOtp(String phoneNumber) {
    return _otpStorage[phoneNumber];
  }
}
