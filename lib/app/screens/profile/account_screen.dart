import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/security_service.dart';
import '../security/security_settings_screen.dart';
import '../security/change_passcode_screen.dart';
import 'profile_management_screen.dart';
import '../../services/profile_service.dart';
import '../webview/in_app_browser_screen.dart';
import 'qr_code_upi_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with TickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFlipped = false;
  bool _securityEnabled = false;
  
  // Profile data
  String _userName ='';
  String _userEmail='';
  String _userPhone = '';
  String? _profileImagePath;
  
  // Card-related data
  String _cardNumber = '';
  String _cvv = '';
  String _validity = '';

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadSecuritySettings();
    // Delay loading profile data to ensure AuthProvider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForAuthProviderAndLoadData();
    });
  }

  Future<void> _waitForAuthProviderAndLoadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for AuthProvider to be initialized
    while (!authProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('=== AuthProvider Initialized ===');
    print('Login status: ${authProvider.isLoggedIn}');
    print('Has API data: ${await authProvider.hasApiProfileData()}');
    print('=================================');
    
    // Now load profile data
    await _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if AuthProvider is initialized and we have login status change
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isInitialized && authProvider.isLoggedIn) {
      _loadProfileData();
    }
  }

  @override
  void didUpdateWidget(AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when widget updates
    _loadProfileData();
  }

  // Add method to refresh profile data manually
  Future<void> refreshProfileData() async {
    await _loadProfileData();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    final appLockEnabled = await SecurityService.instance.isAppLockEnabled;
    
    setState(() {
      _securityEnabled = appLockEnabled;
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('=== Loading Profile Data ===');
      print('User logged in: ${authProvider.isLoggedIn}');
      print('Auth email: ${authProvider.email}');
      print('Auth phone: ${authProvider.phoneNumber}');
      
      // Always try to get profile image from ProfileService (for custom uploaded images)
      String? profileImagePath;
      try {
        profileImagePath = await ProfileService.instance.profileImagePath;
      } catch (e) {
        print('Error loading profile image: $e');
        profileImagePath = null;
      }
      
      // Check if user is logged in
      if (!authProvider.isLoggedIn) {
        print('User not logged in - using guest data');
        setState(() {
          _userName = 'Guest User';
          _userEmail = '';
          _userPhone = '';
          _profileImagePath = null;
        });
        return;
      }
      
      // Get profile data using AuthProvider methods (which handle API data + fallbacks)
      final name = await authProvider.getProfileName();
      final email = await authProvider.getProfileEmail();
      final mobile = await authProvider.getProfileMobile();
      
      setState(() {
        _userName = name.isNotEmpty ? name : 'User';
        _userEmail = email;
        _userPhone = mobile;
        _profileImagePath = profileImagePath;
      });
      
      // Load card details from API
      await _loadCardData();
      
      print('=== Profile Data Loaded ===');
      print('Name: $_userName');
      print('Email: $_userEmail');
      print('Phone: $_userPhone');
      print('Profile Image: $_profileImagePath');
      print('Card Number: $_cardNumber');
      print('============================');
      
    } catch (e) {
      print('Error loading profile data: $e');
      // Final fallback
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String phone = authProvider.phoneNumber ?? '';
      if (phone.startsWith('+91')) {
        phone = phone.substring(3).trim();
      }
      
      setState(() {
        _userName = authProvider.userName ?? 'User';
        _userEmail = authProvider.email ?? '';
        _userPhone = phone;
        _profileImagePath = null;
      });
    }
  }

  Future<void> _loadCardData() async {
    try {
      // Get card details from API data
      final cardNumber = await _getCardNumber();
      final cvv = await _getCVV();
      final validity = await _getValidity();
      
      setState(() {
        _cardNumber = cardNumber;
        _cvv = cvv;
        _validity = validity;
      });
      
      print('=== Card Data Loaded ===');
      print('Card Number: $_cardNumber');
      print('CVV: $_cvv');
      print('Validity: $_validity');
      
      // Debug: Check raw API data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiData = await authProvider.getApiProfileData();
      if (apiData != null) {
        print('=== Raw API Card Data ===');
        print('CardNo: ${apiData['CardNo']}');
        print('CardCVV: ${apiData['CardCVV']}');
        print('CardValidity: ${apiData['CardValidity']}');
        print('========================');
      }
      print('========================');
      
    } catch (e) {
      print('Error loading card data: $e');
      // Use fallback generation methods
      setState(() {
        _cardNumber = _generateCardNumber();
        _cvv = _generateCVV();
        _validity = '12/28';
      });
    }
  }

  Future<String> _getCardNumber() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiData = await authProvider.getApiProfileData();
      
      if (apiData != null) {
        String apiCardNo = apiData['CardNo'] ?? '';
        if (apiCardNo.isNotEmpty) {
          // Format the card number with spaces
          return _formatCardNumber(apiCardNo);
        }
      }
      
      // Fallback to generated card number
      return _generateCardNumber();
    } catch (e) {
      print('Error getting card number from API: $e');
      return _generateCardNumber();
    }
  }

  Future<String> _getCVV() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiData = await authProvider.getApiProfileData();
      
      if (apiData != null) {
        // Check for CVV from API data
        String apiCVV = apiData['CardCVV'] ?? '';
        if (apiCVV.isNotEmpty) {
          return apiCVV;
        }
        
        // If no CVV from API, generate it consistently based on card number
        String apiCardNo = apiData['CardNo'] ?? '';
        if (apiCardNo.isNotEmpty) {
          return _generateCVVFromCardNumber(apiCardNo);
        }
      }
      
      // Fallback to original CVV generation
      return _generateCVV();
    } catch (e) {
      print('Error getting CVV from API: $e');
      return _generateCVV();
    }
  }

  Future<String> _getValidity() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiData = await authProvider.getApiProfileData();
      
      if (apiData != null) {
        // Check for card validity from API data
        String apiValidity = apiData['CardValidity'] ?? '';
        if (apiValidity.isNotEmpty) {
          return apiValidity;
        }
      }
      
      // Fallback to default validity
      return '12/28';
    } catch (e) {
      print('Error getting validity from API: $e');
      return '12/28';
    }
  }

  String _formatCardNumber(String cardNumber) {
    // Remove any existing spaces and format with spaces every 4 digits
    String cleaned = cardNumber.replaceAll(' ', '');
    
    if (cleaned.length >= 16) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)} ${cleaned.substring(12, 16)}';
    } else if (cleaned.length >= 12) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8, 12)} ${cleaned.substring(12)}';
    } else if (cleaned.length >= 8) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8)}';
    } else if (cleaned.length >= 4) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
    }
    
    return cleaned;
  }

  String _generateCVVFromCardNumber(String cardNumber) {
    // Generate CVV based on card number for consistency
    String cleaned = cardNumber.replaceAll(' ', '');
    int sum = 0;
    
    for (int i = 0; i < cleaned.length; i++) {
      if (int.tryParse(cleaned[i]) != null) {
        sum += int.parse(cleaned[i]);
      }
    }
    
    final cvv = (sum % 900 + 100).toString(); // Ensures 3-digit number
    return cvv;
  }

  void _flipCard() {
    if (!_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  String _generateCardNumber() {
    // Generate a unique card number based on user's phone number or ID
    // For demo purposes, we'll use a random-looking but consistent number
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String phoneNumber = authProvider.phoneNumber ?? '';
    
    // Clean phone number - remove +91 prefix if present
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3).trim();
    }
    
    // Use last 4 digits of phone number to make it user-specific
    final lastFour = phoneNumber.length >= 4 
        ? phoneNumber.substring(phoneNumber.length - 4)
        : '1005';
    
    return '4521 1234 5678 $lastFour';
  }

  String _generateCVV() {
    // Generate a CVV number based on user data for consistency
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String phoneNumber = authProvider.phoneNumber ?? '';
    
    // Clean phone number - remove +91 prefix if present
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3).trim();
    }
    
    // Use phone number to generate consistent CVV
    int sum = 0;
    for (int i = 0; i < phoneNumber.length; i++) {
      if (phoneNumber[i].isNotEmpty && int.tryParse(phoneNumber[i]) != null) {
        sum += int.parse(phoneNumber[i]);
      }
    }
    final cvv = (sum % 900 + 100).toString(); // Ensures 3-digit number
    return cvv;
  }

  // Helper method to generate avatar widget
  Widget _buildAvatarWidget({required double size, double? fontSize}) {
    if (_profileImagePath != null && File(_profileImagePath!).existsSync()) {
      return Image.file(
        File(_profileImagePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(size: size, fontSize: fontSize);
        },
      );
    } else {
      return _buildInitialsAvatar(size: size, fontSize: fontSize);
    }
  }

  // Helper method to build initials avatar
  Widget _buildInitialsAvatar({required double size, double? fontSize}) {
    String initials = _getInitials(_userName);
    Color avatarColor = _getAvatarColor(_userName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize ?? (size * 0.4),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty || name == 'Guest User' || name == 'User') {
      return 'U';
    }
    
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  // Helper method to get avatar color based on name
  Color _getAvatarColor(String name) {
    if (name.isEmpty || name == 'Guest User' || name == 'User') {
      return Colors.grey[600]!;
    }
    
    // Generate color based on name hash
    int hash = name.hashCode;
    List<Color> colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
    ];
    
    return colors[hash.abs() % colors.length];
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(),
                  
                  // Profile Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Profile Header
                          _buildProfileHeader(),
                          
                          const SizedBox(height: 16),

                          // Jaikisan Card
                          _buildJaikisanCard(),
                          
                          const SizedBox(height: 16),
                          
                          // Menu Options
                          _buildMenuOptions(),
                          
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          const SizedBox(width: 16),
          
          const Expanded(
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Info Row
          Row(
            children: [
              // Profile Picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipOval(
                  child: _buildAvatarWidget(size: 50, fontSize: 20),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Name and Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.length > 20 ? '${_userName.substring(0, 17)}...' : _userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Manage Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileManagementScreen(),
                    ),
                  ).then((_) {
                    // Reload profile data when returning
                    _loadProfileData();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // QR Codes & UPI IDs Section
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.qr_code,
                  label: 'QR codes &\nJMI IDs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRCodeUPIScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.payment,
                  label: 'Manage\npayments',
                  onTap: () => _launchURL('https://cityride.city/comming-soon', title: 'Manage Payments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJaikisanCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _flipController,
          builder: (context, child) {
            final isShowingFront = _flipController.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipController.value * math.pi),
              child: isShowingFront ? _buildCardFront() : _buildCardBack(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 215, // Increased height to prevent overflow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFDC143C), // Deep red
            Color(0xFFB71C1C), // Darker red
            Color(0xFF8B0000), // Very dark red
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern/texture
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Diagonal texture pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: CardTexturePainter(),
              ),
            ),
          ),
          
          // Circular pattern overlay
          Positioned(
            right: -50,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Bottom right pattern
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Left side accent
          Positioned(
            left: -30,
            top: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row - Logo and Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Jaikisan Card Logo/Text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jaikisan Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gateway to Rural India',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    
                    // Jaikisan.net logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Jaikisan Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // User Photo (positioned on left side)
                const SizedBox(height: 15), // Reduced spacing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Photo
                    Container(
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildAvatarWidget(size: 50, fontSize: 18),
                      ),
                    ),
                    
                    const SizedBox(width: 8), // Fixed spacing instead of Spacer
                    
                    // Card Number and User Name - Flexible to prevent overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _cardNumber.isNotEmpty ? _cardNumber : _generateCardNumber(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16, // Reduced font size slightly
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5, // Reduced letter spacing
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis, // Handle overflow
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14, // Reduced font size slightly
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, // Reduced letter spacing
                              shadows: [
                                Shadow(
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 1.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis, // Handle overflow
                            maxLines: 1, // Ensure single line
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10), // Using fixed height instead of Spacer to better control layout
                
                // Bottom Row - Additional Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valid Till: ${_validity.isNotEmpty ? _validity : '12/28'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // V2C Bazaar Logo
                    Container(
                      height: 45, // Slightly reduced height
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.asset(
                          'assets/logos/J&KBank.png',
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Attractive fallback with Jaikisan Card branding
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'J&K',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 6,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Bank',
                                    style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFDC143C), // Deep red
              Color(0xFFB71C1C), // Darker red
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern/texture
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Magnetic Stripe
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                color: Colors.black,
              ),
            ),
            
            // Card Back Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 35), // Space for magnetic stripe
                  
                  // Card Number
                  Text(
                    'Card Number: ${_cardNumber.isNotEmpty ? _cardNumber : _generateCardNumber()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Validity and CVV Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Valid Thru',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 7,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _validity.isNotEmpty ? _validity : '12/28',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CVV',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 7,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _cvv.isNotEmpty ? _cvv : _generateCVV(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MPIN',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 7,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '****',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Security features text (shorter)
                  Text(
                    'Property of Jaikisan Card. Use constitutes acceptance of terms.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 7,
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Bottom info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Service: 1800-J&K-BANK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 7,
                        ),
                      ),
                      // V2C Bazaar Logo
                      Container(
                        height: 14,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/logos/J&KBank.png',
                            height: 14,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Attractive fallback with Jaikisan Card branding
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 1,
                                      offset: const Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'J&K',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 4,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Bank',
                                      style: TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preferences Section Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Menu Items
          // _buildMenuItem(
          //   icon: Icons.language,
          //   title: 'Languages',
          //   onTap: () => _handleMenuTap('Languages'),
          // ),
          
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Bill notifications',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () => _handleMenuTap('Bill notifications'),
          ),
          
          _buildMenuItem(
            icon: Icons.security,
            title: 'Permissions',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () => _handleMenuTap('Permissions'),
          ),
          
          _buildMenuItem(
            icon: Icons.palette_outlined,
            title: 'Theme',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () => _handleMenuTap('Theme'),
          ),
          
          _buildMenuItem(
            icon: Icons.access_time,
            title: 'Reminders',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () => _handleMenuTap('Reminders'),
          ),
          
          const SizedBox(height: 16),
          
          // Security Section Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'SECURITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.fingerprint,
            title: 'Biometric & screen lock',
            trailing: Switch(
              value: _securityEnabled,
              onChanged: (value) {
                // Navigate to security settings instead of just toggling
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                ).then((_) {
                  // Reload settings when returning from security settings
                  _loadSecuritySettings();
                });
              },
              activeColor: const Color(0xFF4CAF50),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsScreen(),
                ),
              ).then((_) {
                // Reload settings when returning from security settings
                _loadSecuritySettings();
              });
            },
          ),

          _buildMenuItem(
            icon: Icons.vpn_key,
            title: 'Change Passcode',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasscodeScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Account Section Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Icon(
        icon,
        color: Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
      ) : null,
      trailing: trailing,
    );
  }

  void _handleMenuTap(String menu) {
    // Open specific URL for each menu option
    String title = menu;
    _launchURL('https://cityride.city/comming-soon', title: title);
  }

  // Helper method to open URLs in in-app browser
  void _launchURL(String url, {String title = 'Coming Soon'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppBrowserScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await SecurityService.instance.clearSecurityData();
                await authProvider.logout();
                context.go('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class CardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // More visible diagonal lines pattern
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Create diagonal lines pattern
    const spacing = 12.0;
    
    // Draw diagonal lines from top-left to bottom-right
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    
    // Create opposite diagonal lines for crosshatch effect
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    for (double i = 0; i < size.width + size.height; i += spacing * 1.5) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i - size.height, 0),
        crossPaint,
      );
    }
    
    // Create a more visible dot pattern
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    const dotSpacing = 25.0;
    const dotRadius = 1.5;
    
    for (double x = dotSpacing; x < size.width; x += dotSpacing) {
      for (double y = dotSpacing; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
    
    // Add geometric pattern
    final geometricPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw small rectangles pattern
    const rectSize = 8.0;
    const rectSpacing = 20.0;
    
    for (double x = rectSpacing; x < size.width; x += rectSpacing) {
      for (double y = rectSpacing; y < size.height; y += rectSpacing) {
        canvas.drawRect(
          Rect.fromLTWH(x - rectSize/2, y - rectSize/2, rectSize, rectSize),
          geometricPaint,
        );
      }
    }
    
    // Add curved accent lines
    final curvePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.1,
      size.width * 0.6, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.6,
      size.width, size.height * 0.3,
    );
    
    canvas.drawPath(path, curvePaint);
    
    // Add another curved line
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.2, size.height * 0.9,
      size.width * 0.5, size.height * 0.6,
    );
    path2.quadraticBezierTo(
      size.width * 0.7, size.height * 0.4,
      size.width, size.height * 0.8,
    );
    
    canvas.drawPath(path2, curvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
