import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _backgroundAnimationController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    _setupAnimations();
    _startAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animation controller
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo rotation animation
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Text slide animation
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Text fade animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeIn,
    ));

    // Background animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    if (!mounted) return;
    _backgroundAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoAnimationController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textAnimationController.forward();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait for auth provider to initialize if not already done
      if (!authProvider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (authProvider.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF1A237E), const Color(0xFF00BCD4), _backgroundAnimation.value) ?? const Color(0xFF1A237E),
                  Color.lerp(const Color(0xFF3F51B5), const Color(0xFF26C6DA), _backgroundAnimation.value) ?? const Color(0xFF3F51B5),
                  Color.lerp(const Color(0xFF00BCD4), const Color(0xFF4FC3F7), _backgroundAnimation.value) ?? const Color(0xFF00BCD4),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background decorative elements
                _buildBackgroundDecorations(),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Section
                      _buildLogo(),
                      
                      const SizedBox(height: 40),
                      
                      // App Name
                      _buildAppName(),
                      
                      const SizedBox(height: 8),
                      
                      // Tagline
                      _buildTagline(),
                      
                      const SizedBox(height: 60),
                      
                      // Loading Section
                      _buildLoadingSection(),
                    ],
                  ),
                ),
                
                // Bottom branding
                _buildBottomBranding(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Floating circles
        Positioned(
          top: 100,
          right: -50,
          child: AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 150,
          left: -75,
          child: AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundAnimation.value * 0.8,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 200,
          left: 50,
          child: AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundAnimation.value * 0.6,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value * 0.1,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF8F9FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main icon
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 60,
                    color: Color(0xFF00BCD4),
                  ),
                  
                  // Decorative elements
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    left: 25,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildAppName() {
    return SlideTransition(
      position: _textSlideAnimation,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: const Text(
          'Jaikisan Card',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return SlideTransition(
      position: _textSlideAnimation,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'Secure • Fast • Reliable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // Loading indicator
        Container(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.3),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Loading text
        FadeTransition(
          opacity: _textFadeAnimation,
          child: const Text(
            'Initializing your digital wallet...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBranding() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bank-grade Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
