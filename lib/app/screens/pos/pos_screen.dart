import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'pos_withdrawal_screen.dart';
import '../transfer/contact_detail_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  late FocusNode _cardNumberFocusNode;
  late TextEditingController _cardNumberController;
  bool _isKeyboardEnabled = false;
  String? _email;
  String? _tokenCode;
  bool _isLoadingCredentials = true;

  @override
  void initState() {
    super.initState();
    _cardNumberFocusNode = FocusNode();
    _cardNumberController = TextEditingController();
    
    // Get credentials from AuthProvider (set during login with OTP verification)
    _getCredentialsFromAuth();
    
    // Auto-focus on the input field when page opens (keyboard OFF by default)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_cardNumberFocusNode);
    });
  }

  @override
  void dispose() {
    _cardNumberFocusNode.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  void _getCredentialsFromAuth() {
    try {
      // Get credentials from AuthProvider (stored during OTP verification in login)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Set email from auth provider
      _email = authProvider.email;
      
      // Get tokenCode asynchronously from storage
      authProvider.getTokenCode().then((tokenCode) {
        if (mounted) {
          setState(() {
            _tokenCode = tokenCode;
            _isLoadingCredentials = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _isLoadingCredentials = false;
          });
        }
      });
      
      // If credentials are not found, show warning
      if (_email == null) {
        if (mounted) {
          _showErrorDialog('Please login first to access POS');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
        _showErrorDialog('Error loading credentials: $e');
      }
    }
  }

  Future<void> _submitCardNumber() async {
    String rfidNumber = _cardNumberController.text.trim();
    
    if (rfidNumber.isEmpty) {
      _showErrorDialog('Please enter RFID number');
      return;
    }

    if (_isLoadingCredentials) {
      _showErrorDialog('Loading credentials, please try again');
      return;
    }

    if (_email == null || _tokenCode == null) {
      _showErrorDialog('Credentials not loaded. Please try again');
      return;
    }

    try {
      print('=== POS API Request Debug ===');
      print('Email: $_email');
      print('TokenCode: $_tokenCode');
      print('RFID Number: $rfidNumber');
      
      // Using GET request with parameters in headers
      final uri = Uri.parse(
        'https://api.v2cbazar.com/api/Response/ProcessGetMemberDetailsByRFIDNo/000001'
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Email': _email!,
          'TokenCode': _tokenCode!,
          'CCode': 'JAIKISAN',
          'RFIDNUM': rfidNumber,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - API server not responding');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          
          print('Response Code from API: ${jsonResponse['RESPONSE']?[0]?['ResponseCode']}');
          print('Response Message: ${jsonResponse['RESPONSE']?[0]?['ResponseMessage']}');
          
          // Check response code from API
          final responseData = jsonResponse['RESPONSE']?[0];
          if (responseData != null) {
            if (responseData['ResponseCode'] == '200') {
              // Success - Check if we have member details
              if (jsonResponse['MemberDetails'] != null && jsonResponse['MemberDetails'].isNotEmpty) {
                final memberData = jsonResponse['MemberDetails'][0];
                print('Member Data: $memberData');
                _showSuccessModal(memberData);
                _cardNumberController.clear();
              } else {
                _showErrorDialog('Member details not found in API response');
              }
            } else if (responseData['ResponseCode'] == '404') {
              // Not found
              _showErrorDialog('RFID Card Not Found\n\n${responseData['ResponseMessage'] ?? 'No member found with this RFID number'}');
            } else {
              // Other error responses
              _showErrorDialog('API Error: ${responseData['ResponseMessage'] ?? 'Operation failed'}\n\nCode: ${responseData['ResponseCode']}');
            }
          } else {
            _showErrorDialog('Invalid API response format - Missing RESPONSE data');
          }
        } catch (parseError) {
          _showErrorDialog('Error parsing API response: $parseError');
          print('Parse Error: $parseError');
        }
      } else if (response.statusCode == 405) {
        _showErrorDialog('Server Error 405: Method Not Allowed\n\nTrying alternative endpoint...');
        print('=== Error 405 - Trying POST instead ===');
        await _submitCardNumberWithPOST(rfidNumber);
      } else if (response.statusCode == 400) {
        _showErrorDialog('Bad Request (400)\n\nPlease check:\n- RFID format is correct\n- Card exists in system');
        print('=== Error 400 Details ===');
        print('Response: ${response.body}');
      } else if (response.statusCode == 401) {
        _showErrorDialog('Authentication Error (401)\n\nCredentials may have expired. Please login again.');
      } else if (response.statusCode == 500) {
        _showErrorDialog('Server Error (500)\n\nThe API server is having issues. Please try again later.');
      } else {
        _showErrorDialog('Server error: ${response.statusCode}\n\n${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
      print('=== Exception Details ===');
      print('Error: $e');
    }
  }

  // Fallback method: Try POST if GET fails with 405
  Future<void> _submitCardNumberWithPOST(String rfidNumber) async {
    try {
      print('=== Trying POST method ===');
      
      final uri = Uri.parse(
        'https://api.v2cbazar.com/api/Response/ProcessGetMemberDetailsByRFIDNo/000001'
      );
      
      final body = {
        'RFIDNUM': rfidNumber,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Email': _email!,
          'TokenCode': _tokenCode!,
          'CCode': 'JAIKISAN',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('POST Request timeout');
        },
      );

      print('POST Response Status: ${response.statusCode}');
      print('POST Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final responseData = jsonResponse['RESPONSE']?[0];
          
          if (responseData != null && responseData['ResponseCode'] == '200') {
            if (jsonResponse['MemberDetails'] != null && jsonResponse['MemberDetails'].isNotEmpty) {
              final memberData = jsonResponse['MemberDetails'][0];
              _showSuccessModal(memberData);
              _cardNumberController.clear();
              return;
            }
          }
        } catch (e) {
          print('POST Parse error: $e');
        }
      }
      
      _showErrorDialog('POST method also failed. Please try again.');
    } catch (e) {
      _showErrorDialog('POST Error: $e');
      print('POST Exception: $e');
    }
  }

  void _showSuccessModal(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            
            // Contact name
            Text(
              data['ContactName'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Contact number (Account Number)
            Text(
              'Account: ${data['ContactNumber'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            
            // Contact ID
            Text(
              'ID: ${data['ContactID'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDeposit(data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Deposit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          _handleWithdraw(data);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Withdraw',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleDeposit(Map<String, dynamic> data) {
    // Navigate to contact detail screen with the member details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          contactName: data['ContactName'] ?? 'Unknown',
          phoneNumber: data['ContactNumber'] ?? '',
          contact: null,
          contactID: data['ContactID'] ?? '', // Pass ContactID from API response
        ),
      ),
    );
  }

  void _handleWithdraw(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => POSWithdrawalScreen(
          studentName: data['ContactName'] ?? 'N/A',
          rollNo: data['ContactNumber'] ?? 'N/A',
          studentPhoto: data['ContactID'] ?? '',
          senderContactID: data['ContactID'] ?? '', // RFID Card Contact ID
          pinFromAPI: data['PIN']?.toString(), // PIN from API response
          apiMemberData: jsonEncode(data), // Full member data
        ),
      ),
    );
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          title: const Text(
            'POS',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            // Keyboard toggle button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isKeyboardEnabled = !_isKeyboardEnabled;
                    if (!_isKeyboardEnabled) {
                      // Hide keyboard but keep focus on field
                      FocusScope.of(context).requestFocus(_cardNumberFocusNode);
                    } else {
                      // Show keyboard
                      FocusScope.of(context).requestFocus(_cardNumberFocusNode);
                    }
                  });
                },
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isKeyboardEnabled ? const Color(0xFF4CAF50) : Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isKeyboardEnabled ? Icons.keyboard : Icons.block,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isKeyboardEnabled ? 'ON' : 'OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen image with GestureDetector to keep focus
            GestureDetector(
              onTap: () {
                // Keep focus on the input field
                FocusScope.of(context).requestFocus(_cardNumberFocusNode);
              },
              child: Image.network(
                'https://merimaa.life/Assets/uploads/image_1778074377_69fb43098b288.jpeg',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Image could not be loaded',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Card number input field at top
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: TextField(
                focusNode: _cardNumberFocusNode,
                controller: _cardNumberController,
                readOnly: !_isKeyboardEnabled,
                showCursor: true,
                onSubmitted: (value) {
                  // Submit on Enter key
                  _submitCardNumber();
                },
                decoration: InputDecoration(
                  hintText: 'Enter Card Number',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.credit_card, color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                ),
                // style: const TextStyle(color: Colors.white, fontSize: 16),
                // keyboardType: TextInputType.number,
                // maxLength: 19,
                // textInputAction: TextInputAction.send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
