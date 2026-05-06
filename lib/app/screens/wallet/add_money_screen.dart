import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bank/add_money_bank_screen.dart';
import '../payment/add_money_card_screen.dart';
import '../payment/add_money_razorpay_screen.dart';
import '../payment/add_money_upi_screen.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _selectedAmount = 0.0;
  
  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000, 10000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _onAmountChanged(String value) {
    setState(() {
      _selectedAmount = double.tryParse(value) ?? 0.0;
    });
  }

  bool get _isValidAmount => _selectedAmount >= 10 && _selectedAmount <= 100000;

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
          'Add Money',
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
          // Amount Selection Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Input Card
                  _buildAmountInputCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Amount Selection
                  _buildQuickAmountSelection(),
                  
                  const SizedBox(height: 32),
                  
                  // Payment Methods
                  _buildPaymentMethods(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount Input Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isValidAmount 
                    ? const Color(0xFF4CAF50) 
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: _onAmountChanged,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Amount Validation Message
          if (_selectedAmount > 0 && !_isValidAmount)
            Text(
              _selectedAmount < 10 
                  ? 'Minimum amount is ₹10'
                  : 'Maximum amount is ₹1,00,000',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          
          if (_isValidAmount)
            const Text(
              'Amount looks good!',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4CAF50),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Select',
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
            final isSelected = _selectedAmount == amount;
            return GestureDetector(
              onTap: () => _selectQuickAmount(amount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF6A11CB) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF6A11CB) 
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected 
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6A11CB).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
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

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        
        // Bank Transfer
        _buildPaymentMethodCard(
          title: 'Bank Transfer',
          subtitle: 'Transfer from your bank account',
          icon: Icons.account_balance,
          color: const Color(0xFF2196F3),
          onTap: () => _navigateToPaymentMethod('bank'),
        ),
        
        const SizedBox(height: 12),
        
        // Debit/Credit Card
        _buildPaymentMethodCard(
          title: 'Debit/Credit Card',
          subtitle: 'Pay using your debit or credit card',
          icon: Icons.credit_card,
          color: const Color(0xFF4CAF50),
          onTap: () => _navigateToPaymentMethod('card'),
        ),
        
        const SizedBox(height: 12),
        
        // Razorpay
        _buildPaymentMethodCard(
          title: 'Razorpay Gateway',
          subtitle: 'Secure payment through Razorpay',
          icon: Icons.payment,
          color: const Color(0xFF6A11CB),
          onTap: () => _navigateToPaymentMethod('razorpay'),
        ),
        
        const SizedBox(height: 12),
        
        // UPI
        _buildPaymentMethodCard(
          title: 'UPI Payment',
          subtitle: 'Pay using any UPI app',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFFFF9800),
          onTap: () => _navigateToPaymentMethod('upi'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isValidAmount ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isValidAmount 
                ? color.withOpacity(0.2) 
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _isValidAmount ? color : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isValidAmount 
                          ? const Color(0xFF1A1A1A) 
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isValidAmount 
                          ? const Color(0xFF666666) 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: _isValidAmount ? color : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPaymentMethod(String method) {
    if (!_isValidAmount) return;

    switch (method) {
      case 'bank':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMoneyBankScreen(amount: _selectedAmount),
          ),
        );
        break;
      case 'card':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMoneyCardScreen(amount: _selectedAmount),
          ),
        );
        break;
      case 'razorpay':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMoneyRazorpayScreen(amount: _selectedAmount),
          ),
        );
        break;
      case 'upi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMoneyUpiScreen(amount: _selectedAmount),
          ),
        );
        break;
    }
  }
}
