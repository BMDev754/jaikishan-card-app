import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pin_verification_screen.dart';
import 'add_money_screen.dart';
import '../transaction/transaction_history_screen.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/api/api_service.dart';

class WalletBalanceScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const WalletBalanceScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<WalletBalanceScreen> createState() => _WalletBalanceScreenState();
}

class _WalletBalanceScreenState extends State<WalletBalanceScreen>
    with TickerProviderStateMixin {
  bool _isBalanceVisible = false;
  double _walletBalance = 0.0; // Start with 0 balance
  bool _isLoadingBalance = false;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));

    // Load wallet balance
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      // Get user credentials from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = await authProvider.getProfileEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      // Get ContactID dynamically from API profile data
      final contactID = await authProvider.getContactID();
      
      if (userEmail.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        print('Missing user credentials for balance API call');
        print('Email: $userEmail, TokenCode: ${tokenCode.isNotEmpty ? "present" : "missing"}, ContactID: $contactID');
        if (mounted) {
          setState(() {
            _walletBalance = 0.0;
            _isLoadingBalance = false;
          });
        }
        return;
      }

      print('Using ContactID: $contactID for balance API call');
      final balanceData = await ApiService.getLedgerBalanceByID(userEmail, tokenCode, contactID);
      
      if (balanceData['success'] == true && 
          balanceData['data'] != null &&
          balanceData['data']['currentbalance'] != null) {
        
        final List<dynamic> balanceList = balanceData['data']['currentbalance'];
        
        if (balanceList.isNotEmpty) {
          // Get balance from API response
          final balanceValue = balanceList[0]['Balance'];
          double balance = 0.0;
          
          if (balanceValue != null) {
            if (balanceValue is double) {
              balance = balanceValue;
            } else if (balanceValue is int) {
              balance = balanceValue.toDouble();
            } else if (balanceValue is String) {
              balance = double.tryParse(balanceValue) ?? 0.0;
            }
          }

          if (mounted) {
            setState(() {
              _walletBalance = balance;
              _isLoadingBalance = false;
            });
          }
        } else {
          // No balance data - set to 0.00
          if (mounted) {
            setState(() {
              _walletBalance = 0.0;
              _isLoadingBalance = false;
            });
          }
        }
      } else {
        // API failed - set balance to 0.00
        if (mounted) {
          setState(() {
            _walletBalance = 0.0;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
      if (mounted) {
        setState(() {
          _walletBalance = 0.0;
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _onWalletCardTap() async {
    // Scale animation for card press
    await _cardAnimationController.forward();
    await _cardAnimationController.reverse();

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Navigate to PIN verification
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinVerificationScreen(),
      ),
    );

    if (result == true) {
      // PIN verified successfully, show balance
      setState(() {
        _isBalanceVisible = true;
      });
    }
  }

  void _completeOnboarding() async {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.completeWalletIntroStep();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to JaiKisan! Setup completed successfully.'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    }
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
          'Wallet Balance',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.more_vert, color: Colors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info
            _buildHeaderInfo(),
            
            // Wallet Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWalletCard(),
                    const SizedBox(height: 40),
                    if (!_isBalanceVisible) _buildTapInstruction(),
                    if (_isBalanceVisible) _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isOnboarding 
        ? FloatingActionButton.extended(
            onPressed: _completeOnboarding,
            backgroundColor: const Color(0xFF4CAF50),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Complete Setup',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          )
        : FloatingActionButton.extended(
            onPressed: _showAddMoneyOptions,
            backgroundColor: const Color(0xFF6A11CB),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Money',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
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
              color: const Color(0xFF0066FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF0066FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jaikisan Wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Secure & Fast Payments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return AnimatedBuilder(
      animation: _cardScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: GestureDetector(
            onTap: _onWalletCardTap,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6A11CB),
                    Color(0xFF2575FC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  
                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jaikisan Wallet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_isLoadingBalance && _isBalanceVisible)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                _isBalanceVisible ? '₹ ${_walletBalance.toStringAsFixed(2)}' : '₹ ****',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(width: 12),
                            if (!_isBalanceVisible)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tap to view',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Last updated: Just now',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildTapInstruction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.touch_app,
            color: Color(0xFF2196F3),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Tap on the wallet card above',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Enter your PIN to view your balance securely',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        // Add Money Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: _showAddMoneyOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'Add Money to Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Transaction History',
                  Icons.history,
                  const Color(0xFF2196F3),
                  () => _navigateToTransactionHistory(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Wallet Stats',
                  Icons.analytics_outlined,
                  const Color(0xFF6A11CB),
                  () => _showWalletStats(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    );
  }

  void _showWalletStats() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading wallet statistics...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Get user credentials from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = await authProvider.getProfileEmail();
      final tokenCode = await authProvider.getTokenCode();
      final contactID = await authProvider.getContactID();
      
      if (userEmail.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error and fallback to local data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load wallet statistics from server'),
            backgroundColor: Colors.orange,
          ),
        );
        _showLocalWalletStats();
        return;
      }

      // Get wallet statistics from API
      final balanceData = await ApiService.getLedgerBalanceByID(userEmail, tokenCode, contactID);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (balanceData['success'] == true && balanceData['data'] != null) {
        _showApiWalletStats(balanceData['data']);
      } else {
        // API failed - show local stats as fallback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server data unavailable, showing local data'),
            backgroundColor: Colors.orange,
          ),
        );
        _showLocalWalletStats();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      print('Error loading wallet stats from API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load statistics, showing local data'),
          backgroundColor: Colors.red,
        ),
      );
      _showLocalWalletStats();
    }
  }

  void _showApiWalletStats(Map<String, dynamic> apiData) {
    // Extract data from API response
    double currentBalance = 0.0;
    double totalCredit = 0.0; // Added amount (Credit)
    double totalDebit = 0.0;  // Deducted amount (Debit)

    // Debug: Print the entire API response structure
    print('API Data Structure: $apiData');

    // Get current balance and transaction totals from currentbalance
    if (apiData['currentbalance'] != null) {
      final List<dynamic> balanceList = apiData['currentbalance'];
      if (balanceList.isNotEmpty) {
        final balanceData = balanceList[0];
        
        // Extract Balance
        final balanceValue = balanceData['Balance'];
        if (balanceValue != null) {
          if (balanceValue is double) {
            currentBalance = balanceValue;
          } else if (balanceValue is int) {
            currentBalance = balanceValue.toDouble();
          } else if (balanceValue is String) {
            currentBalance = double.tryParse(balanceValue) ?? 0.0;
          }
        }
        
        // Extract Added amount (Credit)
        final addedValue = balanceData['Added'];
        if (addedValue != null) {
          if (addedValue is double) {
            totalCredit = addedValue;
          } else if (addedValue is int) {
            totalCredit = addedValue.toDouble();
          } else if (addedValue is String) {
            totalCredit = double.tryParse(addedValue) ?? 0.0;
          }
        }
        
        // Extract Deducted amount (Debit)
        final deductedValue = balanceData['Deducted'];
        if (deductedValue != null) {
          if (deductedValue is double) {
            totalDebit = deductedValue;
          } else if (deductedValue is int) {
            totalDebit = deductedValue.toDouble();
          } else if (deductedValue is String) {
            totalDebit = double.tryParse(deductedValue) ?? 0.0;
          }
        }
        
        print('Extracted values - Balance: $currentBalance, Added (Credit): $totalCredit, Deducted (Debit): $totalDebit');
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF6A11CB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Wallet Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildStatRow('Current Balance', '₹${currentBalance.toStringAsFixed(2)}', const Color(0xFF4CAF50)),
              const SizedBox(height: 12),
              _buildStatRow('Total Added (Credit)', '₹${totalCredit.toStringAsFixed(2)}', const Color(0xFF2196F3)),
              const SizedBox(height: 12),
              _buildStatRow('Total Deducted (Debit)', '₹${totalDebit.toStringAsFixed(2)}', const Color(0xFFF44336)),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF2196F3),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live data from server - Added: money added to wallet, Deducted: money spent from wallet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showLocalWalletStats() async {
    final totalAdded = await WalletService.instance.totalAmountAdded;
    final totalSpent = await WalletService.instance.totalAmountSpent;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF6A11CB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Wallet Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LOCAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildStatRow('Current Balance', '₹${_walletBalance.toStringAsFixed(2)}', const Color(0xFF4CAF50)),
              const SizedBox(height: 12),
              _buildStatRow('Total Added', '₹${totalAdded.toStringAsFixed(2)}', const Color(0xFF2196F3)),
              const SizedBox(height: 12),
              _buildStatRow('Total Spent', '₹${totalSpent.toStringAsFixed(2)}', const Color(0xFFF44336)),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.storage,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Local data - some information may be limited',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddMoneyOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMoneyScreen(),
      ),
    ).then((_) {
      // Reload wallet balance when returning from add money screen
      _loadWalletBalance();
    });
  }
}
