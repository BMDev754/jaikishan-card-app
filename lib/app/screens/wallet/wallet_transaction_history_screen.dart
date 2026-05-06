import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/wallet_service.dart';

class WalletTransactionHistoryScreen extends StatefulWidget {
  const WalletTransactionHistoryScreen({super.key});

  @override
  State<WalletTransactionHistoryScreen> createState() => _WalletTransactionHistoryScreenState();
}

class _WalletTransactionHistoryScreenState extends State<WalletTransactionHistoryScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Add Money', 'Transfer', 'Payment'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await WalletService.instance.transactionHistory;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    }
    
    TransactionType? filterType;
    switch (_selectedFilter) {
      case 'Add Money':
        filterType = TransactionType.addMoney;
        break;
      case 'Transfer':
        filterType = TransactionType.transfer;
        break;
      case 'Payment':
        filterType = TransactionType.payment;
        break;
    }
    
    return _transactions.where((t) => t.type == filterType).toList();
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
          'Transaction History',
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
          // Filter Tabs
          _buildFilterTabs(),
          
          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = option;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6A11CB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6A11CB) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All' 
                ? 'Start adding money to see your transaction history'
                : 'No ${_selectedFilter.toLowerCase()} transactions found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isCredit = transaction.type == TransactionType.addMoney || transaction.type == TransactionType.refund;
    final color = _getTransactionColor(transaction.type);
    final icon = _getTransactionIcon(transaction.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Transaction Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
                    ),
                    if (transaction.referenceNumber != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ref: ${transaction.referenceNumber!.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(transaction.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ),
              if (transaction.paymentMethod != null) ...[
                const SizedBox(height: 2),
                Text(
                  _getPaymentMethodText(transaction.paymentMethod!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.addMoney:
        return const Color(0xFF4CAF50);
      case TransactionType.transfer:
        return const Color(0xFF2196F3);
      case TransactionType.payment:
        return const Color(0xFFFF9800);
      case TransactionType.refund:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.addMoney:
        return Icons.add_circle_outline;
      case TransactionType.transfer:
        return Icons.send;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.undo;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return const Color(0xFF4CAF50);
      case TransactionStatus.pending:
        return const Color(0xFFFF9800);
      case TransactionStatus.failed:
        return const Color(0xFFF44336);
      case TransactionStatus.cancelled:
        return const Color(0xFF666666);
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.razorpay:
        return 'Razorpay';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }
}
