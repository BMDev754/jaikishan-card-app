import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_model.dart';
import '../../services/bank_service.dart';
import 'add_bank_screen.dart';
import 'bank_transfer_screen.dart';

class SavedBanksScreen extends StatefulWidget {
  const SavedBanksScreen({super.key});

  @override
  State<SavedBanksScreen> createState() => _SavedBanksScreenState();
}

class _SavedBanksScreenState extends State<SavedBanksScreen> {
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
          'Saved Banks',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _addNewBank,
            icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
        : savedBanks.isEmpty 
          ? _buildEmptyState()
          : _buildBanksList(),
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
            'No Saved Banks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your bank accounts to transfer money easily',
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
                'Add Bank Account',
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

  Widget _buildBanksList() {
    return Column(
      children: [
        // Stats Header
        Container(
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
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${savedBanks.length} Bank Account${savedBanks.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${savedBanks.where((bank) => bank.isVerified).length} Verified',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Banks List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: savedBanks.length,
            itemBuilder: (context, index) {
              final bank = savedBanks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildBankCard(bank),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBankCard(SavedBankAccount bank) {
    return GestureDetector(
      onTap: () => _openBankTransfer(bank),
      child: Container(
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
              children: [
                // Bank Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Center(
                    child: Text(
                      bank.bankLogo,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
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
                      const SizedBox(height: 6),
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
                
                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, bank),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'transfer',
                      child: Row(
                        children: [
                          Icon(Icons.send, size: 18, color: Color(0xFF00BCD4)),
                          SizedBox(width: 8),
                          Text('Transfer Money'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF666666)),
                          SizedBox(width: 8),
                          Text('Edit Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Color(0xFFE57373)),
                          SizedBox(width: 8),
                          Text('Delete Account'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openBankTransfer(bank),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Added ${_formatDate(bank.addedDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

  void _handleMenuAction(String action, SavedBankAccount bank) {
    switch (action) {
      case 'transfer':
        _openBankTransfer(bank);
        break;
      case 'edit':
        _editBank(bank);
        break;
      case 'delete':
        _deleteBank(bank);
        break;
    }
  }

  void _editBank(SavedBankAccount bank) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality will be implemented'),
        backgroundColor: Color(0xFF00BCD4),
      ),
    );
  }

  void _deleteBank(SavedBankAccount bank) {
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