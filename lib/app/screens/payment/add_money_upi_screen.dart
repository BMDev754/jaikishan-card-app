import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/wallet_service.dart';

class AddMoneyUpiScreen extends StatefulWidget {
  final double amount;

  const AddMoneyUpiScreen({
    super.key,
    required this.amount,
  });

  @override
  State<AddMoneyUpiScreen> createState() => _AddMoneyUpiScreenState();
}

class _AddMoneyUpiScreenState extends State<AddMoneyUpiScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _upiIdController = TextEditingController();
  bool _isProcessing = false;
  String _selectedUpiApp = '';
  
  // Mock UPI ID for receiving payments
  final String _merchantUpiId = 'jaikisan@okaxis';
  final String _merchantName = 'Jaikisan Card';

  final List<Map<String, dynamic>> _upiApps = [
    {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'icon': Icons.payment,
      'color': const Color(0xFF4285F4),
    },
    {
      'name': 'PhonePe',
      'package': 'com.phonepe.app',
      'icon': Icons.phone_android,
      'color': const Color(0xFF5F259F),
    },
    {
      'name': 'Paytm',
      'package': 'net.one97.paytm',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF00BAF2),
    },
    {
      'name': 'BHIM',
      'package': 'in.org.npci.upiapp',
      'icon': Icons.payment,
      'color': const Color(0xFF00A693),
    },
    {
      'name': 'Amazon Pay',
      'package': 'in.amazon.mShop.android.shopping',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFFFF9900),
    },
    {
      'name': 'Other UPI App',
      'package': 'other',
      'icon': Icons.apps,
      'color': const Color(0xFF666666),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'UPI Payment',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF9800),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF9800),
          tabs: const [
            Tab(text: 'Pay via UPI'),
            Tab(text: 'UPI QR Code'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Amount Summary
          _buildAmountSummary(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpiPayTab(),
                _buildQrCodeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Amount to Pay',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'via UPI Payment',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiPayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPI Apps
          const Text(
            'Select UPI App',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _upiApps.length,
            itemBuilder: (context, index) {
              final app = _upiApps[index];
              final isSelected = _selectedUpiApp == app['package'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUpiApp = app['package'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFFFF9800) 
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: app['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          app['icon'],
                          color: app['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          app['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Manual UPI ID Entry
          const Text(
            'Or Enter UPI ID Manually',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _upiIdController,
            decoration: InputDecoration(
              hintText: 'example@upi',
              prefixIcon: const Icon(Icons.alternate_email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Pay Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedUpiApp.isNotEmpty || _upiIdController.text.isNotEmpty) && !_isProcessing
                  ? _processUpiPayment 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      'Pay ₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
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
                const Text(
                  'Scan QR Code to Pay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: _generateUpiQrData(),
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                    errorStateBuilder: (cxt, err) {
                      return const Center(
                        child: Text(
                          "Something went wrong...",
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Pay to: $_merchantName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UPI ID: $_merchantUpiId',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Copy UPI ID
                OutlinedButton.icon(
                  onPressed: _copyUpiId,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy UPI ID'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9800),
                    side: const BorderSide(color: Color(0xFFFF9800)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to pay using QR Code:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Open any UPI app (Google Pay, PhonePe, Paytm, etc.)\n'
                  '2. Scan the QR code above\n'
                  '3. Enter the amount and confirm payment\n'
                  '4. Money will be added to your wallet instantly',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Manual Payment Confirmation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmManualPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'I have completed the payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateUpiQrData() {
    // Generate UPI QR code data
    return 'upi://pay?pa=$_merchantUpiId&pn=${Uri.encodeComponent(_merchantName)}&am=${widget.amount}&cu=INR&tn=${Uri.encodeComponent('Add money to JaiKisan wallet')}';
  }

  void _copyUpiId() {
    Clipboard.setData(ClipboardData(text: _merchantUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _processUpiPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate UPI payment process
      await Future.delayed(const Duration(seconds: 3));

      // Add money to wallet
      final success = await WalletService.instance.addMoneyToWallet(
        amount: widget.amount,
        paymentMethod: PaymentMethod.upi,
        title: 'UPI Payment',
        description: 'Money added via UPI payment',
        referenceNumber: 'UPI${DateTime.now().millisecondsSinceEpoch}',
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to add money. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _confirmManualPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Have you completed the payment of ₹${widget.amount.toStringAsFixed(2)} using the QR code or UPI ID?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Add money to wallet
              final success = await WalletService.instance.addMoneyToWallet(
                amount: widget.amount,
                paymentMethod: PaymentMethod.upi,
                title: 'UPI QR Payment',
                description: 'Money added via UPI QR code payment',
                referenceNumber: 'QR${DateTime.now().millisecondsSinceEpoch}',
              );

              if (success) {
                _showSuccessDialog();
              } else {
                _showErrorDialog('Failed to add money. Please try again.');
              }
            },
            child: const Text('Yes, Confirm'),
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
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '₹${widget.amount.toStringAsFixed(2)} has been added to your wallet',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                    Navigator.pop(context); // Go back to wallet screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Done'),
                ),
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
