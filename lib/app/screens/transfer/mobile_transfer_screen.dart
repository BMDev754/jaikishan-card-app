import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../../services/contact_service.dart';
import '../../services/wallet_service.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import 'contact_detail_screen.dart';
import 'contact_transaction_history_screen.dart';

class MobileTransferScreen extends StatefulWidget {
  const MobileTransferScreen({super.key});

  @override
  State<MobileTransferScreen> createState() => _MobileTransferScreenState();
}

class _MobileTransferScreenState extends State<MobileTransferScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<Map<String, dynamic>> _contactsWithTransactions = [];
  bool _isLoading = false; // Start with false for instant display
  bool _hasPermission = true; // Start with true for instant display
  bool _isLoadingContacts = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContactsInstantly();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadContactsInstantly() {
    // Set initial state for instant display
    setState(() {
      _isLoading = false;
      _hasPermission = true;
    });
    
    // Load real contacts immediately
    _loadRealContacts();
    
    // Load contacts with transactions
    _loadContactsWithTransactions();
  }

  Future<void> _loadRealContacts() async {
    try {
      // Check permission
      final hasPermission = await ContactService.checkContactPermission();
      
      if (!hasPermission) {
        final granted = await ContactService.requestContactPermission();
        if (!granted) {
          if (mounted) {
            setState(() {
              _hasPermission = false;
            });
          }
          return;
        }
      }
      
      // Load real contacts
      final realContacts = await ContactService.getContacts();
      if (mounted) {
        setState(() {
          _contacts = realContacts;
          _filteredContacts = realContacts;
          _hasPermission = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
        });
      }
      print('Failed to load contacts: $e');
    }
  }

  Future<void> _loadContactsWithTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      // Get user credentials from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait a bit for AuthProvider to initialize if needed
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userEmail = await authProvider.getProfileEmail();
      final tokenCode = await authProvider.getTokenCode();
      
      print('Mobile Transfer API Call - Email: ${userEmail.isNotEmpty ? "present" : "missing"}, Token: ${tokenCode.isNotEmpty ? "present" : "missing"}');
      
      if (userEmail.isEmpty || tokenCode.isEmpty) {
        print('Missing user credentials for API call - retrying in 2 seconds...');
        
        // Retry after a delay
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        final retryEmail = await authProvider.getProfileEmail();
        final retryToken = await authProvider.getTokenCode();
        
        print('Retry - Email: ${retryEmail.isNotEmpty ? "present" : "missing"}, Token: ${retryToken.isNotEmpty ? "present" : "missing"}');
        
        if (retryEmail.isEmpty || retryToken.isEmpty) {
          print('Still missing credentials after retry - hiding recent transactions section');
          if (mounted) {
            setState(() {
              _contactsWithTransactions = [];
              _isLoadingContacts = false;
            });
          }
          return;
        }
        
        // Use retry credentials
        final recentLedgerData = await ApiService.getRecentLedger(retryEmail, retryToken, await authProvider.getContactID());
        await _processApiResponse(recentLedgerData);
      } else {
        // Use original credentials
        final recentLedgerData = await ApiService.getRecentLedger(userEmail, tokenCode, await authProvider.getContactID());
        await _processApiResponse(recentLedgerData);
      }
    } catch (e) {
      print('Error loading recent ledger data: $e');
      if (mounted) {
        setState(() {
          _contactsWithTransactions = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _processApiResponse(Map<String, dynamic> recentLedgerData) async {
    // Check if API response has recentLedger data (direct structure)
    if (recentLedgerData['recentLedger'] != null) {
      final List<dynamic> ledgerList = recentLedgerData['recentLedger'];
      
      print('Mobile Transfer - API returned ${ledgerList.length} contacts');
      
      if (ledgerList.isNotEmpty) {
        // Convert API data to the format expected by the UI
        final List<Map<String, dynamic>> contactsList = ledgerList.map<Map<String, dynamic>>((item) {
          final String contactName = item['ContactName'] ?? 'Unknown';
          final String transCount = item['TransCount']?.toString() ?? '0';
          final String? contactImage = item['ContactImageName'];
          final String? contactID = item['ContactID']?.toString(); // Extract ContactID
          final String? accountID = item['AccountID']?.toString(); // Extract AccountID
          
          // Generate avatar data
          final initial = contactName.isNotEmpty ? contactName[0].toUpperCase() : 'U';
          final colors = [
            const Color(0xFF673AB7),
            const Color(0xFFFF9800), 
            const Color(0xFF4CAF50),
            const Color(0xFF2196F3),
            const Color(0xFF9C27B0),
            const Color(0xFFE91E63),
            const Color(0xFF795548),
            const Color(0xFF607D8B),
          ];
          final color = colors[contactName.hashCode.abs() % colors.length];
          
          return {
            'name': contactName,
            'phone': '', // API doesn't provide phone in this response
            'initial': initial,
            'color': color,
            'transactionCount': int.tryParse(transCount) ?? 0,
            'contactImage': contactImage,
            'contactID': contactID, // Store ContactID
            'accountID': accountID, // Store AccountID
            'lastTransactionDate': DateTime.now(), // API doesn't provide date
          };
        }).toList();

        if (mounted) {
          setState(() {
            _contactsWithTransactions = contactsList;
            _isLoadingContacts = false;
          });
          print('Mobile Transfer - Successfully loaded ${contactsList.length} contacts');
        }
      } else {
        // No data received - hide recent transactions section
        print('Mobile Transfer - API returned empty contact list');
        if (mounted) {
          setState(() {
            _contactsWithTransactions = [];
            _isLoadingContacts = false;
          });
        }
      }
    } else {
      // API failed or returned no data - hide recent transactions section
      print('Mobile Transfer - API call failed or returned invalid data');
      if (mounted) {
        setState(() {
          _contactsWithTransactions = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        try {
          // Clean the display name for searching
          final cleanDisplayName = contact.displayName
              .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
              .toLowerCase();
          return cleanDisplayName.contains(query) ||
                 contact.phones.any((phone) => phone.number.contains(query));
        } catch (e) {
          return false;
        }
      }).toList();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send Money',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {
              // Handle QR scanner
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Enter name or phone number',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contacts with Transactions Section (only show when not searching and data exists)
                  if ((_contactsWithTransactions.isNotEmpty || _isLoadingContacts) && _searchController.text.isEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _isLoadingContacts
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Loading recent transactions...'),
                                ],
                              ),
                            )
                          : _buildContactGrid(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // All Contacts Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchController.text.isEmpty ? 'All Contacts' : 'Search Results',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (_hasPermission)
                          Text(
                            '${_filteredContacts.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Contact List or Loading
                  if (_isLoading)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading contacts...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!_hasPermission)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Unable to access contacts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please grant contact permission in settings',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredContacts.isEmpty)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No contacts found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactItem(_filteredContacts[index]);
                        },
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

  Widget _buildContactItem(Contact contact) {
    final initials = ContactService.getInitials(contact.displayName);
    final color = ContactService.getColorForContact(contact.displayName);
    final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    
    // Clean the display name to handle special characters - more aggressive cleaning
    String cleanDisplayName;
    try {
      cleanDisplayName = contact.displayName
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '') // Only keep printable ASCII
          .trim();
      
      if (cleanDisplayName.isEmpty) {
        cleanDisplayName = 'Contact ${contact.id}';
      }
    } catch (e) {
      cleanDisplayName = 'Contact ${contact.id}';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () => _handleContactTap(cleanDisplayName, phoneNumber, contact),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: contact.photo != null
                  ? ClipOval(
                      child: Image.memory(
                        contact.photo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContactTap(String name, String phoneNumber, [Contact? contact]) async {
    // Check if contact has previous transactions
    try {
      final allTransactions = await WalletService.instance.transactionHistory;
      final contactTransactions = allTransactions.where((transaction) =>
        transaction.title.toLowerCase().contains(name.toLowerCase()) ||
        transaction.description.toLowerCase().contains(name.toLowerCase()) ||
        transaction.description.contains(phoneNumber)
      ).toList();

      if (contactTransactions.isNotEmpty) {
        // Contact has previous transactions - show transaction history
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactTransactionHistoryScreen(
              contactName: name,
              phoneNumber: phoneNumber,
              contact: contact,
            ),
          ),
        );
      } else {
        // Contact has no transactions - show contact detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailScreen(
              contactName: name,
              phoneNumber: phoneNumber,
              contact: contact,
            ),
          ),
        );
      }
    } catch (e) {
      // On error, fallback to contact detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContactDetailScreen(
            contactName: name,
            phoneNumber: phoneNumber,
            contact: contact,
          ),
        ),
      );
    }
  }

  Widget _buildContactGrid() {
    // Return empty container if no contacts
    if (_contactsWithTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    const int itemsPerRow = 4;
    final List<Widget> rows = [];
    
    for (int i = 0; i < _contactsWithTransactions.length; i += itemsPerRow) {
      final rowItems = _contactsWithTransactions
          .skip(i)
          .take(itemsPerRow)
          .map((contact) => Expanded(
                child: _buildContactIconItem(contact),
              ))
          .toList();
      
      // Fill remaining slots in row if needed
      while (rowItems.length < itemsPerRow) {
        rowItems.add(const Expanded(child: SizedBox()));
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rowItems,
          ),
        ),
      );
    }
    
    return Column(
      children: rows,
    );
  }

  Widget _buildContactIconItem(Map<String, dynamic> contactData) {
    final name = contactData['name'] as String;
    final phone = contactData['phone'] as String;
    final initial = contactData['initial'] as String;
    final color = contactData['color'] as Color;
    final transactionCount = contactData['transactionCount'] as int;
    final contactID = contactData['contactID'] as String?; // Extract ContactID

    return GestureDetector(
      onTap: () => _handleContactWithTransactionTap(name, phone, transactionCount, contactID),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactWithTransactionTap(String name, String phone, int transactionCount, String? contactID) {
    // Since this contact has transactions, always open transaction history
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactTransactionHistoryScreen(
          contactName: name,
          phoneNumber: phone,
          contactID: contactID, // Pass ContactID to transaction history screen
        ),
      ),
    );
  }
}
