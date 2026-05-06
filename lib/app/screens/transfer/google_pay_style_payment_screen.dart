import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';
import '../../services/wallet_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import '../wallet/pin_verification_screen.dart';
import 'payment_success_history_screen.dart';

class GooglePayStylePaymentScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final Contact? contact;
  final bool isRequest;
  final String? contactID; // Add ContactID parameter for API

  const GooglePayStylePaymentScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.contact,
    this.isRequest = false,
    this.contactID, // Add ContactID parameter
  });

  @override
  State<GooglePayStylePaymentScreen> createState() => _GooglePayStylePaymentScreenState();
}

class _GooglePayStylePaymentScreenState extends State<GooglePayStylePaymentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _remarksFocusNode = FocusNode();
  
  double _enteredAmount = 0.0;
  bool _showPaymentOptions = false;
  String _selectedPaymentMethod = 'wallet';
  double _walletBalance = 0.0;
  bool _isProcessing = false;
  String? _transactionResult; // Store transaction result
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _loadWalletBalance();
    
    // Auto focus on amount field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  Future<void> _loadWalletBalance() async {
    try {
      // First show local balance immediately for better UX
      final localBalance = await WalletService.instance.walletBalance;
      setState(() {
        _walletBalance = localBalance;
      });
      
      // Then fetch updated balance from API
      final apiBalance = await WalletService.instance.getWalletBalanceFromAPI();
      setState(() {
        _walletBalance = apiBalance;
      });
      
      print('Wallet balance loaded: ₹$_walletBalance');
    } catch (e) {
      print('Error loading wallet balance: $e');
      // Fallback to local balance
      final localBalance = await WalletService.instance.walletBalance;
      setState(() {
        _walletBalance = localBalance;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _amountFocusNode.dispose();
    _remarksFocusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _enteredAmount = amount;
      // Remove automatic showing of payment options when amount changes
      // Payment options will only show when user explicitly confirms the amount
    });
  }

  void _selectQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    _onAmountChanged(amount.toStringAsFixed(0));
  }

  void _confirmAmount() {
    if (_enteredAmount > 0 && !_showPaymentOptions) {
      setState(() {
        _showPaymentOptions = true;
      });
      _slideController.forward();
      _fadeController.forward();
    }
  }

  Future<void> _processPayment() async {
    if (_enteredAmount <= 0) return;
    
    if (_selectedPaymentMethod == 'wallet' && _enteredAmount > _walletBalance) {
      _showInsufficientBalanceDialog();
      return;
    }

    // Navigate to PIN verification
    final pinVerified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinVerificationScreen(),
      ),
    );

    if (pinVerified == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Get user credentials and ContactIDs for API call
        final authProvider = AuthProvider();
        await authProvider.initialize();
        
        final email = await authProvider.getApiUserEmail();
        final tokenCode = await authProvider.getTokenCode();
        final senderContactID = await authProvider.getContactID();
        
        // Use provided ContactID as receiver, or fallback to sender's ContactID for testing
        final receiverContactID = widget.contactID ?? senderContactID;
        
        if (email.isEmpty || tokenCode.isEmpty || senderContactID.isEmpty) {
          throw Exception('Missing user credentials for API call');
        }

        // Get remarks from controller, or use default
        final remarks = _remarksController.text.trim().isEmpty 
            ? 'Payment to ${widget.contactName}'
            : _remarksController.text.trim();

        print('Processing payment via API:');
        print('Sender: $senderContactID');
        print('Receiver: $receiverContactID');
        print('Amount: $_enteredAmount');
        print('Remarks: $remarks');

        // Call the send money API
        final result = await ApiService.sendAmountToMember(
          email: email,
          tokenCode: tokenCode,
          senderContactID: senderContactID,
          receiverContactID: receiverContactID,
          amount: _enteredAmount.toStringAsFixed(0),
          remarks: remarks,
        );

        if (result['success'] == true) {
          // Store transaction result for success dialog
          _transactionResult = result['voucherNumber'] ?? '';
          
          // Update local wallet balance if payment was successful
          if (_selectedPaymentMethod == 'wallet') {
            await WalletService.instance.deductMoneyFromWallet(
              amount: _enteredAmount,
              title: widget.isRequest ? 'Money Request' : 'Payment to ${widget.contactName}',
              description: remarks,
              referenceNumber: result['voucherNumber'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
            );
          }

          _showSuccessDialog();
        } else {
          _showErrorDialog(result['message'] ?? 'Payment failed. Please try again.');
        }
      } catch (e) {
        print('Payment error: $e');
        _showErrorDialog('Payment failed: ${e.toString()}');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = ContactService.getInitials(widget.contactName);
    final color = ContactService.getColorForContact(widget.contactName);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Contact Info
                        _buildContactInfo(initials, color),
                        
                        const SizedBox(height: 40),
                        
                        // Amount Input Section
                        _buildAmountInput(),
                        
                        const SizedBox(height: 20),
                        
                        // Remarks Input Section
                        _buildRemarksInput(),
                        
                        const SizedBox(height: 20),
                        
                        // Quick Amount Selection
                        _buildQuickAmounts(),
                        
                        const SizedBox(height: 150), // Space for payment options
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Payment Options (Slide up from bottom)
          if (_showPaymentOptions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPaymentOptions(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String initials, Color color) {
    return Column(
      children: [
        // Profile Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: widget.contact?.photo != null
              ? ClipOval(
                  child: Image.memory(
                    widget.contact!.photo!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        
        const SizedBox(height: 16),
        
        // Contact Name
        Text(
          widget.contactName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Banking Name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Banking name: ${widget.contactName.split(' ').first.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Phone Number
        if (widget.phoneNumber.isNotEmpty)
          Text(
            widget.phoneNumber,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        // "Enter amount" label
        Text(
          widget.isRequest ? 'Enter amount to request' : 'Enter amount to send',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Amount Input Field
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '₹',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w300,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: _onAmountChanged,
                  onSubmitted: (value) {
                    // When user presses Done/Enter on keyboard, show payment options
                    if (_enteredAmount > 0 && _enteredAmount <= 100000) {
                      _confirmAmount();
                    }
                  },
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFCCCCCC),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Amount validation
        if (_enteredAmount > 0)
          Text(
            _enteredAmount > 100000 
                ? 'Maximum amount is ₹1,00,000'
                : _enteredAmount < 1
                    ? 'Minimum amount is ₹1'
                    : '',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildRemarksInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Add a note" label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Add a note (optional)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Remarks Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _remarksController,
            focusNode: _remarksFocusNode,
            maxLength: 100,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: 'e.g., For dinner, Gift, etc.',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Hide character counter
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      children: [
        const Text(
          'Quick amounts',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _quickAmounts.map((amount) {
            return GestureDetector(
              onTap: () => _selectQuickAmount(amount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _enteredAmount == amount 
                        ? const Color(0xFF2196F3) 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _enteredAmount == amount 
                        ? const Color(0xFF2196F3)
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Choose account label
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Choose account to pay with',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Wallet Card Option
          _buildWalletCard(),
          
          const SizedBox(height: 8),
          
          // Card Option (placeholder) - HIDDEN
          /*
          _buildPaymentMethodCard(
            'card',
            'Debit Card',
            '**** 1234',
            Icons.credit_card,
            const Color(0xFF2196F3),
          ),
          */
          
          const SizedBox(height: 24),
          
          // Pay Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enteredAmount > 0 && !_isProcessing ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.isRequest 
                            ? 'Request ₹${_enteredAmount.toStringAsFixed(0)}'
                            : 'Pay ₹${_enteredAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final isSelected = _selectedPaymentMethod == 'wallet';
    final color = const Color(0xFF4CAF50);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = 'wallet';
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'JaiKisan Wallet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadWalletBalance,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: color,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live balance from JaiKisan Wallet',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: Text(
          'Your wallet balance is ₹${_walletBalance.toStringAsFixed(2)}. Please add money to your wallet or choose a different payment method.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to add money screen
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isRequest ? 'Request Sent!' : 'Payment Successful!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isRequest 
                    ? '₹${_enteredAmount.toStringAsFixed(0)} request sent to ${widget.contactName}'
                    : '₹${_enteredAmount.toStringAsFixed(0)} sent to ${widget.contactName} successfully',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              // Show transaction ID if available
              if (_transactionResult != null && _transactionResult!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Transaction ID: $_transactionResult',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to contact detail
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to contact detail
                        
                        // Navigate to payment history screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentSuccessHistoryScreen(
                              contactName: widget.contactName,
                              contactPhone: widget.phoneNumber,
                              amount: _enteredAmount,
                              isPayment: !widget.isRequest,
                              transactionId: _transactionResult ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View History'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
