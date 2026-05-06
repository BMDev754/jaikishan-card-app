import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';
import '../../services/wallet_service.dart';

class PaymentScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final Contact? contact;
  final bool isRequest; // true for request money, false for pay money

  const PaymentScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.contact,
    this.isRequest = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isProcessing = false;
  double _currentAmount = 0.0;
  String _selectedQuickAmount = '';

  final List<double> _quickAmounts = [50, 100, 200, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    
    // Auto focus on amount field
    Future.delayed(const Duration(milliseconds: 800), () {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedQuickAmount = amount.toString();
      _currentAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
    HapticFeedback.lightImpact();
  }

  void _onAmountChanged(String value) {
    setState(() {
      _currentAmount = double.tryParse(value) ?? 0.0;
      _selectedQuickAmount = '';
    });
  }

  Future<void> _processPayment() async {
    if (_currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (!widget.isRequest) {
        // For payments, check wallet balance and deduct money
        final currentBalance = await WalletService.instance.walletBalance;
        
        if (_currentAmount > currentBalance) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Insufficient wallet balance'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Deduct money from wallet
        await WalletService.instance.deductMoneyFromWallet(
          amount: _currentAmount,
          title: 'Payment to ${widget.contactName}',
          description: _noteController.text.isEmpty ? 'Mobile payment' : _noteController.text,
        );
      }

      // Show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isRequest 
                ? 'Request for ₹${_currentAmount.toStringAsFixed(0)} sent to ${widget.contactName}'
                : 'Payment of ₹${_currentAmount.toStringAsFixed(0)} sent to ${widget.contactName}',
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Contact Card
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildContactCard(initials, color),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Amount Section
                      _buildAmountSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Quick Amount Buttons
                      _buildQuickAmountSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Note Section
                      _buildNoteSection(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Button
              _buildBottomActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isRequest ? 'Request money' : 'Pay',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  widget.isRequest 
                      ? 'Ask ${widget.contactName} for money'
                      : 'Send money to ${widget.contactName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // Scanner Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Open QR scanner
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR Scanner coming soon')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String initials, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: widget.contact?.photo != null
                ? ClipOval(
                    child: Image.memory(
                      widget.contact!.photo!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Contact Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.phoneNumber.isNotEmpty)
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'JaiKisan User',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Verified Badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Enter amount',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Amount Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _currentAmount > 0 
                    ? const Color(0xFF4CAF50) 
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: _onAmountChanged,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 20, top: 20),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          
          if (_currentAmount > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Amount: ₹${_currentAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick amounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickAmounts.map((amount) {
            final isSelected = _selectedQuickAmount == amount.toString();
            return GestureDetector(
              onTap: () => _selectQuickAmount(amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF4CAF50) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF4CAF50) 
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected 
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                color: Color(0xFF666666),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Add a note (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What\'s this for?',
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    final isValid = _currentAmount > 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wallet Balance (for pay only)
          if (!widget.isRequest)
            FutureBuilder<double>(
              future: WalletService.instance.walletBalance,
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                final hasInsufficientFunds = _currentAmount > balance;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: hasInsufficientFunds 
                        ? const Color(0xFFFFEBEE) 
                        : const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: hasInsufficientFunds 
                            ? const Color(0xFFF44336) 
                            : const Color(0xFF2196F3),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wallet Balance: ₹${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasInsufficientFunds 
                              ? const Color(0xFFF44336) 
                              : const Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasInsufficientFunds && _currentAmount > 0) ...[
                        const Spacer(),
                        const Text(
                          'Insufficient funds',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF44336),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid && !_isProcessing ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isRequest 
                    ? const Color(0xFF2196F3) 
                    : const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isRequest 
                              ? Icons.request_page 
                              : Icons.send,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isRequest 
                              ? 'Request ₹${_currentAmount.toStringAsFixed(0)}'
                              : 'Pay ₹${_currentAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}
