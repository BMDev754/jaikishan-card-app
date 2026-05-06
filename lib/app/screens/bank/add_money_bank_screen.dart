import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';

class AddMoneyBankScreen extends StatefulWidget {
  final double amount;

  const AddMoneyBankScreen({
    super.key,
    required this.amount,
  });

  @override
  State<AddMoneyBankScreen> createState() => _AddMoneyBankScreenState();
}

class _AddMoneyBankScreenState extends State<AddMoneyBankScreen> {
  bool _isProcessing = false;
  String? _selectedBank;
  
  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'State Bank of India',
      'code': 'SBI',
      'icon': Icons.account_balance,
      'color': const Color(0xFF1976D2),
    },
    {
      'name': 'HDFC Bank',
      'code': 'HDFC',
      'icon': Icons.account_balance,
      'color': const Color(0xFF0D47A1),
    },
    {
      'name': 'ICICI Bank',
      'code': 'ICICI',
      'icon': Icons.account_balance,
      'color': const Color(0xFFE65100),
    },
    {
      'name': 'Axis Bank',
      'code': 'AXIS',
      'icon': Icons.account_balance,
      'color': const Color(0xFF7B1FA2),
    },
    {
      'name': 'Punjab National Bank',
      'code': 'PNB',
      'icon': Icons.account_balance,
      'color': const Color(0xFF388E3C),
    },
    {
      'name': 'Bank of Baroda',
      'code': 'BOB',
      'icon': Icons.account_balance,
      'color': const Color(0xFFD32F2F),
    },
  ];

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
          'Bank Transfer',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Amount Summary
          _buildAmountSummary(),
          
          // Bank Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Bank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bank List
                  ..._banks.map((bank) => _buildBankCard(bank)).toList(),
                ],
              ),
            ),
          ),
          
          // Continue Button
          _buildContinueButton(),
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
            'Amount to Add',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'via Bank Transfer',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final isSelected = _selectedBank == bank['code'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBank = bank['code'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2196F3) 
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bank['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                bank['icon'],
                color: bank['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transfer money securely',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2196F3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _selectedBank != null && !_isProcessing 
            ? _processBankTransfer 
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
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
            : const Text(
                'Continue with Bank Transfer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _processBankTransfer() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate bank transfer process
      await Future.delayed(const Duration(seconds: 3));

      // Add money to wallet
      final success = await WalletService.instance.addMoneyToWallet(
        amount: widget.amount,
        paymentMethod: PaymentMethod.bankTransfer,
        title: 'Bank Transfer',
        description: 'Money added via $_selectedBank bank transfer',
        referenceNumber: 'BT${DateTime.now().millisecondsSinceEpoch}',
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
                  color: Color.fromARGB(255, 240, 147, 40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Services Coming Soon!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '₹${widget.amount.toStringAsFixed(2)} has not been added to your wallet, Still it not.',
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
