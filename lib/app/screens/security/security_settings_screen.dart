import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/security_service.dart';
import '../../services/onboarding_service.dart';
import '../../providers/onboarding_provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const SecuritySettingsScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _appLockEnabled = false;
  bool _deviceAuthAvailable = false;
  int _sessionTimeout = 1;
  bool _isLoading = true;
  bool _isOnboardingPending = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkDeviceAuthAvailability();
    _checkOnboardingStatus();
  }

  Future<void> _loadSettings() async {
    final appLockEnabled = await SecurityService.instance.isAppLockEnabled;
    final timeout = await SecurityService.instance.sessionTimeout;

    setState(() {
      _appLockEnabled = appLockEnabled;
      _sessionTimeout = timeout;
      _isLoading = false;
    });
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
      await onboardingProvider.initializeOnboarding();
      
      // Check if app lock step is the current onboarding step
      final currentStep = onboardingProvider.currentStep;
      final isOnboardingActive = onboardingProvider.isOnboardingActive;
      final isAppLockCompleted = await OnboardingService.isAppLockEnabled();
      final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();
      
      print('Onboarding Debug:');
      print('Current Step: $currentStep');
      print('Is Onboarding Active: $isOnboardingActive');
      print('Widget isOnboarding: ${widget.isOnboarding}');
      print('Is App Lock Completed: $isAppLockCompleted');
      print('Is Onboarding Completed: $isOnboardingCompleted');
      
      setState(() {
        // For now, always show skip button (for testing)
        _isOnboardingPending = true;
        
        // Original logic (commented for debugging):
        // _isOnboardingPending = widget.isOnboarding || 
        //                       (currentStep == OnboardingStep.appLock && isOnboardingActive) ||
        //                       (!isAppLockCompleted && !isOnboardingCompleted);
      });
      
      print('Is Onboarding Pending: $_isOnboardingPending');
    } catch (e) {
      print('Error checking onboarding status: $e');
      setState(() {
        _isOnboardingPending = true; // Default to showing skip button if there's an error
      });
    }
  }

  Future<void> _checkDeviceAuthAvailability() async {
    try {
      print('Checking device authentication availability...');
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      print('canCheckBiometrics: $isAvailable');
      print('isDeviceSupported: $isDeviceSupported');
      print('availableBiometrics: $availableBiometrics');
      
      final deviceAuthAvailable = isAvailable && isDeviceSupported;
      print('Device auth available: $deviceAuthAvailable');
      
      setState(() {
        _deviceAuthAvailable = deviceAuthAvailable;
      });
    } catch (e) {
      print('Error checking device auth availability: $e');
      setState(() {
        _deviceAuthAvailable = false;
      });
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value && _deviceAuthAvailable) {
      // Test device authentication before enabling
      try {
        print('Attempting device authentication...');
        final isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable app lock',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );

        print('Authentication result: $isAuthenticated');
        if (isAuthenticated) {
          await SecurityService.instance.setAppLockEnabled(true);
          setState(() {
            _appLockEnabled = true;
          });
          _showSuccessMessage('App lock enabled');
          
          // Handle onboarding flow
          if (_isOnboardingPending) {
            final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
            await onboardingProvider.completeAppLockStep();
          }
        }
      } catch (e) {
        print('Authentication error: $e');
        _showErrorMessage('Failed to enable app lock: ${e.toString()}');
      }
    } else if (value && !_deviceAuthAvailable) {
      _showErrorMessage('Device authentication not available. Please set up PIN, Pattern, Password, or Biometric in your device settings.');
    } else {
      await SecurityService.instance.setAppLockEnabled(false);
      setState(() {
        _appLockEnabled = false;
      });
      _showSuccessMessage('App lock disabled');
    }
  }

  Future<void> _updateSessionTimeout(int minutes) async {
    await SecurityService.instance.setSessionTimeout(minutes);
    setState(() {
      _sessionTimeout = minutes;
    });
    _showSuccessMessage('Session timeout updated to $minutes minutes');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'App Lock Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Onboarding Info (if applicable)
                    if (_isOnboardingPending) ...[
                      /*Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00BCD4).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: const Color(0xFF00BCD4),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Optional Security Step',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00BCD4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You can enable app lock to secure your app with your device authentication. This step is optional and can be skipped.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),*/
                      //const SizedBox(height: 20),
                    ],
                    
                    // App Lock Header
                    _buildSectionHeader(
                      'App Lock',
                      'Secure your app with device authentication',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // App Lock Toggle
                    _buildAppLockSection(),
                    
                    const SizedBox(height: 20),
                    
                    // Device Security Info
                    _buildDeviceSecurityInfo(),
                    
                    if (_appLockEnabled) ...[
                      const SizedBox(height: 30),
                      
                      // Session Timeout
                      _buildSectionHeader(
                        'Session Timeout',
                        'App will require authentication after this time',
                      ),
                      const SizedBox(height: 20),
                      _buildSessionTimeoutSection(),
                    ],

                    // Simple Skip Button in Footer
                    if (_isOnboardingPending) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: TextButton(
                          onPressed: _skipAppLock,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildAppLockSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6A11CB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.security,
              color: _deviceAuthAvailable ? const Color(0xFF6A11CB) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable App Lock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _deviceAuthAvailable
                      ? 'Use device security to protect your app'
                      : 'Device security not set up',
                  style: TextStyle(
                    fontSize: 12,
                    color: _deviceAuthAvailable ? const Color(0xFF666666) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _appLockEnabled,
            onChanged: _deviceAuthAvailable ? _toggleAppLock : null,
            activeColor: const Color(0xFF6A11CB),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _deviceAuthAvailable 
            ? const Color(0xFFF0F8FF) 
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _deviceAuthAvailable 
              ? const Color(0xFF2196F3).withOpacity(0.2)
              : const Color(0xFFFF9800).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _deviceAuthAvailable ? Icons.check_circle : Icons.warning,
                color: _deviceAuthAvailable 
                    ? const Color(0xFF2196F3) 
                    : const Color(0xFFFF9800),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _deviceAuthAvailable 
                    ? 'Device Security Available' 
                    : 'Setup Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _deviceAuthAvailable 
                      ? const Color(0xFF2196F3) 
                      : const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _deviceAuthAvailable
                ? 'Your device supports the following authentication methods:\n• Fingerprint\n• Face unlock\n• PIN, Pattern, or Password'
                : 'To use app lock, please set up device security in your phone settings:\n• Go to Settings > Security\n• Set up PIN, Pattern, Password, or Biometric',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimeoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto-lock after',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '$_sessionTimeout min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A11CB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _sessionTimeout.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: const Color(0xFF6A11CB),
            inactiveColor: Colors.grey[300],
            onChanged: (value) {
              setState(() {
                _sessionTimeout = value.round();
              });
            },
            onChangeEnd: (value) {
              _updateSessionTimeout(value.round());
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 min', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('30 min', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // Skip app lock - simple bypass without enabling app lock
  Future<void> _skipAppLock() async {
    try {
      // Just close the screen without enabling app lock or completing onboarding step
      print('Skipping app lock setup - not enabling app lock');
      
      // Ensure app lock remains disabled
      await SecurityService.instance.setAppLockEnabled(false);
      
      // Don't call any onboarding completion methods - just close the screen
      // The user can continue with the app without app lock enabled
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error skipping: $e');
      // Still close the screen even if there's an error
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
