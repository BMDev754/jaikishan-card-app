import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/security_service.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen>
    with TickerProviderStateMixin {
  String _enteredPin = '';
  String? _correctPin; // Will be loaded from SecurityService
  bool _isLoading = false;
  bool _isError = false;
  
  late AnimationController _shakeController;
  late AnimationController _bounceController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _loadCorrectPin();
  }

  Future<void> _loadCorrectPin() async {
    final storedPin = await SecurityService.instance.userPasscode;
    setState(() {
      _correctPin = storedPin ?? ''; // Fallback to demo PIN
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onPinDigitTap(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Bounce animation for PIN dots
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });

      // Auto verify when PIN is complete
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _verifyPin() async {
    if (_correctPin == null) {
      // PIN not loaded yet
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_enteredPin == _correctPin) {
      // Success
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    } else {
      // Error
      setState(() {
        _isLoading = false;
        _isError = true;
        _enteredPin = '';
      });
      
      HapticFeedback.heavyImpact();
      
      // Shake animation
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Please try again.'),
          backgroundColor: Color(0xFFE57373),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight - 40, // Account for SafeArea and padding
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header Section
                  _buildHeader(),
                  
                  const SizedBox(height: 30),
                  
                  // PIN Display
                  _buildPinDisplay(),
                  
                  const SizedBox(height: 30),
                  
                  // Loading or Error State
                  if (_isLoading) _buildLoadingState(),
                  if (_isError && !_isLoading) _buildErrorState(),
                  
                  const SizedBox(height: 20),
                  
                  // PIN Keypad
                  _buildPinKeypad(),
                  
                  const SizedBox(height: 16),
                  
                  // Forgot PIN
                  _buildForgotPin(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A11CB).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter your PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please enter your 4-digit PIN to view\nyour wallet balance',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _enteredPin.length == index + 1 ? _bounceAnimation.value : 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _enteredPin.length
                            ? (_isError ? const Color(0xFFE57373) : const Color(0xFF6A11CB))
                            : Colors.grey[300],
                        border: Border.all(
                          color: index < _enteredPin.length
                              ? (_isError ? const Color(0xFFE57373) : const Color(0xFF6A11CB))
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verifying PIN...',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE57373).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.error_outline,
            color: Color(0xFFE57373),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Incorrect PIN',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFE57373),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPinKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 4: *, 0, delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('', isDisabled: true),
              _buildKeypadButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit, {bool isDisabled = false}) {
    return GestureDetector(
      onTap: isDisabled || _isLoading ? null : () => _onPinDigitTap(digit),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(27.5),
          border: isDisabled ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDisabled ? Colors.transparent : const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onDeleteTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(27.5),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Color(0xFF666666),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPin() {
    return GestureDetector(
      onTap: () => _showForgotPinDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: const Text(
          'Forgot PIN?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6A11CB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: Text(
          _correctPin != null 
            ? 'Your current PIN is: $_correctPin\n\nYou can change your PIN in Account > Security > Change Passcode.'
            : 'Loading your PIN...\n\nYou can change your PIN in Account > Security > Change Passcode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
