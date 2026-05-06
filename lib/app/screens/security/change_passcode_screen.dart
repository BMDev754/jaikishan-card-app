import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/security_service.dart';
import '../../providers/onboarding_provider.dart';
import 'package:local_auth/local_auth.dart';

class ChangePasscodeScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const ChangePasscodeScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<ChangePasscodeScreen> createState() => _ChangePasscodeScreenState();
}

class _ChangePasscodeScreenState extends State<ChangePasscodeScreen>
    with TickerProviderStateMixin {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  int _currentStep = 1; // 1: current pin, 2: new pin, 3: confirm pin
  bool _isLoading = false;
  bool _isError = false;
  bool _isFirstTimeSetup = false; // Track if this is first time PIN setup
  final LocalAuthentication _localAuth = LocalAuthentication();

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

    _checkExistingPasscode();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingPasscode() async {
    final hasPasscode = await SecurityService.instance.hasPasscodeSet;
    setState(() {
      _isFirstTimeSetup = !hasPasscode;
    });
    
    if (!hasPasscode) {
      // If no passcode exists, skip to new pin creation
      setState(() {
        _currentStep = 2;
      });
    }
  }

  String get _currentPinValue {
    switch (_currentStep) {
      case 1:
        return _currentPin;
      case 2:
        return _newPin;
      case 3:
        return _confirmPin;
      default:
        return '';
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 1:
        return 'Enter current PIN';
      case 2:
        return _isFirstTimeSetup ? 'Create your PIN' : 'Enter new PIN';
      case 3:
        return _isFirstTimeSetup ? 'Confirm your PIN' : 'Confirm new PIN';
      default:
        return '';
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 1:
        return 'Please enter your current 4-digit PIN';
      case 2:
        return _isFirstTimeSetup 
            ? 'Create a secure 4-digit PIN for your account' 
            : 'Create a new 4-digit PIN for security';
      case 3:
        return _isFirstTimeSetup 
            ? 'Re-enter your PIN to confirm' 
            : 'Re-enter your new PIN to confirm';
      default:
        return '';
    }
  }

  void _onPinDigitTap(String digit) {
    if (_currentPinValue.length < 4) {
      setState(() {
        switch (_currentStep) {
          case 1:
            _currentPin += digit;
            break;
          case 2:
            _newPin += digit;
            break;
          case 3:
            _confirmPin += digit;
            break;
        }
        _isError = false;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Bounce animation for PIN dots
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });

      // Auto verify when PIN is complete
      if (_currentPinValue.length == 4) {
        _verifyCurrentStep();
      }
    }
  }

  void _onDeleteTap() {
    if (_currentPinValue.isNotEmpty) {
      setState(() {
        switch (_currentStep) {
          case 1:
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
            break;
          case 2:
            _newPin = _newPin.substring(0, _newPin.length - 1);
            break;
          case 3:
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
            break;
        }
        _isError = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _verifyCurrentStep() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    bool isValid = false;
    String errorMessage = '';

    switch (_currentStep) {
      case 1:
        // Verify current PIN
        isValid = await SecurityService.instance.verifyPasscode(_currentPin);
        errorMessage = 'Incorrect current PIN';
        break;
      case 2:
        // New PIN entered, move to confirmation
        isValid = true;
        break;
      case 3:
        // Confirm new PIN and update via API
        if (_newPin == _confirmPin) {
          Map<String, dynamic> result;
          
          if (_isFirstTimeSetup || _currentPin.isEmpty) {
            // First time setup - set passcode directly
            try {
              await SecurityService.instance.setUserPasscode(_newPin);
              result = {
                'success': true,
                'message': 'Passcode set successfully!',
              };
            } catch (e) {
              result = {
                'success': false,
                'message': 'Failed to set passcode: $e',
              };
            }
          } else {
            // Update existing passcode via API
            result = await SecurityService.instance.updatePasscodeViaApi(_currentPin, _newPin);
          }
          
          if (result['success'] == true) {
            isValid = true;
            
            setState(() {
              _isLoading = false;
            });
            
            HapticFeedback.heavyImpact();
            
            if (mounted) {
              // Handle onboarding flow
              if (widget.isOnboarding) {
                final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
                await onboardingProvider.completePasscodeStep();
              }
              
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Passcode updated successfully!'),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return; // Exit early since we handled the success case
          } else {
            isValid = false;
            errorMessage = result['message'] ?? 'Failed to update passcode';
          }
        } else {
          isValid = false;
          errorMessage = 'PINs do not match';
        }
        break;
    }

    if (isValid) {
      if (_currentStep < 3) {
        // Move to next step
        setState(() {
          _currentStep++;
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    } else {
      // Error
      setState(() {
        _isLoading = false;
        _isError = true;
        switch (_currentStep) {
          case 1:
            _currentPin = '';
            break;
          case 2:
            _newPin = '';
            break;
          case 3:
            _confirmPin = '';
            break;
        }
      });

      HapticFeedback.heavyImpact();

      // Shake animation
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFE57373),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to change your passcode',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        // Skip current PIN verification
        setState(() {
          _currentStep = 2;
        });
      }
    } catch (e) {
      print('Authentication error: $e');
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        ),
        title: const Text(
          'Change Passcode',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight -
                    40,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Progress indicator
                  _buildProgressIndicator(),

                  const SizedBox(height: 30),

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

                  // Biometric authentication option (only for step 1)
                  if (_currentStep == 1) _buildBiometricOption(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index < _currentStep;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF6A11CB)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
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
            Icons.vpn_key,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _stepTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _stepSubtitle,
          style: const TextStyle(
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
                    scale: _currentPinValue.length == index + 1
                        ? _bounceAnimation.value
                        : 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _currentPinValue.length
                            ? (_isError
                                ? const Color(0xFFE57373)
                                : const Color(0xFF6A11CB))
                            : Colors.grey[300],
                        border: Border.all(
                          color: index < _currentPinValue.length
                              ? (_isError
                                  ? const Color(0xFFE57373)
                                  : const Color(0xFF6A11CB))
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
        Text(
          _currentStep == 1 
              ? 'Verifying current PIN...' 
              : _currentStep == 2 
                  ? 'Processing...' 
                  : (_isFirstTimeSetup ? 'Setting up your PIN...' : 'Updating passcode...'),
          style: const TextStyle(
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
        Text(
          _currentStep == 1
              ? 'Incorrect PIN'
              : _currentStep == 3
                  ? 'PINs do not match'
                  : 'Error',
          style: const TextStyle(
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

  Widget _buildBiometricOption() {
    return GestureDetector(
      onTap: _authenticateWithBiometrics,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.fingerprint,
              color: Color(0xFF6A11CB),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Use biometric authentication',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6A11CB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
