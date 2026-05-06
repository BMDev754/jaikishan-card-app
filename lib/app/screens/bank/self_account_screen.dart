import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_model.dart';
import '../../services/bank_service.dart';
import '../../widgets/bank_icon_widget.dart';
import 'add_bank_screen.dart';
import 'bank_transfer_screen.dart';

class SelfAccountScreen extends StatefulWidget {
  const SelfAccountScreen({super.key});

  @override
  State<SelfAccountScreen> createState() => _SelfAccountScreenState();
}

class _SelfAccountScreenState extends State<SelfAccountScreen> {
  List<SavedBankAccount> savedBanks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBanks();
  }

  Future<void> _loadSavedBanks() async {
    setState(() => isLoading = true);
    final banks = await BankService.getSavedBanks();
    setState(() {
      savedBanks = banks;
      isLoading = false;
    });
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
          'To Self Account',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
        : Column(
            children: [
              // Quick Transfer Section
              _buildQuickTransferSection(),
              
              // Saved Banks Section
              Expanded(
                child: savedBanks.isEmpty 
                  ? _buildEmptyState()
                  : _buildSavedBanksList(),
              ),
            ],
          ),
    );
  }

  Widget _buildQuickTransferSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF00BCD4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Transfer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Transfer money to your other bank accounts',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _addNewBank,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00BCD4), width: 1.5),
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF00BCD4).withOpacity(0.05),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add New Bank Account',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 14,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 48,
              color: Color(0xFF00BCD4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Bank Accounts Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your bank accounts to transfer money easily to yourself',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addNewBank,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Your First Bank Account',
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

  Widget _buildSavedBanksList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved Bank Accounts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '${savedBanks.length} Account${savedBanks.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: savedBanks.length,
              separatorBuilder: (context, index) => const Divider(
                height: 24,
                color: Color(0xFFE0E0E0),
              ),
              itemBuilder: (context, index) {
                final bank = savedBanks[index];
                return _buildBankAccountTile(bank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountTile(SavedBankAccount bank) {
    return GestureDetector(
      onTap: () => _openBankTransfer(bank),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            // Bank Logo
            BankIconWidget(
              bank: bank.bank, // Use the bank getter from SavedBankAccount
              size: 48,
              fontSize: 14,
              showBorder: true,
            ),
            
            const SizedBox(width: 16),
            
            // Bank Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bank.bankName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (bank.isVerified)
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
                  const SizedBox(height: 4),
                  Text(
                    bank.accountHolderName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bank.maskedAccountNumber} • ${bank.ifscCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _deleteBankAccount(bank),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF00BCD4),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewBank() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBankScreen(),
      ),
    );
    
    if (result == true) {
      _loadSavedBanks();
    }
  }

  void _openBankTransfer(SavedBankAccount bank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(bankAccount: bank),
      ),
    );
  }

  void _deleteBankAccount(SavedBankAccount bank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Text('Are you sure you want to delete ${bank.bankName} account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await BankService.deleteBankAccount(bank.id);
              if (success) {
                _loadSavedBanks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bank account deleted successfully'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
