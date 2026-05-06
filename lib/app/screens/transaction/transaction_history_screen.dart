import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _displayTransactions = [];
  bool _isLoading = true;
  bool _useApiData = true; // Flag to switch between API and local data
  
  final List<String> _filters = ['All', 'Sent', 'Received', 'Bills', 'Recharge'];

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
      if (_useApiData) {
        await _loadApiTransactions();
      } else {
        await _loadLocalTransactions();
      }
    } catch (e) {
      print('Error loading transactions: $e');
      // Fallback to local transactions if API fails
      if (_useApiData) {
        await _loadLocalTransactions();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadApiTransactions() async {
    try {
      // Get user credentials
      final authProvider = AuthProvider();
      await authProvider.initialize();
      
      final email = await authProvider.getApiUserEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      if (email.isEmpty || tokenCode.isEmpty) {
        print('Missing credentials for transaction API');
        await _loadLocalTransactions();
        return;
      }

      print('Loading transaction history from API...');

      final result = await ApiService.getLedgerSummary(email, tokenCode, await authProvider.getContactID());

      if (result['success'] == true) {
        final ledgerSummary = result['ledgerSummary'] as List;
        final apiTransactions = _convertApiTransactionsToDisplayFormat(ledgerSummary);
        
        setState(() {
          _displayTransactions = apiTransactions;
        });
        
        print('Successfully loaded ${apiTransactions.length} transactions from API');
      } else {
        print('Failed to load transactions from API: ${result['message']}');
        // Fallback to local data
        await _loadLocalTransactions();
      }
    } catch (e) {
      print('Error loading API transactions: $e');
      // Fallback to local data
      await _loadLocalTransactions();
    }
  }

  Future<void> _loadLocalTransactions() async {
    try {
      final walletService = WalletService.instance;
      final transactions = await walletService.transactionHistory;
      
      setState(() {
        _displayTransactions = _convertLocalTransactionsToDisplayFormat(transactions);
      });
      
      print('Loaded ${transactions.length} local transactions as fallback');
    } catch (e) {
      print('Error loading local transactions: $e');
      setState(() {
        _displayTransactions = [];
      });
    }
  }

  List<Map<String, dynamic>> _convertApiTransactionsToDisplayFormat(List<dynamic> ledgerSummary) {
    List<Map<String, dynamic>> transactions = [];
    
    try {
      for (var item in ledgerSummary) {
        if (item is Map<String, dynamic>) {
          final contactName = item['ContactName'] ?? 'Unknown Contact';
          final amount = (item['Amount'] as num?)?.toDouble() ?? 0.0;
          final voucherNumber = item['VoucherNumber'] ?? '';
          final voucherDate = item['VoucherDate'] ?? '';
          final remarks = item['Remarks'] ?? '';
          final contactID = item['ContactID'] ?? '';
          
          // Parse date
          DateTime transactionDate;
          try {
            transactionDate = DateTime.parse(voucherDate);
          } catch (e) {
            transactionDate = DateTime.now();
          }

          // Determine transaction type: negative (-) = received, positive (+) = sent
          final isReceived = amount < 0; // Negative amounts are received
          
          String type = isReceived ? 'received' : 'sent';
          String title = isReceived 
              ? 'Payment received from $contactName'
              : 'Payment sent to $contactName';
          String subtitle = remarks.isNotEmpty 
              ? remarks 
              : 'Transaction via $voucherNumber';
          IconData icon = isReceived ? Icons.arrow_downward : Icons.arrow_upward;
          Color color = isReceived ? Colors.green : Colors.red;
          
          // Generate avatar from contact name
          String? avatar = contactName.isNotEmpty ? contactName[0].toUpperCase() : null;
          
          // Format date
          String dateText = _formatTransactionDate(transactionDate);

          transactions.add({
            'id': voucherNumber,
            'type': type,
            'title': title,
            'subtitle': subtitle,
            'amount': amount,
            'date': dateText,
            'status': 'Success',
            'icon': icon,
            'color': color,
            'avatar': avatar,
            'timestamp': transactionDate,
            'contactName': contactName,
            'contactID': contactID,
            'voucherNumber': voucherNumber,
            'remarks': remarks,
          });
        }
      }

      // Sort by most recent first
      transactions.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      print('Converted ${transactions.length} API transactions to display format');
    } catch (e) {
      print('Error converting API transactions: $e');
    }

    return transactions;
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('d/M/y').format(date);
    }
  }

  List<Map<String, dynamic>> _convertLocalTransactionsToDisplayFormat(List<Transaction> transactions) {
    return transactions.map((transaction) {
      // Determine transaction type and display info
      String type = 'sent';
      String title = transaction.title;
      String subtitle = transaction.description;
      IconData icon = Icons.arrow_upward;
      Color color = Colors.red;
      String? avatar;
      
      // Extract contact information for payment transactions
      if (transaction.description.contains('(+') && transaction.description.contains(')')) {
        final phoneStart = transaction.description.indexOf('(+');
        final phoneEnd = transaction.description.indexOf(')', phoneStart);
        if (phoneStart != -1 && phoneEnd != -1) {
          // Extract contact name for avatar
          if (transaction.title.startsWith('Payment to ')) {
            final contactName = transaction.title.substring(11);
            avatar = contactName.isNotEmpty ? contactName[0].toUpperCase() : null;
          }
        }
      }
      
      // Determine transaction type based on transaction type and amount
      switch (transaction.type) {
        case TransactionType.payment:
        case TransactionType.transfer:
          type = 'sent';
          icon = Icons.arrow_upward;
          color = Colors.red;
          break;
        case TransactionType.addMoney:
          type = 'received';
          title = 'Money Added';
          subtitle = 'Wallet Top-up';
          icon = Icons.arrow_downward;
          color = Colors.green;
          avatar = null;
          break;
        case TransactionType.refund:
          type = 'received';
          title = 'Refund Received';
          subtitle = 'Transaction Refund';
          icon = Icons.arrow_downward;
          color = Colors.green;
          avatar = null;
          break;
      }

      // Format date
      final now = DateTime.now();
      final difference = now.difference(transaction.timestamp);
      String dateText;
      if (difference.inDays == 0) {
        final hour = transaction.timestamp.hour;
        final minute = transaction.timestamp.minute;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        dateText = 'Today, $displayHour:${minute.toString().padLeft(2, '0')} $ampm';
      } else if (difference.inDays == 1) {
        final hour = transaction.timestamp.hour;
        final minute = transaction.timestamp.minute;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        dateText = 'Yesterday, $displayHour:${minute.toString().padLeft(2, '0')} $ampm';
      } else if (difference.inDays < 7) {
        dateText = '${difference.inDays} days ago';
      } else {
        dateText = '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}';
      }

      return {
        'id': transaction.id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'amount': transaction.type == TransactionType.addMoney || transaction.type == TransactionType.refund 
            ? -transaction.amount  // Received money (negative values)
            : transaction.amount,  // Sent money (positive values)
        'date': dateText,
        'status': 'Success',
        'icon': icon,
        'color': color,
        'avatar': avatar,
        'timestamp': transaction.timestamp,
      };
    }).toList();
  }

  void _toggleDataSource() {
    setState(() {
      _useApiData = !_useApiData;
    });
    _loadTransactions();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _displayTransactions;
    }
    return _displayTransactions.where((transaction) => 
      transaction['type'] == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Transaction History',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _useApiData ? Icons.cloud : Icons.storage,
                color: Colors.black,
              ),
              onPressed: () => _toggleDataSource(),
              tooltip: _useApiData ? 'Using API Data' : 'Using Local Data',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () => _loadTransactions(),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: () => _showFilterDialog(),
            ),
          ],
        ),
        body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            )
          : Column(
              children: [
                // Filter Chips
                _buildFilterChips(),
                
                // Transaction Summary
                _buildTransactionSummary(),
                
                // Transaction List
                Expanded(
                  child: _buildTransactionList(),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF00BCD4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF00BCD4),
                side: BorderSide(
                  color: const Color(0xFF00BCD4),
                  width: 1,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    // Calculate totals: negative (-) = received, positive (+) = sent
    final totalReceived = _displayTransactions
        .where((t) => t['amount'] < 0) // Negative amounts are received
        .fold(0.0, (sum, t) => sum + (t['amount'] as num).abs());
    
    final totalSent = _displayTransactions
        .where((t) => t['amount'] > 0) // Positive amounts are sent
        .fold(0.0, (sum, t) => sum + (t['amount'] as num));

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
        children: [
          // Data source indicator
          /*Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _useApiData ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              /*children: [
                Icon(
                  _useApiData ? Icons.cloud : Icons.storage,
                  size: 14,
                  color: _useApiData ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 4),
                /*Text(
                  _useApiData ? 'Live Data' : 'Local Data',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _useApiData ? Colors.green : Colors.blue,
                  ),
                ),*/
              ],*/
            ),
          ),*/
          //const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Total Sent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalSent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Total Received',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalReceived.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final filteredTransactions = _filteredTransactions;
    
    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransactions.length,
        separatorBuilder: (context, index) => const Divider(
          height: 24,
          color: Color(0xFFE0E0E0),
        ),
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    // Fixed logic: negative (-) = received (right side), positive (+) = sent (left side)
    final isReceived = transaction['amount'] < 0; // Negative = received
    final amountColor = isReceived ? Colors.green : Colors.red; // Received = green, Sent = red
    final amountPrefix = isReceived ? '+ ₹' : '- ₹'; // Received shows +, Sent shows -
    
    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: Row(
        children: [
          // Transaction Icon/Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: transaction['avatar'] != null
                ? Center(
                    child: Text(
                      transaction['avatar'],
                      style: TextStyle(
                        color: transaction['color'],
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Icon(
                    transaction['icon'],
                    color: transaction['color'],
                    size: 24,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['subtitle'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['date'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${transaction['amount'].abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction['status'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filter or make a transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Transactions'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter transaction ID, name, or amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...['Date Range', 'Amount Range', 'Transaction Type', 'Status'].map(
              (filter) => ListTile(
                title: Text(filter),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Transaction details
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildDetailRow('Transaction ID', transaction['id']),
                  _buildDetailRow('Type', transaction['title']),
                  _buildDetailRow('Amount', '₹${transaction['amount'].abs().toStringAsFixed(2)}'),
                  _buildDetailRow('Date & Time', transaction['date']),
                  _buildDetailRow('Status', transaction['status']),
                  _buildDetailRow('Payment Method', 'UPI'),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _downloadReceipt(transaction),
                          child: const Text('Download Receipt'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _shareTransaction(transaction),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                          ),
                          child: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(Map<String, dynamic> transaction) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt for ${transaction['id']} downloaded'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _shareTransaction(Map<String, dynamic> transaction) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing transaction ${transaction['id']}'),
        backgroundColor: const Color(0xFF00BCD4),
      ),
    );
  }
}
