import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_model.dart';
import '../../widgets/bank_icon_widget.dart';

class BankTransferScreen extends StatefulWidget {
  final SavedBankAccount bankAccount;

  const BankTransferScreen({
    super.key,
    required this.bankAccount,
  });

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  
  bool _isProcessing = false;
  final double _walletBalance = 25000.0; // Mock wallet balance

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
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
          'Transfer Money',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          // Bank Account Header
          _buildBankAccountHeader(),
          
          // Wallet Balance Section
          _buildWalletBalanceSection(),
          
          // Transfer Form
          Expanded(
            child: SingleChildScrollView(
              child: _buildTransferForm(),
            ),
          ),
          
          // Bottom Action Button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBankAccountHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          BankIconWidget(
            bank: widget.bankAccount.bank, // Use the bank getter
            size: 48,
            fontSize: 14,
            showBorder: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bankAccount.bankName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bankAccount.accountHolderName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.bankAccount.maskedAccountNumber} • ${widget.bankAccount.ifscCode}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          if (widget.bankAccount.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Show add money options
              _showAddMoneyOptions();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Color(0xFF0066FF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Add Money',
                    style: TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 12,
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

  Widget _buildTransferForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            
            // Amount Field
            _buildAmountField(),
            
            const SizedBox(height: 20),
            
            // Quick Amount Buttons
            _buildQuickAmountButtons(),
            
            const SizedBox(height: 20),
            
            // Remarks Field
            _buildRemarksField(),
            
            const SizedBox(height: 24),
            
            // Transaction Info
            _buildTransactionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: _validateAmount,
          decoration: InputDecoration(
            hintText: 'Enter amount to transfer',
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.currency_rupee,
              color: Color(0xFF666666),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE57373)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuickAmountButtons() {
    final quickAmounts = [500, 1000, 2000, 5000];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: quickAmounts.map((amount) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _amountController.text = amount.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00BCD4)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00BCD4).withOpacity(0.05),
                    ),
                    child: Text(
                      '₹$amount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRemarksField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Remarks (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _remarksController,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'Enter transfer remarks',
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.note_alt_outlined,
              color: Color(0xFF666666),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00BCD4)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 18),
              SizedBox(width: 8),
              Text(
                'Transaction Information',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Transfers are processed instantly\n• No charges for self account transfers\n• Transaction limit: ₹50,000 per day\n• Money will be debited from your wallet',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processTransfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Transfer Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Invalid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > _walletBalance) {
      return 'Insufficient balance';
    }
    
    if (amount > 50000) {
      return 'Maximum transfer limit is ₹50,000';
    }
    
    return null;
  }

  void _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    
    // Show confirmation dialog
    final confirmed = await _showTransferConfirmation(amount);
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      // Simulate transfer processing
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isProcessing = false);
      
      // Show success dialog
      _showTransferSuccess(amount);
      
    } catch (e) {
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer failed. Please try again.'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
  }

  Future<bool> _showTransferConfirmation(double amount) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer ₹${amount.toStringAsFixed(2)} to:'),
            const SizedBox(height: 8),
            Text(
              widget.bankAccount.bankName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(widget.bankAccount.accountHolderName),
            Text(widget.bankAccount.maskedAccountNumber),
            if (_remarksController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Remarks: ${_remarksController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showTransferSuccess(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
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
              'Transfer Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)} transferred successfully',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Money to Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFF00BCD4)),
              title: const Text('Add from Bank Account'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Color(0xFF00BCD4)),
              title: const Text('Add via UPI'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Color(0xFF00BCD4)),
              title: const Text('Add via Debit/Credit Card'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}