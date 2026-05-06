import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/security_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  
  const AppLockScreen({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with TickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _canUseDeviceAuth = false;
  bool _authAttempted = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkDeviceAuthAvailability();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkDeviceAuthAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (isAvailable && isDeviceSupported) {
        setState(() {
          _canUseDeviceAuth = true;
        });
        // Auto-trigger device authentication
        _authenticateWithDevice();
      } else {
        // If device auth is not available, show manual unlock option
        setState(() {
          _canUseDeviceAuth = false;
        });
      }
    } catch (e) {
      print('Error checking device auth availability: $e');
      setState(() {
        _canUseDeviceAuth = false;
      });
    }
  }

  Future<void> _authenticateWithDevice() async {
    if (_authAttempted) return;
    
    setState(() {
      _authAttempted = true;
      _isLoading = true;
    });

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Jaikisan Card',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN, pattern, password as fallback
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await SecurityService.instance.updateLastAuthTime();
        widget.onUnlocked();
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show retry option
        _showRetryDialog();
      }
    } on PlatformException catch (e) {
      print('Device authentication error: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.message ?? 'Authentication failed');
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'You need to authenticate to access the app. Please try again or close the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop(); // Close the app
            },
            child: const Text('Close App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _authAttempted = false;
              });
              _authenticateWithDevice();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop(); // Close the app
            },
            child: const Text('Close App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _authAttempted = false;
              });
              _authenticateWithDevice();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      _buildAppLogo(),
                      
                      const SizedBox(height: 40),
                      
                      // Security Message
                      _buildSecurityMessage(),
                      
                      const SizedBox(height: 60),
                      
                      // Authentication Button or Loading State
                      if (_isLoading) 
                        _buildLoadingState()
                      else
                        _buildUnlockButton(),
                      
                      const SizedBox(height: 30),
                      
                      // Alternative unlock options
                      if (!_isLoading) _buildAlternativeOptions(),
                      
                      
                      // Instructions
                      _buildInstructions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(
        Icons.credit_card,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildSecurityMessage() {
    return Column(
      children: [
        const Text(
          'Jaikisan Card',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _canUseDeviceAuth
              ? 'Use your device security to unlock'
              : 'Authentication required to access the app',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Authenticating...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: _handleUnlockTap,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'UNLOCK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlternativeOptions() {
    return Column(
      children: [
        // Biometric/Device Auth Option
        if (_canUseDeviceAuth) 
          _buildAuthOption(
            icon: Icons.fingerprint,
            title: 'Use Biometric',
            subtitle: 'Fingerprint, Face, or Device PIN',
            onTap: _authenticateWithDevice,
          ),
        
        const SizedBox(height: 16),
        
        // App Passcode Option
        _buildAuthOption(
          icon: Icons.dialpad,
          title: 'Enter Passcode',
          subtitle: 'Use app passcode to unlock',
          onTap: _showPasscodeDialog,
        ),
      ],
    );
  }

  Widget _buildAuthOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnlockTap() async {
    if (_canUseDeviceAuth) {
      await _authenticateWithDevice();
    } else {
      _showPasscodeDialog();
    }
  }

  void _showPasscodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasscodeDialog(
        onSuccess: () {
          Navigator.pop(context);
          widget.onUnlocked();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            _canUseDeviceAuth
                ? 'This app uses your device\'s security features:\n• Fingerprint\n• Face unlock\n• PIN, Pattern, or Password'
                : 'Please enable device security (PIN, Pattern, Password, or Biometric) in your device settings to use app lock.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PasscodeDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const PasscodeDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<PasscodeDialog> createState() => _PasscodeDialogState();
}

class _PasscodeDialogState extends State<PasscodeDialog>
    with TickerProviderStateMixin {
  String _enteredPin = '';
  bool _isLoading = false;
  bool _isError = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onPinDigitTap(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });

      HapticFeedback.lightImpact();

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
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    bool isValid = await SecurityService.instance.verifyPasscode(_enteredPin);

    if (isValid) {
      await SecurityService.instance.updateLastAuthTime();
      HapticFeedback.heavyImpact();
      widget.onSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _isError = true;
        _enteredPin = '';
      });

      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enter Passcode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // PIN Display
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _enteredPin.length
                              ? (_isError
                                  ? const Color(0xFFE57373)
                                  : const Color(0xFF6A11CB))
                              : Colors.white.withOpacity(0.3),
                          border: Border.all(
                            color: index < _enteredPin.length
                                ? (_isError
                                    ? const Color(0xFFE57373)
                                    : const Color(0xFF6A11CB))
                                : Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Loading or Error State
            if (_isLoading)
              const Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Verifying...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              )
            else if (_isError)
              const Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Color(0xFFE57373),
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Incorrect passcode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE57373),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // PIN Keypad
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
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
        const SizedBox(height: 12),
        
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 12),
        
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 12),
        
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
    );
  }

  Widget _buildKeypadButton(String digit, {bool isDisabled = false}) {
    return GestureDetector(
      onTap: isDisabled || _isLoading ? null : () => _onPinDigitTap(digit),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: isDisabled
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDisabled ? Colors.transparent : Colors.white,
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}