import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/twilio_service.dart';
import '../../services/email_otp_service.dart';
import '../../services/device_email_service.dart';
import '../../services/v2c_auth_api_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import 'user_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  int _resendTimer = 30;
  bool _isEmailLogin = false; // Default to mobile login
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Sample email addresses (in production, these would come from device contacts or saved accounts)
  List<String> _deviceEmails = [];
  bool _isLoadingEmails = false;
  final DeviceEmailService _emailService = DeviceEmailService();

  void _showEmailSuggestionDialog() async {
    // Load device emails if not already loaded
    if (_deviceEmails.isEmpty && !_isLoadingEmails) {
      setState(() {
        _isLoadingEmails = true;
      });
      
      _deviceEmails = await _emailService.getDeviceEmails();
      
      // Log Google accounts found
      final googleAccounts = _deviceEmails.where((email) => email.toLowerCase().contains('@gmail.com')).toList();
      if (kDebugMode) {
        print('Google accounts detected: ${googleAccounts.length}');
        for (String account in googleAccounts) {
          print('  - $account');
        }
      }
      
      setState(() {
        _isLoadingEmails = false;
      });
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Permissions banner when no emails found
            if (_deviceEmails.isEmpty && !_isLoadingEmails)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Access Your Device Accounts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Grant permissions to see your saved email accounts and make login easier',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              setState(() {
                                _isLoadingEmails = true;
                              });
                              
                              try {
                                final contactsGranted = await _emailService.requestContactsPermission();
                                final accountsGranted = await _emailService.requestAccountsPermission();
                                
                                if (contactsGranted || accountsGranted) {
                                  _emailService.clearCache();
                                  _deviceEmails = await _emailService.getDeviceEmails();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Permissions granted! Loading your accounts...'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Permissions denied. You can still type your email manually.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoadingEmails = false;
                                  });
                                }
                              }
                            },
                            icon: const Icon(Icons.security, size: 16),
                            label: const Text('Grant Permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF00BCD4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Email Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Google accounts shown first',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      setState(() {
                        _isLoadingEmails = true;
                      });
                      
                      // Request both permissions
                      await _emailService.requestContactsPermission();
                      await _emailService.requestAccountsPermission();
                      
                      _emailService.clearCache();
                      _deviceEmails = await _emailService.getDeviceEmails();
                      
                      setState(() {
                        _isLoadingEmails = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingEmails
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                          ),
                          SizedBox(height: 16),
                          Text('Loading email accounts...'),
                        ],
                      ),
                    )
                  : _deviceEmails.isEmpty
                      ? SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Email Accounts Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No email addresses were found in your device contacts.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'To use email suggestions:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF00BCD4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '• Grant contacts permission for saved email addresses\n• Grant accounts permission for device accounts (Google, etc.)\n• Or type your email manually',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final granted = await _emailService.requestContactsPermission();
                                                if (granted) {
                                                  _emailService.clearCache();
                                                  _deviceEmails = await _emailService.getDeviceEmails();
                                                  setState(() {});
                                                }
                                              },
                                              icon: const Icon(Icons.contacts, size: 16),
                                              label: const Text('Contacts', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF00BCD4),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                setState(() {
                                                  _isLoadingEmails = true;
                                                });
                                                
                                                try {
                                                  final granted = await _emailService.requestAccountsPermission();
                                                  if (granted) {
                                                    _emailService.clearCache();
                                                    _deviceEmails = await _emailService.getDeviceEmails();
                                                    if (mounted) {
                                                      setState(() {});
                                                      
                                                      // Show success message
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Accounts permission granted! Refreshing email list...'),
                                                          backgroundColor: Colors.green,
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    // Show permission denied message
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Accounts permission denied. You can still type your email manually.'),
                                                          backgroundColor: Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  // Show error message
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Error requesting permission: $e'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isLoadingEmails = false;
                                                    });
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.account_circle, size: 16),
                                              label: const Text('Accounts', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Row(
                                        children: [
                                          Expanded(child: Divider()),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          ),
                                          Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              final email = await _emailService.showGoogleAccountPicker();
                                              if (email != null) {
                                                _emailController.text = email;
                                                Navigator.pop(context);
                                                
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Selected: $email'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'G',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          label: const Text('Choose Google Account'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Close and type email manually',
                                    style: TextStyle(
                                      color: Color(0xFF00BCD4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _deviceEmails.length,
                          itemBuilder: (context, index) {
                            final email = _deviceEmails[index];
                            final isValidEmail = email.contains('@') && !email.startsWith('No ');
                            final isGoogleAccount = email.toLowerCase().contains('@gmail.com');
                            final accountType = isValidEmail ? _emailService.getAccountType(email) : 'Permission required';
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isGoogleAccount 
                                    ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
                                    : Border.all(color: Colors.grey.withOpacity(0.2)),
                                color: isGoogleAccount 
                                    ? Colors.red.withOpacity(0.05)
                                    : Colors.transparent,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isValidEmail 
                                      ? (isGoogleAccount ? Colors.red : const Color(0xFF00BCD4))
                                      : Colors.orange,
                                  child: isGoogleAccount
                                      ? const Text(
                                          'G',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Icon(
                                          isValidEmail ? Icons.email : Icons.warning,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: TextStyle(
                                          color: isValidEmail ? Colors.black : Colors.orange,
                                          fontWeight: isGoogleAccount ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isGoogleAccount)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Google',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  accountType,
                                  style: TextStyle(
                                    color: isValidEmail 
                                        ? (isGoogleAccount ? Colors.red : Colors.grey)
                                        : Colors.orange,
                                    fontWeight: isGoogleAccount ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                onTap: isValidEmail ? () {
                                  _emailController.text = email;
                                  Navigator.pop(context);
                                } : () async {
                                  // Request permission
                                  final granted = await _emailService.requestContactsPermission();
                                  if (granted) {
                                    Navigator.pop(context);
                                    _showEmailSuggestionDialog();
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  // Send email OTP using the real API service
  Future<Map<String, dynamic>> _sendEmailOtp(String email) async {
    return await EmailOTPService.sendOTP(email);
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Use TwilioSmsService for production SMS sending or email service for email
    Map<String, dynamic> result;
    
    if (_isEmailLogin) {
      // For email OTP, we'll simulate the same response structure
      // In a real implementation, you would integrate with an email service
      result = await _sendEmailOtp(_emailController.text);
    } else {
      // Phone/Mobile login using V2C API
      String phoneNumber = _phoneController.text.trim();
      
      // Validate phone number format
      if (!V2CAuthApiService.isValidPhoneNumber(phoneNumber)) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
        return;
      }
      
      // Send OTP using V2C API
      result = await V2CAuthApiService.sendPhoneOTP(phoneNumber);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isOtpSent = result['success'];
      });
      
      if (result['success']) {
        _startResendTimer();
        
        // Simple success message without showing OTP
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_isEmailLogin ? 'email' : 'mobile number'} successfully!'),
            backgroundColor: const Color(0xFF00BCD4),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Handle different types of errors
        String errorMessage = result['message'] ?? 'Failed to send OTP. Please try again.';
        
        // Provide specific guidance for API errors
        if (errorMessage.contains('405') || errorMessage.contains('Method')) {
          errorMessage = 'Service temporarily unavailable. Please try again later.';
        } else if (errorMessage.contains('Network') || errorMessage.contains('internet')) {
          errorMessage = 'Please check your internet connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 4-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isVerifying = true;
    });
    
    // Verify OTP
    bool isValid;
    Map<String, dynamic>? loginData;
    Map<String, dynamic>? verificationResult;
    
    if (_isEmailLogin) {
      // Verify email OTP using API
      verificationResult = await EmailOTPService.verifyOTP(_emailController.text, _otpController.text);
      isValid = verificationResult['success'];
      loginData = verificationResult;
    } else {
      // Verify phone OTP using V2C API
      String phoneNumber = _phoneController.text.trim();
      verificationResult = await V2CAuthApiService.validatePhoneOTPLogin(phoneNumber, _otpController.text);
      isValid = verificationResult['success'];
      loginData = verificationResult;
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      
      if (isValid) {
        // Debug logging
        print('=== LOGIN DEBUG ===');
        print('verificationResult keys: ${verificationResult.keys}');
        print('multipleUsers: ${verificationResult['multipleUsers']}');
        print('userCount: ${verificationResult['userCount']}');
        if (verificationResult.containsKey('users')) {
          print('users length: ${(verificationResult['users'] as List?)?.length ?? 0}');
        }
        print('==================');
        
        // Check if multiple users were returned
        if (verificationResult['multipleUsers'] == true) {
          // Get the first user's credentials to call the ProcessGetMultipleAccountListForMember API
          final users = verificationResult['users'] as List<dynamic>;
          final userList = users.map((user) => user as Map<String, dynamic>).toList();
          
          print('Multiple users detected, calling ProcessGetMultipleAccountListForMember API');
          
          if (userList.isNotEmpty) {
            try {
              final firstUser = userList[0];
              final email = firstUser['email'] ?? firstUser['Email'] ?? '';
              final tokenCode = firstUser['tokenCode'] ?? firstUser['TokenCode'] ?? '';
              final phoneNumber = _isEmailLogin ? _phoneController.text.trim() : _phoneController.text.trim();
              
              // Call the ProcessGetMultipleAccountListForMember API
              final accountListResult = await ApiService.getMultipleAccountListForMember(
                email: email,
                tokenCode: tokenCode,
                phoneNumber: phoneNumber,
              );
              
              print('=== ProcessGetMultipleAccountListForMember API Result ===');
              print('Success: ${accountListResult['success']}');
              print('Has accounts: ${accountListResult['accounts'] != null}');
              if (accountListResult['accounts'] != null) {
                print('Accounts count: ${(accountListResult['accounts'] as List).length}');
                print('First account: ${(accountListResult['accounts'] as List).isNotEmpty ? (accountListResult['accounts'] as List)[0] : 'No accounts'}');
              }
              print('Full result: $accountListResult');
              print('=========================================');
              
              if (accountListResult['success'] == true && accountListResult['accounts'] != null) {
                final accounts = accountListResult['accounts'] as List<dynamic>;
                print('Found ${accounts.length} accounts from ProcessGetMultipleAccountListForMember API');
                
                if (accounts.isNotEmpty) {
                  // Use accounts from the new API
                  final accountList = accounts.map((account) => account as Map<String, dynamic>).toList();
                  
                  print('=== Navigating to UserSelectionScreen with API data ===');
                  print('Account list length: ${accountList.length}');
                  print('First account data: ${accountList.isNotEmpty ? accountList[0] : 'Empty'}');
                  print('Original email: $email');
                  print('Original tokenCode: $tokenCode');
                  print('================================================');
                  
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserSelectionScreen(
                          users: accountList,
                          loginType: _isEmailLogin ? 'email' : 'phone',
                          originalEmail: email,
                          originalTokenCode: tokenCode,
                          originalLoginData: firstUser,
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              
              // Fallback to original login data if API fails or returns no accounts
              print('ProcessGetMultipleAccountListForMember API failed or returned no accounts, using fallback data');
            } catch (e) {
              print('Error calling ProcessGetMultipleAccountListForMember API: $e');
            }
          }
          
          // Fallback: Navigate with original user data
          print('Using fallback: Navigating to user selection screen with ${userList.length} users from login data');
          
          if (mounted) {
            // For fallback, the original user data should have email and tokenCode
            final fallbackEmail = userList.isNotEmpty ? (userList[0]['email'] ?? userList[0]['Email'] ?? '') : '';
            final fallbackTokenCode = userList.isNotEmpty ? (userList[0]['tokenCode'] ?? userList[0]['TokenCode'] ?? '') : '';
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserSelectionScreen(
                  users: userList,
                  loginType: _isEmailLogin ? 'email' : 'phone',
                  originalEmail: fallbackEmail,
                  originalTokenCode: fallbackTokenCode,
                  originalLoginData: userList.isNotEmpty ? userList[0] : null,
                ),
              ),
            );
          }
          return;
        }
        
        // Single user or fallback - proceed with normal login
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (_isEmailLogin) {
          // For email login with API data - extract profile data
          print('=== Email Login API Debug ===');
          print('Name from API: ${loginData['Name']}');
          print('Mobile from API: ${loginData['Mobile']}');
          print('Gender from API: ${loginData['Gender']}');
          print('Address from API: ${loginData['Address']}');
          print('DateofBirth from API: ${loginData['DateofBirth']}');
          print('======================');
          
          // Create profile data map from API response
          final profileData = {
            'Name': loginData['Name'] ?? '',
            'email': loginData['email'] ?? _emailController.text,
            'Mobile': loginData['Mobile'] ?? '',
            'Gender': loginData['Gender'] ?? '',
            'DateofBirth': loginData['DateofBirth'] ?? '',
            'Address': loginData['Address'] ?? '',
            'CardNo': loginData['CardNo'] ?? '',
            'ContactID': loginData['ContactID'] ?? '',
            'tokenCode': loginData['tokenCode'] ?? '',
            'latitude': loginData['latitude'] ?? '',
            'longitude': loginData['longitude'] ?? '',
            'buildingRadius': loginData['buildingRadius'] ?? '',
          };
          
          print('=== Email Profile Data to Store ===');
          print('Profile Data: $profileData');
          print('============================');
          
          await authProvider.loginWithEmailData(
            _emailController.text,
            loginData['Name'] ?? 'User',
            loginData['tokenCode'] ?? '',
            additionalData: profileData,
          );
          
          // Debug: Verify data was saved
          final savedData = await authProvider.getApiProfileData();
          print('=== Email Login Verification ===');
          print('Data saved successfully: ${savedData != null}');
          if (savedData != null) {
            print('Saved data keys: ${savedData.keys.toList()}');
          }
          print('==========================');
        } else if (!_isEmailLogin) {
          // For V2C API phone login - use loginDetails from the response
          final phoneLoginData = loginData['loginDetails'] ?? {};
          print('=== V2C API Login Debug ===');
          print('Login Details: $phoneLoginData');
          print('TokenCode: ${loginData['TokenCode']}');
          print('Name: ${loginData['Name']}');
          print('Mobile: ${loginData['Mobile']}');
          print('Email: ${loginData['Email']}');
          print('Address: ${loginData['Address']}');
          print('CardNo: ${loginData['CardNo']}');
          print('ContactID: ${loginData['ContactID']}');
          print('============================');
          
          await authProvider.loginWithV2CApiData(loginData);
          
          // Debug: Verify data was saved
          final savedData = await authProvider.getApiProfileData();
          print('=== V2C Login Verification ===');
          print('Data saved successfully: ${savedData != null}');
          if (savedData != null) {
            print('Saved data keys: ${savedData.keys.toList()}');
          }
          print('==============================');
        } else if (_isEmailLogin) {
          await authProvider.loginWithEmail(_emailController.text);
        } else {
          await authProvider.loginWithPhone(_phoneController.text);
        }
        
        // Navigate to home screen
        context.go('/home');
      } else {
        String errorMessage;
        
        if (_isEmailLogin) {
          errorMessage = loginData['message'] ?? 'Invalid OTP. Please check the code and try again.';
        } else if (!_isEmailLogin) {
          errorMessage = verificationResult['message'] ?? 'Invalid OTP. Please check the code and try again.';
        } else {
          errorMessage = 'Invalid OTP. Please check the code and try again.';
        }
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _otpController.clear();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Clear previous OTP and send new one
    Map<String, dynamic> result;
    
    if (_isEmailLogin) {
      EmailOTPService.clearOTP(_emailController.text);
      result = await EmailOTPService.sendOTP(_emailController.text);
    } else {
      TwilioSmsService.clearOtp(_phoneController.text);
      result = await TwilioSmsService.sendOtp(_phoneController.text);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        _startResendTimer();
        
        // Show simple success message (hide OTP for production)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP resent to ${_isEmailLogin ? 'email' : 'phone'} successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _openRegisterUrl() async {
    final Uri url = Uri.parse('https://jaikisancards.in/register/register.html');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open register page. Please try again later.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening register page: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo and App Name
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.payment,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Jaikisan Card',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isOtpSent 
                                    ? 'Verify your ${_isEmailLogin ? 'email' : 'phone number'}' 
                                    : 'Welcome back! Please sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 50),
                          
                          if (!_isOtpSent) ...[
                            // Login Method Toggle
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isEmailLogin = true;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: _isEmailLogin ? const Color(0xFF00BCD4) : Colors.transparent,
                                        ),
                                        child: Text(
                                          'Email',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _isEmailLogin ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isEmailLogin = false;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: !_isEmailLogin ? const Color(0xFF00BCD4) : Colors.transparent,
                                        ),
                                        child: Text(
                                          'Phone',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: !_isEmailLogin ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Input Field
                            Text(
                              _isEmailLogin ? 'Email Address' : 'Phone Number',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _isEmailLogin ? _emailController : _phoneController,
                                keyboardType: _isEmailLogin ? TextInputType.emailAddress : TextInputType.phone,
                                onTap: _isEmailLogin ? _showEmailSuggestionDialog : null,
                                inputFormatters: _isEmailLogin ? null : [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  hintText: _isEmailLogin ? 'Enter your email address' : 'Enter your phone number',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: _isEmailLogin 
                                    ? Icon(Icons.email_outlined, color: const Color(0xFF00BCD4))
                                    : Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          '+91',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF00BCD4),
                                          ),
                                        ),
                                      ),
                                  suffixIcon: _isEmailLogin 
                                    ? Icon(Icons.arrow_drop_down, color: const Color(0xFF00BCD4))
                                    : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _isEmailLogin 
                                      ? 'Please enter your email address' 
                                      : 'Please enter your mobile number';
                                  }
                                  if (_isEmailLogin) {
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                  } else {
                                    // Use V2C API validation for phone numbers
                                    if (!V2CAuthApiService.isValidPhoneNumber(value)) {
                                      return 'Please enter a valid 10-digit mobile number starting with 6, 7, 8, or 9';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Send OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BCD4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF00BCD4).withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Register Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _openRegisterUrl,
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00BCD4),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // OTP Input
                            const Text(
                              'Enter OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEmailLogin 
                                ? 'We\'ve sent a 6-digit code to ${_emailController.text}'
                                : 'We\'ve sent a 6-digit code to +91 ${_phoneController.text}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: InputDecoration(
                                  hintText: '0000',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 24,
                                    letterSpacing: 8,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Resend OTP
                            Center(
                              child: TextButton(
                                onPressed: _resendTimer > 0 ? null : _resendOtp,
                                child: Text(
                                  _resendTimer > 0
                                      ? 'Resend OTP in ${_resendTimer}s'
                                      : 'Resend OTP',
                                  style: TextStyle(
                                    color: _resendTimer > 0
                                        ? Colors.grey[500]
                                        : const Color(0xFF00BCD4),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Verify OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BCD4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF00BCD4).withOpacity(0.4),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Verify & Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Change Number/Email
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: Text(
                                  _isEmailLogin ? 'Change Email Address' : 'Change Phone Number',
                                  style: const TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 40),
                          
                          // Terms and Privacy
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'By continuing, you agree to our Terms of Service and Privacy Policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
