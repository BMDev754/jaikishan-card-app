import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/providers/auth_provider.dart';
import 'app/providers/app_security_provider.dart';
import 'app/providers/onboarding_provider.dart';
import 'app/providers/notification_provider.dart';
import 'app/routes/app_router.dart';
import 'app/utils/app_theme.dart';
import 'app/services/storage_service.dart';
import 'app/services/profile_service.dart';
import 'app/services/security_service.dart';
import 'app/services/notification_service.dart';
import 'app/screens/security/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue even if Firebase fails - app can work without it
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.initialize();
  
  // Initialize Profile Service with default data
  await ProfileService.instance.initializeDefaultProfile();
  
  // Initialize Notification Service
  try {
    await NotificationService.instance.initialize();
    print('✓ Notification service initialized');
  } catch (e) {
    print('Notification service error: $e');
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppSecurityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider()..initializeOnboarding(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Consumer2<AuthProvider, AppSecurityProvider>(
        builder: (context, authProvider, securityProvider, child) {
          return MaterialApp.router(
            title: 'Jaikisan Card',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // Show app lock screen if security is enabled and app is locked
              if (securityProvider.isAppLocked && !securityProvider.isCheckingLock) {
                return AppLockScreen(
                  onUnlocked: () {
                    securityProvider.unlockApp();
                  },
                );
              }

              // Show privacy screen if app is in background to hide content
              if (securityProvider.isAppInBackground && !securityProvider.isCheckingLock) {
                return _buildPrivacyScreen();
              }
              
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: AppLifecycleWrapper(
                  securityProvider: securityProvider,
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrivacyScreen() {
    return Consumer<AppSecurityProvider>(
      builder: (context, securityProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF6A11CB),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Jaikisan Card',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'App is secured',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 50),
                // Unlock Button
                GestureDetector(
                  onTap: () => _handlePrivacyUnlock(context, securityProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_open,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Unlock App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to unlock with biometric or passcode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePrivacyUnlock(BuildContext context, AppSecurityProvider securityProvider) async {
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      
      // Check if biometric authentication is available
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        // Try biometric authentication first
        final bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to unlock Jaikisan Card',
          options: const AuthenticationOptions(
            biometricOnly: false, // Allow PIN, pattern, password as fallback
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          await SecurityService.instance.updateLastAuthTime();
          securityProvider.unlockApp();
        }
      } else {
        // Show passcode dialog if biometric is not available
        _showPrivacyPasscodeDialog(context, securityProvider);
      }
    } on PlatformException catch (e) {
      print('Authentication error: $e');
      // Fallback to passcode dialog
      _showPrivacyPasscodeDialog(context, securityProvider);
    } catch (e) {
      print('Unexpected error during authentication: $e');
      // Fallback to passcode dialog
      _showPrivacyPasscodeDialog(context, securityProvider);
    }
  }

  void _showPrivacyPasscodeDialog(BuildContext context, AppSecurityProvider securityProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasscodeDialog(
        onSuccess: () {
          Navigator.pop(context);
          securityProvider.unlockApp();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  final AppSecurityProvider securityProvider;
  final Widget child;

  const AppLifecycleWrapper({
    super.key,
    required this.securityProvider,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App comes to foreground - check if unlock is needed and refresh API data
        widget.securityProvider.onAppResumed();
        _refreshApiDataOnResume();
        break;
      case AppLifecycleState.paused:
        // App is going to background (minimized) - lock the app
        widget.securityProvider.onAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., during a phone call) - hide content but don't fully lock
        widget.securityProvider.onAppInactive();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new state in Flutter 3.13+) - lock the app
        widget.securityProvider.onAppPaused();
        break;
    }
  }

  void _refreshApiDataOnResume() {
    // Get the auth provider and refresh API data when app resumes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isLoggedIn) {
          authProvider.refreshApiDataForAllScreens();
        }
      } catch (e) {
        print('Error refreshing API data on app resume: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
