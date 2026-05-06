import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api/api_service.dart';
import '../providers/auth_provider.dart';

enum TransactionType {
  addMoney,
  transfer,
  payment,
  refund,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
}

enum PaymentMethod {
  bankTransfer,
  debitCard,
  creditCard,
  razorpay,
  upi,
}

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final PaymentMethod? paymentMethod;
  final DateTime timestamp;
  final String? referenceNumber;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    this.paymentMethod,
    required this.timestamp,
    this.referenceNumber,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      type: TransactionType.values[json['type']],
      status: TransactionStatus.values[json['status']],
      paymentMethod: json['paymentMethod'] != null 
          ? PaymentMethod.values[json['paymentMethod']] 
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      referenceNumber: json['referenceNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.index,
      'status': status.index,
      'paymentMethod': paymentMethod?.index,
      'timestamp': timestamp.toIso8601String(),
      'referenceNumber': referenceNumber,
    };
  }
}

class WalletService {
  static const String _walletBalanceKey = 'wallet_balance';
  static const String _transactionHistoryKey = 'transaction_history';
  static const String _isNewUserKey = 'is_new_user';
  
  static WalletService? _instance;
  static WalletService get instance => _instance ??= WalletService._();
  WalletService._();

  // Get current wallet balance
  Future<double> get walletBalance async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getDouble(_walletBalanceKey) ?? 0.0;
    
    // If it's a new user, set balance to 0
    final isNewUser = prefs.getBool(_isNewUserKey) ?? true;
    if (isNewUser) {
      return 0.0;
    }
    
    return balance;
  }

  // Get wallet balance from API
  Future<double> getWalletBalanceFromAPI() async {
    try {
      // Get user credentials from AuthProvider
      final authProvider = AuthProvider();
      await authProvider.initialize();
      
      final email = await authProvider.getApiUserEmail();
      final tokenCode = await authProvider.getTokenCode();
      final contactID = await authProvider.getContactID();

      if (email.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        print('Missing credentials for wallet balance API');
        // Fallback to local balance
        return await walletBalance;
      }

      print('Fetching wallet balance from API for ContactID: $contactID');

      final result = await ApiService.getLedgerBalanceByID(email, tokenCode, contactID);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        
        if (data['currentbalance'] != null && data['currentbalance'] is List) {
          final balanceList = data['currentbalance'] as List;
          if (balanceList.isNotEmpty) {
            final balanceData = balanceList.first;
            final apiBalance = (balanceData['Balance'] as num?)?.toDouble() ?? 0.0;
            
            print('API Balance retrieved: $apiBalance');
            
            // Update local storage with API balance
            await setWalletBalance(apiBalance);
            
            return apiBalance;
          }
        }
      }
      
      print('Failed to get balance from API: ${result['message']}');
      // Fallback to local balance
      return await walletBalance;
      
    } catch (e) {
      print('Error getting wallet balance from API: $e');
      // Fallback to local balance
      return await walletBalance;
    }
  }

  // Set wallet balance
  Future<void> setWalletBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_walletBalanceKey, balance);
    await prefs.setBool(_isNewUserKey, false);
  }

  // Add money to wallet
  Future<bool> addMoneyToWallet({
    required double amount,
    required PaymentMethod paymentMethod,
    required String title,
    String? description,
    String? referenceNumber,
  }) async {
    try {
      // Get current balance
      final currentBalance = await walletBalance;
      
      // Create transaction record
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description ?? 'Money added to wallet',
        amount: amount,
        type: TransactionType.addMoney,
        status: TransactionStatus.success,
        paymentMethod: paymentMethod,
        timestamp: DateTime.now(),
        referenceNumber: referenceNumber,
      );

      // Update balance
      final newBalance = currentBalance + amount;
      await setWalletBalance(newBalance);

      // Save transaction
      await _saveTransaction(transaction);

      return true;
    } catch (e) {
      print('Error adding money to wallet: $e');
      return false;
    }
  }

  // Deduct money from wallet
  Future<bool> deductMoneyFromWallet({
    required double amount,
    required String title,
    String? description,
    String? referenceNumber,
  }) async {
    try {
      final currentBalance = await walletBalance;
      
      if (currentBalance < amount) {
        return false; // Insufficient balance
      }

      // Create transaction record
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description ?? 'Money deducted from wallet',
        amount: amount,
        type: TransactionType.transfer,
        status: TransactionStatus.success,
        timestamp: DateTime.now(),
        referenceNumber: referenceNumber,
      );

      // Update balance
      final newBalance = currentBalance - amount;
      await setWalletBalance(newBalance);

      // Save transaction
      await _saveTransaction(transaction);

      return true;
    } catch (e) {
      print('Error deducting money from wallet: $e');
      return false;
    }
  }

  // Get transaction history
  Future<List<Transaction>> get transactionHistory async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_transactionHistoryKey);
      
      if (historyJson == null) {
        return [];
      }

      final List<dynamic> historyList = json.decode(historyJson);
      return historyList
          .map((json) => Transaction.fromJson(json))
          .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first
    } catch (e) {
      print('Error loading transaction history: $e');
      return [];
    }
  }

  // Save transaction to history
  Future<void> _saveTransaction(Transaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHistory = await transactionHistory;
      
      currentHistory.insert(0, transaction); // Add at beginning
      
      // Keep only last 100 transactions
      if (currentHistory.length > 100) {
        currentHistory.removeRange(100, currentHistory.length);
      }

      final historyJson = json.encode(
        currentHistory.map((t) => t.toJson()).toList(),
      );
      
      await prefs.setString(_transactionHistoryKey, historyJson);
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Check if user is new (has 0 balance and no transactions)
  Future<bool> get isNewUser async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isNewUserKey) ?? true;
  }

  // Mark user as not new
  Future<void> markUserAsNotNew() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isNewUserKey, false);
  }

  // Clear wallet data (for logout)
  Future<void> clearWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletBalanceKey);
    await prefs.remove(_transactionHistoryKey);
    await prefs.setBool(_isNewUserKey, true);
  }

  // Get recent transactions (last 5)
  Future<List<Transaction>> get recentTransactions async {
    final history = await transactionHistory;
    return history.take(5).toList();
  }

  // Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final history = await transactionHistory;
    return history.where((t) => t.type == type).toList();
  }

  // Get total amount added to wallet
  Future<double> get totalAmountAdded async {
    final addMoneyTransactions = await getTransactionsByType(TransactionType.addMoney);
    return addMoneyTransactions
        .where((t) => t.status == TransactionStatus.success)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // Get total amount spent
  Future<double> get totalAmountSpent async {
    final spendTransactions = await getTransactionsByType(TransactionType.transfer);
    final paymentTransactions = await getTransactionsByType(TransactionType.payment);
    
    final totalSpend = spendTransactions
        .where((t) => t.status == TransactionStatus.success)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final totalPayments = paymentTransactions
        .where((t) => t.status == TransactionStatus.success)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return totalSpend + totalPayments;
  }
}
