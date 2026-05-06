import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import 'google_pay_style_payment_screen.dart';
import 'package:intl/intl.dart';

class ContactTransactionHistoryScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final Contact? contact;
  final String? contactID; // Add ContactID parameter

  const ContactTransactionHistoryScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.contact,
    this.contactID, // Add ContactID parameter
  });

  @override
  State<ContactTransactionHistoryScreen> createState() => _ContactTransactionHistoryScreenState();
}

class _ContactTransactionHistoryScreenState extends State<ContactTransactionHistoryScreen> {
  List<Map<String, dynamic>> contactTransactions = [];
  bool isLoading = true;
  Map<String, dynamic>? memberDetail; // Add member detail state
  String? apiMobileNumber; // Add API mobile number state

  @override
  void initState() {
    super.initState();
    _loadContactTransactions();
    _loadMemberDetails(); // Load member details
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload transactions and member details when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadContactTransactions();
        _loadMemberDetails();
      }
    });
  }

  Future<void> _loadContactTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load transactions from API using RequestGetMemberByID only
      await _loadTransactionsFromAPI();
    } catch (e) {
      print('Error loading contact transactions: $e');
      // Set empty transactions on error
      setState(() {
        contactTransactions = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadTransactionsFromAPI() async {
    try {
      // Get user credentials from AuthProvider
      final authProvider = AuthProvider();
      await authProvider.initialize();
      
      final email = await authProvider.getApiUserEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      // Use ContactID if provided, otherwise try to get from API data
      String? contactID = widget.contactID;
      
       if (contactID == null || contactID.isEmpty) {
        // Fallback: try to get ContactID from AuthProvider for current user
          //contactID = await authProvider.getContactID();
          contactID ='';
       }
     
      String? requestedByContactID = await authProvider.getContactID();

      if (email.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        print('Missing credentials for transaction API');
        return;
      }

      print('Loading transactions for ContactID: $contactID');

      final result = await ApiService.getMemberByID(email, tokenCode, contactID, requestedByContactID);

      if (result['success'] == true) {
        // Check if there are transaction details in the API response
        List<Map<String, dynamic>> apiTransactions = [];
        
        // Check for recentLedger field (as shown in the API response)
        if (result['recentLedger'] != null) {
          apiTransactions = _processApiTransactions(result['recentLedger']);
          print('Found ${apiTransactions.length} transactions in recentLedger');
        } else if (result['transactions'] != null) {
          apiTransactions = _processApiTransactions(result['transactions']);
        } else if (result['transactionHistory'] != null) {
          apiTransactions = _processApiTransactions(result['transactionHistory']);
        } else if (result['ledger'] != null) {
          apiTransactions = _processApiTransactions(result['ledger']);
        } else if (result['memberDetail'] != null) {
          // Check if member details contain transaction information
          final memberDetails = result['memberDetail'] as List;
          if (memberDetails.isNotEmpty) {
            final memberData = memberDetails.first;
            if (memberData['transactions'] != null) {
              apiTransactions = _processApiTransactions(memberData['transactions']);
            } else if (memberData['transactionHistory'] != null) {
              apiTransactions = _processApiTransactions(memberData['transactionHistory']);
            }
          }
        }

        print('API transactions found: ${apiTransactions.length}');
        
        if (apiTransactions.isNotEmpty) {
          setState(() {
            contactTransactions = apiTransactions;
          });
          print('Successfully loaded ${apiTransactions.length} transactions from API');
        } else {
          setState(() {
            contactTransactions = [];
          });
          print('No transaction data found in API response');
          print('Available API response keys: ${result.keys.toList()}');
          if (result['memberDetail'] != null) {
            final memberDetails = result['memberDetail'] as List;
            if (memberDetails.isNotEmpty) {
              print('Member detail keys: ${memberDetails.first.keys.toList()}');
            }
          }
        }
      } else {
        print('Failed to load transactions from API: ${result['message']}');
      }
    } catch (e) {
      print('Error loading transactions from API: $e');
    }
  }

  List<Map<String, dynamic>> _processApiTransactions(dynamic transactionData) {
    List<Map<String, dynamic>> processedTransactions = [];
    
    try {
      List<dynamic> transactions = [];
      
      if (transactionData is List) {
        transactions = transactionData;
      } else if (transactionData is Map && transactionData['data'] is List) {
        transactions = transactionData['data'];
      }

      print('Processing ${transactions.length} transactions from API');

      for (var transaction in transactions) {
        if (transaction is Map<String, dynamic>) {
          // Extract transaction details based on the actual API response structure
          // From the API response: Amount, VoucherNumber, VoucherDate, Remarks, ContactName
          
          final amount = transaction['Amount'] ?? 0.0;
          final voucherNumber = transaction['VoucherNumber'] ?? '';
          final voucherDate = transaction['VoucherDate'] ?? '';
          final remarks = transaction['Remarks'] ?? '';
          final contactName = transaction['ContactName'] ?? widget.contactName;
          
          print('Processing transaction: Amount: $amount, Voucher: $voucherNumber, Date: $voucherDate');
          
          // Parse date from VoucherDate
          DateTime? transactionDate;
          if (voucherDate is String && voucherDate.isNotEmpty) {
            try {
              // The API returns date in format: "2025-08-30T00:00:00"
              transactionDate = DateTime.parse(voucherDate);
            } catch (e) {
              print('Error parsing date: $voucherDate');
              transactionDate = DateTime.now();
            }
          } else {
            transactionDate = DateTime.now();
          }

          // Convert amount to double and determine transaction type
          double transactionAmount = 0.0;
          if (amount is num) {
            transactionAmount = amount.toDouble();
          } else if (amount is String) {
            transactionAmount = double.tryParse(amount) ?? 0.0;
          }
          
          print('Transaction amount: $transactionAmount (${transactionAmount < 0 ? 'RECEIVED' : 'SENT'})');

          // Determine if it's a credit (negative = received) or debit (positive = sent) transaction
          // Negative values = money received (left side)
          // Positive values = money sent (right side)
          final isReceived = transactionAmount < 0; // Negative amount means received
          final isSent = transactionAmount > 0;     // Positive amount means sent
          final absAmount = transactionAmount.abs();
          
          // Create transaction title based on amount sign
          String title;
          if (isReceived) {
            title = 'Payment received from $contactName';
          } else {
            title = 'Payment sent to $contactName';
          }
          
          // Create subtitle with transaction details (excluding voucher number)
          String subtitle = 'JMI Transaction';
          if (remarks != null && remarks.isNotEmpty) {
            subtitle = remarks;
          }

          processedTransactions.add({
            'title': title,
            'subtitle': subtitle,
            'amount': absAmount.toInt(),
            'date': transactionDate,
            'status': 'Success', // API doesn't provide status, assume success for completed transactions
            'isReceived': isReceived, // Negative values = received (left side)
            'isSent': isSent,         // Positive values = sent (right side)
            'description': remarks.isNotEmpty ? remarks : 'JMI Transaction',
            'voucherNumber': voucherNumber,
            'voucherDate': voucherDate,
            'remarks': remarks,
            'rawAmount': transactionAmount, // Keep original amount with sign
            'rawData': transaction, // Keep raw data for debugging
          });
        }
      }

      // Sort by most recent first, then by time within the same day
      processedTransactions.sort((a, b) {
        final dateA = a['date'] as DateTime;
        final dateB = b['date'] as DateTime;
        
        // First sort by date (most recent day first)
        final dayComparison = dateB.compareTo(dateA);
        if (dayComparison != 0) {
          return dayComparison;
        }
        
        // If same day, sort by time (most recent time first within the day)
        return dateB.compareTo(dateA);
      });

      print('Successfully processed ${processedTransactions.length} transactions');

    } catch (e) {
      print('Error processing API transactions: $e');
    }

    return processedTransactions;
  }



  Future<void> _loadMemberDetails() async {
    try {
      // Get user credentials from AuthProvider
      final authProvider = AuthProvider();
      await authProvider.initialize();
      
      final email = await authProvider.getApiUserEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      // Use ContactID if provided, otherwise try to get from API data
      String? contactID = widget.contactID;
      
      if (contactID == null || contactID.isEmpty) {
        // Fallback: try to get ContactID from AuthProvider for current user
        //contactID = await authProvider.getContactID();
        contactID= '';
      }
      String? requestedByContactID = await authProvider.getContactID();

      if (email.isEmpty || tokenCode.isEmpty || contactID.isEmpty) {
        print('Missing credentials for member details API');
        return;
      }

      print('Loading member details for ContactID: $contactID');

      final result = await ApiService.getMemberByID(email, tokenCode, contactID, requestedByContactID);

      if (result['success'] == true && result['memberDetail'] != null) {
        final memberDetails = result['memberDetail'] as List;
        if (memberDetails.isNotEmpty) {
          setState(() {
            memberDetail = memberDetails.first;
            apiMobileNumber = memberDetail?['Mobile'] ?? '';
          });
          print('Loaded member details: ${memberDetail?['Name']}, Mobile: $apiMobileNumber');
        }
      } else {
        print('Failed to load member details: ${result['message']}');
      }
    } catch (e) {
      print('Error loading member details: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final initials = ContactService.getInitials(widget.contactName);
    final color = ContactService.getColorForContact(widget.contactName);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background like chat apps
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and contact info
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Contact Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contact Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.contactName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'JMI • ${apiMobileNumber?.isNotEmpty == true ? apiMobileNumber : (widget.phoneNumber.isNotEmpty ? (widget.phoneNumber.length > 10 ? widget.phoneNumber.substring(widget.phoneNumber.length - 10) : widget.phoneNumber) : "Loading...")}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[200],
            ),

            // Transaction List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
                      ),
                    )
                  : contactTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your payment history with ${widget.contactName} will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          reverse: false, // Show oldest first for proper date grouping
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: contactTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(contactTransactions[index], index);
                          },
                        ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handlePayAction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Request Button - HIDDEN
                  /*
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleRequestAction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(transactionDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return DateFormat('d MMM, y').format(date);
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, int index) {
    final amount = transaction['amount'] as int;
    final date = transaction['date'] as DateTime;
    final status = transaction['status'] as String;
    
    // Determine display side based on transaction type
    // isReceived (negative values) = left side
    // isSent (positive values) = right side
    final isReceived = transaction['isReceived'] == true;
    
    // For display: received payments go to left, sent payments go to right
    final showOnLeft = isReceived;  // Negative values (received) on left
    
    // Check if we need to show a date separator
    bool showDateSeparator = false;
    if (index == 0) {
      showDateSeparator = true;
    } else {
      // Get the previous transaction for date comparison
      final previousDate = contactTransactions[index - 1]['date'] as DateTime;
      final currentDate = date;
      
      // Show separator if it's a different day
      if (currentDate.day != previousDate.day || 
          currentDate.month != previousDate.month || 
          currentDate.year != previousDate.year) {
        showDateSeparator = true;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateSeparator)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDateSeparator(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: showOnLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: showOnLeft ? Colors.grey[100] : const Color(0xFF0066FF),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: showOnLeft ? const Radius.circular(4) : const Radius.circular(16),
                    bottomRight: showOnLeft ? const Radius.circular(16) : const Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type
                    Text(
                      showOnLeft ? 'Payment Received' : 'Payment Sent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: showOnLeft ? Colors.green[700] : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Amount
                    Text(
                      '₹${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: showOnLeft ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status and Time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == 'success' || status.toLowerCase() == 'paid' 
                                ? Colors.green 
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: showOnLeft ? Colors.grey[600] : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: showOnLeft ? Colors.grey[600] : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handlePayAction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GooglePayStylePaymentScreen(
          contactName: widget.contactName,
          phoneNumber: widget.phoneNumber,
          contact: widget.contact,
          contactID: widget.contactID, // Pass ContactID to payment screen
          isRequest: false,
        ),
      ),
    );
  }
}
