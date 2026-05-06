class ApiConfig {
  static const String baseUrl = 'https://api.v2cbazar.com/api/Response';
  static const String contentType = 'application/json';
  static const String cCode = 'V2CBAZAR';
  
  // API Endpoints - Updated to use V2CBAZAR instead of 000001
  static const String processEmailOTP = '/ProcessEmailOTPRequestForMember/V2CBAZAR';
  static const String validateEmailOTP = '/ProcessValidateEmailOTPLoginForMember/V2CBAZAR';

  // Headers - Enhanced with additional headers for better API compatibility
  static Map<String, String> get headers => {
    'Content-Type': contentType,
    'CCode': cCode,
    'Accept': 'application/json',
    'User-Agent': 'JaykisanCard/1.0',
  };
  
  // Complete URLs
  static String get emailOTPUrl => baseUrl + processEmailOTP;
  static String get validateOTPUrl => baseUrl + validateEmailOTP;
  
  // Alternative URLs with CCode in path (in case the server expects it there)
  static String get emailOTPUrlWithCCode => '$baseUrl/ProcessEmailOTPRequestForMember/$cCode';
  static String get validateOTPUrlWithCCode => '$baseUrl/ProcessValidateEmailOTPLoginForMember/$cCode';
}
