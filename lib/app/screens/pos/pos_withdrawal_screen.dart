import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/api_service.dart';

class POSWithdrawalScreen extends StatefulWidget {
  final String studentName;
  final String rollNo;
  final String studentPhoto;
  final String? senderContactID; // RFID card contact ID
  final String? pinFromAPI; // PIN from API response
  final String? apiMemberData; // Full API response data

  const POSWithdrawalScreen({
    Key? key,
    required this.studentName,
    required this.rollNo,
    required this.studentPhoto,
    this.senderContactID,
    this.pinFromAPI,
    this.apiMemberData,
  }) : super(key: key);

  @override
  State<POSWithdrawalScreen> createState() => _POSWithdrawalScreenState();
}

class _POSWithdrawalScreenState extends State<POSWithdrawalScreen> {
  late FocusNode _amountFocusNode;
  late FocusNode _pinFocusNode;
  late TextEditingController _amountController;
  late TextEditingController _pinController;
  bool _isPinVisible = false;
  bool _isProcessing = false;
  int _currentStep = 1; // 1 = Enter Amount, 2 = Enter PIN, 3 = Review

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _pinFocusNode = FocusNode();
    _amountController = TextEditingController();
    _pinController = TextEditingController();

    // Auto-focus on amount field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _pinFocusNode.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_amountController.text.isEmpty) {
        _showErrorDialog('Please enter amount');
        return;
      }
      setState(() {
        _currentStep = 2;
      });
      FocusScope.of(context).requestFocus(_pinFocusNode);
    } else if (_currentStep == 2) {
      if (_pinController.text.isEmpty) {
        _showErrorDialog('Please enter PIN');
        return;
      }
      if (_pinController.text.length != 4) {
        _showErrorDialog('PIN must be 4 digits');
        return;
      }
      
      // Verify PIN against API response
      if (_pinController.text != widget.pinFromAPI) {
        _showErrorDialog('Invalid PIN. Please try again.');
        _pinController.clear();
        return;
      }
      
      setState(() {
        _currentStep = 3;
      });
    }
  }

  Future<void> _processTransaction() async {
    // Verify PIN first
    if (_pinController.text != widget.pinFromAPI) {
      _showErrorDialog('Invalid PIN. Please try again.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get user credentials from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final email = authProvider.email;
      final tokenCode = await authProvider.getTokenCode();
      final receiverContactID = await authProvider.getContactID();

      // Validate credentials
      if (email == null || email.isEmpty) {
        throw Exception('User email not found');
      }
      if (tokenCode.isEmpty) {
        throw Exception('User token code not found');
      }
      if (receiverContactID.isEmpty) {
        throw Exception('User contact ID not found');
      }

      if (widget.senderContactID == null || widget.senderContactID!.isEmpty) {
        throw Exception('Sender contact ID not available');
      }

      final amount = _amountController.text;
      final remarks = 'POS Withdrawal';

      print('Processing POS Withdrawal:');
      print('Sender (Card): ${widget.senderContactID}');
      print('Receiver (User): $receiverContactID');
      print('Amount: $amount');
      print('PIN Verified: Yes');

      // Call the send money API
      final result = await ApiService.sendAmountToMember(
        email: email,
        tokenCode: tokenCode,
        senderContactID: widget.senderContactID!,
        receiverContactID: receiverContactID,
        amount: amount,
        remarks: remarks,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result['success'] == true) {
          // Show success dialog
          _showSuccessDialog(amount);
        } else {
          _showErrorDialog(result['message'] ?? 'Transaction failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        print('Transaction error: $e');
        _showErrorDialog('Transaction failed: ${e.toString()}');
      }
    }
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

  void _showSuccessDialog(String amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Transaction Successful',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '₹$amount',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.studentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll: ${widget.rollNo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Withdrawal completed successfully',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Close withdrawal screen
              Navigator.pop(context); // Close POS screen
            },
            child: const Text('Done'),
          ),
        ],
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
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          title: const Text(
            'Withdrawal',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Student name
                _buildStudentNameHeader(),
                const SizedBox(height: 40),

                // Step content
                if (_currentStep == 1)
                  _buildAmountStep()
                else if (_currentStep == 2)
                  _buildPinStep()
                else
                  _buildReviewStep(),

                const SizedBox(height: 40),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentNameHeader() {
    return Text(
      widget.studentName,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          children: [
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 4, 5, 6
        Row(
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: 7, 8, 9
        Row(
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 4: C, 0, Backspace
        Row(
          children: [
            _buildKeypadButton('C', isDelete: true),
            _buildKeypadButton('0'),
            _buildKeypadButton('←', isDelete: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, {bool isDelete = false, bool isOperator = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _handleKeypadInput(label);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isDelete
                ? const Color(0xFFFF6B6B)
                : isOperator
                    ? const Color(0xFFF44336)
                    : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isDelete || isOperator ? Colors.red : Colors.grey)
                    .withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDelete || isOperator
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDelete || isOperator ? Colors.white : const Color(0xFF2C2C2C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeypadInput(String input) {
    setState(() {
      if (input == 'C') {
        // Clear all
        _amountController.clear();
      } else if (input == '←') {
        // Delete last character
        if (_amountController.text.isNotEmpty) {
          _amountController.text =
              _amountController.text.substring(0, _amountController.text.length - 1);
        }
      } else {
        // Add digit
        _amountController.text += input;
      }
    });
  }

  Widget _buildAmountStep() {
    return Column(
      children: [
        const Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Amount input - transparent, no border
        TextField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          readOnly: true, // Disable default keyboard
          onTap: () {
            // Prevent default keyboard from showing
            FocusScope.of(context).requestFocus(FocusNode());
          },
          decoration: const InputDecoration(
            hintText: '₹ 0.00',
            hintStyle: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBDBDBD),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF44336),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Custom numeric keypad
        _buildNumericKeypad(),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        const Text(
          'Enter PIN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // PIN input - transparent, no border
        TextField(
          controller: _pinController,
          focusNode: _pinFocusNode,
          obscureText: !_isPinVisible,
          readOnly: true, // Disable default keyboard
          maxLength: 4,
          onTap: () {
            // Prevent default keyboard from showing
            FocusScope.of(context).requestFocus(FocusNode());
          },
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBDBDBD),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _isPinVisible = !_isPinVisible;
                });
              },
              child: Icon(
                _isPinVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFFF44336),
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            color: Color(0xFFF44336),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Custom numeric keypad for PIN
        _buildPinKeypad(),
      ],
    );
  }

  Widget _buildPinKeypad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          children: [
            _buildPinKeypadButton('1'),
            _buildPinKeypadButton('2'),
            _buildPinKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 4, 5, 6
        Row(
          children: [
            _buildPinKeypadButton('4'),
            _buildPinKeypadButton('5'),
            _buildPinKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: 7, 8, 9
        Row(
          children: [
            _buildPinKeypadButton('7'),
            _buildPinKeypadButton('8'),
            _buildPinKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 8),
        // Row 4: Back (Go to Amount), 0, Delete
        Row(
          children: [
            _buildPinKeypadButton('Back', isBack: true),
            _buildPinKeypadButton('0'),
            _buildPinKeypadButton('Delete', isDelete: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPinKeypadButton(String label, {bool isDelete = false, bool isBack = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isBack) {
            // Go back to amount entry
            setState(() {
              _currentStep = 1;
              _pinController.clear();
            });
            FocusScope.of(context).requestFocus(_amountFocusNode);
          } else {
            _handlePinKeypadInput(label);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isDelete ? const Color(0xFFFF6B6B) : isBack ? const Color(0xFF9E9E9E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isDelete || isBack ? Colors.grey : Colors.grey).withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDelete ? const Color(0xFFFF6B6B) : isBack ? const Color(0xFF9E9E9E) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: (isDelete || isBack) ? Colors.white : const Color(0xFF2C2C2C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePinKeypadInput(String input) {
    setState(() {
      if (input == '←') {
        // Delete last character
        if (_pinController.text.isNotEmpty) {
          _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
        }
      } else if (_pinController.text.length < 4) {
        // Add digit
        _pinController.text += input;
      }
    });
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        const Text(
          'Confirm Transaction',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Amount display
        Column(
          children: [
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '₹${_amountController.text}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF44336),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentStep < 3)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}



