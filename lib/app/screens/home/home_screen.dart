import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/qr_scanner_service.dart';
import '../../services/profile_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../transfer/mobile_transfer_screen.dart';
import '../transfer/google_pay_style_payment_screen.dart';
import '../bank/self_account_screen.dart';
import '../wallet/wallet_balance_screen.dart';
import '../transfer/contact_detail_screen.dart';
import '../transaction/transaction_history_screen.dart';
import '../webview/in_app_browser_screen.dart';
import '../transfer/contact_transaction_history_screen.dart';
import '../pos/pos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMorePeople = false;
  String? _profileImagePath;
  String _userName = 'User';
  List<Map<String, dynamic>> _contactsWithTransactions = [];
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    
    // Delay the API call to ensure AuthProvider is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContactsWithTransactions();
    });
    
    // Check onboarding immediately when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingFlow();
    });
  }

  Future<void> _checkOnboardingFlow() async {
    if (!mounted) return;
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    // Re-initialize onboarding to get latest state
    await onboardingProvider.initializeOnboarding();
    
    // Disable automatic onboarding navigation to prevent opening manage profile automatically
    // User can manually access onboarding features through the app menu
    
    // Only show welcome dialog if onboarding was just completed
    if (onboardingProvider.currentStep == OnboardingStep.completed && 
               onboardingProvider.isFirstTime) {
      // Show welcome dialog when onboarding is completed
      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_outlined,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to JaiKisan!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account setup is complete. You can now enjoy all the features of Jaikisan Card!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A11CB),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile image when dependencies change
    _loadProfileImage();
    
    // Reload contacts with transactions when dependencies change
    _loadContactsWithTransactions();
    
    // Check onboarding flow again when dependencies change (like after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkOnboardingFlow();
      }
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      // Get profile image from ProfileService
      final imagePath = await ProfileService.instance.profileImagePath;
      
      // Get user name from AuthProvider API data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userName = await authProvider.getProfileName();
      
      if (mounted) {
        setState(() {
          _profileImagePath = imagePath;
          _userName = userName;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _loadContactsWithTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      // Get user credentials from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait a bit for AuthProvider to initialize if needed
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userEmail = await authProvider.getProfileEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      print('Home Screen API Call - Email: ${userEmail.isNotEmpty ? "present" : "missing"}, Token: ${tokenCode.isNotEmpty ? "present" : "missing"}');
      
      if (userEmail.isEmpty || tokenCode.isEmpty) {
        print('Missing user credentials for API call - retrying in 2 seconds...');
        
        // Retry after a delay
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        final retryEmail = await authProvider.getProfileEmail();
        final retryToken = await authProvider.getTokenCode();
        
        print('Retry - Email: ${retryEmail.isNotEmpty ? "present" : "missing"}, Token: ${retryToken.isNotEmpty ? "present" : "missing"}');
        
        if (retryEmail.isEmpty || retryToken.isEmpty) {
          print('Still missing credentials after retry - hiding people section');
          if (mounted) {
            setState(() {
              _contactsWithTransactions = [];
              _isLoadingContacts = false;
            });
          }
          return;
        }
        
        // Use retry credentials
        final recentLedgerData = await ApiService.getRecentLedger(retryEmail, retryToken, await authProvider.getContactID());
        await _processApiResponse(recentLedgerData);
      } else {
        // Use original credentials
        final recentLedgerData = await ApiService.getRecentLedger(userEmail, tokenCode, await authProvider.getContactID());
        await _processApiResponse(recentLedgerData);
      }
    } catch (e) {
      print('Error loading recent ledger data: $e');
      if (mounted) {
        setState(() {
          _contactsWithTransactions = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _processApiResponse(Map<String, dynamic> recentLedgerData) async {
    // Check if API response has recentLedger data (direct structure)
    if (recentLedgerData['recentLedger'] != null) {
      final List<dynamic> ledgerList = recentLedgerData['recentLedger'];
      
      print('Home Screen - API returned ${ledgerList.length} contacts');
      
      if (ledgerList.isNotEmpty) {
        // Convert API data to the format expected by the UI
        final List<Map<String, dynamic>> contactsList = ledgerList.map<Map<String, dynamic>>((item) {
          final String contactName = item['ContactName'] ?? 'Unknown';
          final String transCount = item['TransCount']?.toString() ?? '0';
          final String? contactImage = item['ContactImageName'];
          final String contactID = item['ContactID']?.toString() ?? '';
          final String accountID = item['AccountID']?.toString() ?? '';
          
          // Generate avatar data
          final initial = contactName.isNotEmpty ? contactName[0].toUpperCase() : 'U';
          final colors = [
            const Color(0xFF673AB7),
            const Color(0xFFFF9800), 
            const Color(0xFF4CAF50),
            const Color(0xFF2196F3),
            const Color(0xFF9C27B0),
            const Color(0xFFE91E63),
            const Color(0xFF795548),
            const Color(0xFF607D8B),
          ];
          final color = colors[contactName.hashCode.abs() % colors.length];
          
          return {
            'name': contactName,
            'phone': '', // API doesn't provide phone in this response
            'initial': initial,
            'color': color,
            'transactionCount': int.tryParse(transCount) ?? 0,
            'contactImage': contactImage,
            'contactID': contactID, // Add ContactID from API
            'accountID': accountID, // Add AccountID from API
            'lastTransactionDate': DateTime.now(), // API doesn't provide date
            'lastTransactionAmount': 0.0, // API doesn't provide amount
          };
        }).toList();

        if (mounted) {
          setState(() {
            _contactsWithTransactions = contactsList;
            _isLoadingContacts = false;
          });
          print('Home Screen - Successfully loaded ${contactsList.length} contacts');
        }
      } else {
        // No data received - hide people section
        print('Home Screen - API returned empty contact list');
        if (mounted) {
          setState(() {
            _contactsWithTransactions = [];
            _isLoadingContacts = false;
          });
        }
      }
    } else {
      // API failed or returned no data - hide people section
      print('Home Screen - API call failed or returned invalid data');
      if (mounted) {
        setState(() {
          _contactsWithTransactions = [];
          _isLoadingContacts = false;
        });
      }
    }
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
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Welcome Banner
                      _buildWelcomeBanner(),
                      
                      // Money Transfer Section
                      _buildMoneyTransferSection(),

                      // People Section (Recent Transactions) - Only show if data exists or loading
                      if (_contactsWithTransactions.isNotEmpty || _isLoadingContacts)
                        _buildPeopleSection(),
                      
                      // Recharges & Bills Section
                      _buildRechargesAndBillsSection(),
                      
                      // Travel and More Section
                      _buildTravelAndMoreSection(),
                      
                      // Bottom padding to avoid overlap with floating button
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating Scan QR Button
        floatingActionButton: _buildFloatingQRButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: () => context.go('/account'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00BCD4), width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00BCD4),
                child: ClipOval(
                  child: _buildAvatarWidget(size: 36, fontSize: 14),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Win Amount Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF9800), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: Color(0xFFFF9800), size: 16),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Invite Friends, Get Rewards',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Color(0xFFFF9800), size: 14),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action Buttons
          // Search Icon - Hidden as per requirement
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.search, color: Colors.black87, size: 24),
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(),
          // ),
          
          // const SizedBox(width: 4),
          
          /*Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),*/
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send money to loved\nones on-the-go',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Use Jaikisan Card',
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Phone illustration
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'P',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 25,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Money symbol
                  Positioned(
                    top: 5,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyTransferSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Money Transfer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTransferOption(
                icon: Icons.qr_code_scanner,
                label: 'Scan & Pay',
                color: const Color(0xFF00BCD4),
              ),
              _buildTransferOption(
                icon: Icons.phone_android,
                label: 'To Mobile',
                color: const Color(0xFF4CAF50),
              ),
              /*
              _buildTransferOption(
                icon: Icons.person,
                label: 'To Self A/c',
                color: const Color(0xFF9C27B0),
              ),
              */
               // this is the pos option which is not implemented yet but we are keeping it for future use
              _buildTransferOption(
                icon: Icons.credit_card,
                label: 'POS',
                color: const Color(0xFFE91E63),
              ),
              _buildTransferOption(
                icon: Icons.account_balance,
                label: 'Balance',
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _handleTransferOptionTap(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTransferOptionTap(String option) async {
    if (option == 'Scan & Pay') {
      final result = await QRScannerService.scanQRCode(context);
      if (result != null && result.isNotEmpty) {
        // Check if the scanned QR code is in format "contactid@jaikisan"
        if (result.contains('@jaikisan')) {
          final contactID = result.split('@')[0];
          print('Extracted ContactID: $contactID');
          
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          try {
            // Get user credentials for API call
            final authProvider = AuthProvider();
            await authProvider.initialize();
            
            final email = await authProvider.getApiUserEmail();
            final tokenCode = await authProvider.getTokenCode();
            
            if (email.isEmpty || tokenCode.isEmpty) {
              Navigator.pop(context); // Close loading dialog
              throw Exception('Missing user credentials for API call');
            }
            
            // Call API to get member details
            final memberResult = await ApiService.getMemberByContactID(
              email: email,
              tokenCode: tokenCode,
              contactID: contactID,
            );
            
            Navigator.pop(context); // Close loading dialog
            
            if (memberResult['success'] == true) {
              final member = memberResult['member'];
              
              // Navigate to payment screen with member details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GooglePayStylePaymentScreen(
                    contactName: member['name'] ?? 'Unknown User',
                    phoneNumber: member['mobile'] ?? '',
                    contactID: contactID,
                    isRequest: false,
                  ),
                ),
              );
            } else {
              _showErrorDialog('Member not found: ${memberResult['message']}');
            }
          } catch (e) {
            Navigator.pop(context); // Close loading dialog
            print('Error processing QR scan: $e');
            _showErrorDialog('Failed to get member details: $e');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid QR Code format. Expected format: contactid@jaikisan'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else if (option == 'To Mobile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileTransferScreen(),
        ),
      );
    } else if (option == 'To Self A/c') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelfAccountScreen(),
        ),
      );
    } else if (option == 'POS') {
      // Navigate to POS screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const POSScreen(),
        ),
      );
    } else if (option == 'Balance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletBalanceScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$option functionality will be implemented'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF00BCD4),
        ),
      );
    }
  }



  Widget _buildPeopleSection() {
    // Show loading indicator when loading
    if (_isLoadingContacts) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading people...'),
              ],
            ),
          ),
        ),
      );
    }

    // Hide the entire section if no contacts with transactions
    if (_contactsWithTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Google Pay style layout
    final displayContacts = _showMorePeople 
        ? _contactsWithTransactions 
        : _contactsWithTransactions.take(7).toList();

    // First row: up to 4 contacts
    final firstRowContacts = displayContacts.take(4).toList();
    
    // Second row: up to 3 contacts + show more button if needed
    final secondRowContacts = displayContacts.length > 4 
        ? displayContacts.skip(4).take(3).toList() 
        : <Map<String, dynamic>>[];
    
    // Show "Show More" button only if there are more than 7 contacts and not showing more
    final showMoreButton = _contactsWithTransactions.length > 7 && !_showMorePeople;
    
    // Additional contacts when expanded (beyond first 7)
    final additionalContacts = _contactsWithTransactions.length > 7 
        ? _contactsWithTransactions.skip(7).toList() 
        : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'People',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (_showMorePeople && additionalContacts.isNotEmpty)
                GestureDetector(
                  onTap: () => _handleLessPeople(),
                  child: const Text(
                    'Show Less',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // First Row: 4 contacts
          if (firstRowContacts.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: firstRowContacts.map((contact) {
                return _buildPersonItem(
                  name: contact['name'] as String,
                  initial: contact['initial'] as String,
                  color: contact['color'] as Color,
                  phone: contact['phone'] as String,
                  transactionCount: contact['transactionCount'] as int,
                  contactID: contact['contactID'] as String?, // Pass ContactID
                );
              }).toList(),
            ),
          
          // Second Row: 3 contacts + Show More button (Google Pay style)
          if (secondRowContacts.isNotEmpty || showMoreButton) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Display up to 3 contacts in second row
                ...secondRowContacts.map((contact) {
                  return _buildPersonItem(
                    name: contact['name'] as String,
                    initial: contact['initial'] as String,
                    color: contact['color'] as Color,
                    phone: contact['phone'] as String,
                    transactionCount: contact['transactionCount'] as int,
                    contactID: contact['contactID'] as String?, // Pass ContactID
                  );
                }).toList(),
                
                // Add "Show More" circular button if needed
                if (showMoreButton)
                  _buildShowMoreButton(),
                
                // Add empty spaces to maintain 4-column layout
                ...List.generate(
                  4 - secondRowContacts.length - (showMoreButton ? 1 : 0),
                  (index) => const SizedBox(width: 70),
                ),
              ],
            ),
          ],
          
          // Expanded People Section (when showing more than 7)
          if (_showMorePeople && additionalContacts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'More Contacts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            
            // Display additional contacts in rows of 4
            for (int i = 0; i < additionalContacts.length; i += 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...additionalContacts
                        .skip(i)
                        .take(4)
                        .map((contact) => _buildPersonItem(
                              name: contact['name'] as String,
                              initial: contact['initial'] as String,
                              color: contact['color'] as Color,
                              phone: contact['phone'] as String,
                              transactionCount: contact['transactionCount'] as int,
                              contactID: contact['contactID'] as String?, // Pass ContactID
                            ))
                        .toList(),
                    // Add empty spaces to maintain 4-column layout
                    ...List.generate(
                      4 - additionalContacts.skip(i).take(4).length,
                      (index) => const SizedBox(width: 70),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowMoreButton() {
    final remainingCount = _contactsWithTransactions.length - 7;
    
    return GestureDetector(
      onTap: () => _handleMorePeople(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Color(0xFF00BCD4),
                    size: 20,
                  ),
                  Text(
                    '$remainingCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 70,
            child: Text(
              'More',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonItem({
    required String name,
    required String initial,
    required Color color,
    required String phone,
    required int transactionCount,
    String? contactID, // Add optional ContactID parameter
  }) {
    return GestureDetector(
      onTap: () => _handlePersonTap(name, phone, transactionCount, contactID),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePersonTap(String name, String phone, int transactionCount, String? contactID) {
    // If contact has previous transactions, open transaction history
    if (transactionCount > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContactTransactionHistoryScreen(
            contactName: name,
            phoneNumber: phone,
            contactID: contactID, // Pass ContactID from API
          ),
        ),
      );
    } else {
      // If no transactions, open contact detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContactDetailScreen(
            contactName: name,
            phoneNumber: phone,
            contact: null, // In a real app, you'd pass the actual Contact object
          ),
        ),
      );
    }
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

  void _handleMorePeople() {
    setState(() {
      _showMorePeople = true;
    });
  }

  void _handleLessPeople() {
    setState(() {
      _showMorePeople = false;
    });
  }

  Widget _buildRechargesAndBillsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recharges & Bills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton(
                onPressed: () => _handleViewAllRecharges(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRechargeOption(
                icon: Icons.phone_android,
                label: 'Mobile\nRecharge',
                color: const Color(0xFF4CAF50),
              ),
              _buildRechargeOption(
                icon: Icons.wifi,
                label: 'Data\nCard',
                color: const Color(0xFF00BCD4),
              ),
              _buildRechargeOption(
                icon: Icons.electrical_services,
                label: 'Electricity\nBill',
                color: const Color(0xFFFF9800),
              ),
              _buildRechargeOption(
                icon: Icons.local_gas_station,
                label: 'Gas\nBill',
                color: const Color(0xFFF44336),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Add New or View existing bills',
                  style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleViewAllRecharges() {
    // Open the coming soon URL for recharges section
    _launchURL('https://cityride.city/comming-soon', title: 'Recharges & Bills');
  }

  Widget _buildRechargeOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _handleRechargeOptionTap(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleRechargeOptionTap(String option) {
    // Open the coming soon URL for all recharge options
    _launchURL('https://cityride.city/comming-soon', title: option);
  }

  Widget _buildFloatingQRButton() {
    return Container(
      width: 120,
      height: 45,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleScanQR(),
          borderRadius: BorderRadius.circular(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Scan QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScanQR() async {
    final result = await QRScannerService.scanQRCode(context);
    if (result != null && result.isNotEmpty) {
      // Check if the scanned QR code is in format "contactid@jaikisan"
      if (result.contains('@jaikisan')) {
        final contactID = result.split('@')[0];
        print('Extracted ContactID: $contactID');
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Get user credentials for API call
          final authProvider = AuthProvider();
          await authProvider.initialize();
          
          final email = await authProvider.getApiUserEmail();
          final tokenCode = await authProvider.getTokenCode();
          
          if (email.isEmpty || tokenCode.isEmpty) {
            Navigator.pop(context); // Close loading dialog
            throw Exception('Missing user credentials for API call');
          }
          
          // Call API to get member details
          final memberResult = await ApiService.getMemberByContactID(
            email: email,
            tokenCode: tokenCode,
            contactID: contactID,
          );
          
          Navigator.pop(context); // Close loading dialog
          
          if (memberResult['success'] == true) {
            final member = memberResult['member'];
            
            // Navigate to payment screen with member details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GooglePayStylePaymentScreen(
                  contactName: member['name'] ?? 'Unknown User',
                  phoneNumber: member['mobile'] ?? '',
                  contactID: contactID,
                  isRequest: false,
                ),
              ),
            );
          } else {
            _showErrorDialog('Member not found: ${memberResult['message']}');
          }
        } catch (e) {
          Navigator.pop(context); // Close loading dialog
          print('Error processing QR scan: $e');
          _showErrorDialog('Failed to get member details: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR Code format. Expected format: contactid@jaikisan'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildTravelAndMoreSection() {
    return Column(
      children: [
        // Subscriptions and Gift Cards Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSubscriptionCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGiftCardsCard(),
              ),
            ],
          ),
        ),
        
        // Offers & Rewards Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offers & rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRewardOption(
                    icon: Icons.card_giftcard,
                    label: 'Rewards',
                    color: const Color(0xFFFFB300),
                    iconColor: Colors.white,
                  ),
                  _buildRewardOption(
                    icon: Icons.local_offer,
                    label: 'Offers',
                    color: const Color(0xFFE91E63),
                    iconColor: Colors.white,
                  ),
                  _buildRewardOption(
                    icon: Icons.people,
                    label: 'Referrals',
                    color: const Color(0xFF2196F3),
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // CIBIL Score Section
        GestureDetector(
          onTap: () => _launchURL('https://cityride.city/comming-soon', title: 'CIBIL Score'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.yellow.shade600,
                        Colors.red.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get your CIBIL score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Check for free and understand your financial health',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF00BCD4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        
        // Additional Services Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildServiceRow(
                icon: Icons.pie_chart,
                title: 'Check your CIBIL score for free',
                iconColor: const Color(0xFF2196F3),
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              _buildServiceRow(
                icon: Icons.history,
                title: 'See transaction history',
                iconColor: const Color(0xFF4CAF50),
              ),
              const Divider(height: 24, color: Color(0xFFE0E0E0)),
              _buildServiceRow(
                icon: Icons.account_balance,
                title: 'Check bank balance',
                iconColor: const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return GestureDetector(
      onTap: () => _handleSubscriptionTap(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.subscriptions,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Subscriptions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buy plans from brands like Spotify',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardsCard() {
    return GestureDetector(
      onTap: () => _handleGiftCardsTap(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gift cards',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buy gift cards from the biggest brands',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () => _handleRewardOptionTap(label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () => _handleServiceRowTap(title),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF999999),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _handleSubscriptionTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscriptions functionality will be implemented'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF9C27B0),
      ),
    );
  }

  void _handleGiftCardsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gift Cards functionality will be implemented'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _handleRewardOptionTap(String option) {
    // Open the coming soon URL for all reward options
    _launchURL('https://cityride.city/comming-soon', title: option);
  }

  void _handleServiceRowTap(String service) {
    if (service == 'See transaction history') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionHistoryScreen(),
        ),
      );
    } else if (service == 'Check bank balance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WalletBalanceScreen(),
        ),
      );
    } else if (service == 'Check your CIBIL score for free') {
      // Open the coming soon URL for CIBIL score
      _launchURL('https://cityride.city/comming-soon', title: 'CIBIL Score');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$service functionality will be implemented'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF00BCD4),
        ),
      );
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

}
