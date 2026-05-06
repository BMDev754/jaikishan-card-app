import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_model.dart';
import '../../services/bank_service.dart';
import '../../widgets/bank_icon_widget.dart';

class BankVerificationScreen extends StatefulWidget {
  final Bank selectedBank;

  const BankVerificationScreen({
    super.key,
    required this.selectedBank,
  });

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    // Auto-fill IFSC prefix based on bank
    _ifscController.text = widget.selectedBank.code;
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderNameController.dispose();
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
          'Add Bank Account',
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
          // Selected Bank Header
          _buildSelectedBankHeader(),
          
          // Form Section
          Expanded(
            child: SingleChildScrollView(
              child: _buildForm(),
            ),
          ),
          
          // Bottom Action Button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedBankHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          BankIconWidget(
            bank: widget.selectedBank,
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
                  widget.selectedBank.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your account details to add this bank',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          if (_isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.all(16),
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
              'Account Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            
            // Account Number Field
            _buildInputField(
              controller: _accountNumberController,
              label: 'Account Number',
              hint: 'Enter your account number',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => BankService.validateAccountNumber(value ?? ''),
              prefixIcon: Icons.account_balance_wallet_outlined,
            ),
            
            const SizedBox(height: 20),
            
            // IFSC Code Field
            _buildInputField(
              controller: _ifscController,
              label: 'IFSC Code',
              hint: 'Enter IFSC code',
              textCapitalization: TextCapitalization.characters,
              validator: (value) => BankService.validateIFSC(value ?? ''),
              prefixIcon: Icons.business,
            ),
            
            const SizedBox(height: 20),
            
            // Account Holder Name Field
            _buildInputField(
              controller: _accountHolderNameController,
              label: 'Account Holder Name',
              hint: 'Enter account holder name',
              textCapitalization: TextCapitalization.words,
              validator: (value) => BankService.validateAccountHolderName(value ?? ''),
              prefixIcon: Icons.person_outline,
            ),
            
            if (_verificationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE57373)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE57373), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _verificationError!,
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_isVerified) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account verified successfully! You can now save this account.',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: Color(0xFF00BCD4), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your data is secure',
                          style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We use bank-grade security to protect your information. Your details are encrypted and never shared.',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required IconData prefixIcon,
    TextCapitalization? textCapitalization,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF666666),
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
          style: const TextStyle(fontSize: 14),
        ),
      ],
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
            onPressed: _isVerifying ? null : (_isVerified ? _saveAccount : _verifyAccount),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVerified ? const Color(0xFF4CAF50) : const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isVerified ? Icons.save : Icons.verified_user, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isVerified ? 'Save Account' : 'Verify Account',
                        style: const TextStyle(
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

  void _verifyAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      final accountNumber = _accountNumberController.text.trim();
      final ifscCode = _ifscController.text.trim().toUpperCase();
      
      final isVerified = await BankService.verifyBankAccount(accountNumber, ifscCode);
      
      setState(() {
        _isVerifying = false;
        _isVerified = isVerified;
        
        if (!isVerified) {
          _verificationError = 'Unable to verify account. Please check your details and try again.';
        }
      });

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationError = 'Verification failed. Please try again.';
      });
    }
  }

  void _saveAccount() async {
    if (!_isVerified) return;

    setState(() => _isVerifying = true);

    try {
      final savedBankAccount = SavedBankAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bankId: widget.selectedBank.id,
        bankName: widget.selectedBank.name,
        bankLogo: widget.selectedBank.logo,
        bankColor: widget.selectedBank.color, // Add bank color
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
        accountHolderName: _accountHolderNameController.text.trim(),
        isVerified: true,
        addedDate: DateTime.now(),
      );

      final success = await BankService.saveBankAccount(savedBankAccount);

      setState(() => _isVerifying = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account added successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save account. Please try again.'),
            backgroundColor: Color(0xFFE57373),
          ),
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Color(0xFFE57373),
        ),
      );
    }
  }
}
