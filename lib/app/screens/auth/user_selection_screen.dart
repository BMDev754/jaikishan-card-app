import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UserSelectionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final String loginType; // 'email' or 'phone'
  final String? originalEmail;
  final String? originalTokenCode;
  final Map<String, dynamic>? originalLoginData;
  
  const UserSelectionScreen({
    super.key,
    required this.users,
    required this.loginType,
    this.originalEmail,
    this.originalTokenCode,
    this.originalLoginData,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  int? _selectedUserIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('=== UserSelectionScreen Initialized ===');
    print('Users count: ${widget.users.length}');
    print('Login type: ${widget.loginType}');
    for (int i = 0; i < widget.users.length; i++) {
      print('User $i: ${widget.users[i]}');
    }
    print('=====================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Select Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFDC143C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Account List ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select the account you want to use:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.users.length,
                  itemBuilder: (context, index) {
                    final user = widget.users[index];
                    return _buildUserCard(user, index);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedUserIndex != null && !_isLoading
                      ? _continueWithSelectedUser
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC143C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isSelected = _selectedUserIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFDC143C) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: RadioListTile<int>(
        value: index,
        groupValue: _selectedUserIndex,
        onChanged: (int? value) {
          setState(() {
            _selectedUserIndex = value;
          });
        },
        activeColor: const Color(0xFFDC143C),
        title: Text(
          user['Name'] ?? user['name'] ?? 'User ${index + 1}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display ContactID if available (from MemberList API)
            /*if (user['ContactID'] != null && user['ContactID'].toString().isNotEmpty)
              Text(
                'Contact ID: ${user['ContactID']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),*/
            // Display ContactNumber if available (from MemberList API)
            if (user['ContactNumber'] != null && user['ContactNumber'].toString().isNotEmpty)
              Text(
                'Number: ${user['ContactNumber']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            // Display APIUserName if available (from MemberList API)
            if (user['APIUserName'] != null && user['APIUserName'].toString().isNotEmpty)
              Text(
                'Ref. Number: ${user['APIUserName']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            // Fallback to original fields for backward compatibility
            if (user['email'] != null && user['email'].toString().isNotEmpty)
              Text(
                'Email: ${user['email']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (user['Mobile'] != null && user['Mobile'].toString().isNotEmpty)
              Text(
                'Mobile: ${user['Mobile']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (user['CardNo'] != null && user['CardNo'].toString().isNotEmpty)
              Text(
                'Card: ${user['CardNo']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _continueWithSelectedUser() async {
    if (_selectedUserIndex == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedUser = widget.users[_selectedUserIndex!];
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use original login credentials from the constructor
      String email = widget.originalEmail ?? selectedUser['email'] ?? '';
      String tokenCode = widget.originalTokenCode ?? selectedUser['tokenCode'] ?? '';
      String userName = selectedUser['Name'] ?? selectedUser['ContactName'] ?? '';
      
      // If we still don't have email/tokenCode, try to get from auth provider as fallback
      if (email.isEmpty) {
        email = await authProvider.getApiUserEmail();
      }
      if (tokenCode.isEmpty) {
        tokenCode = await authProvider.getTokenCode();
      }

      print('=== USER SELECTION DEBUG ===');
      print('Selected User: $selectedUser');
      print('Original Email: ${widget.originalEmail}');
      print('Original TokenCode: ${widget.originalTokenCode}');
      print('Using Email: $email');
      print('Using TokenCode: $tokenCode');
      print('Using UserName: $userName');
      print('==============================');

      // Create enhanced user data combining original login data with selected member data
      final enhancedUserData = <String, dynamic>{
        // Include original login data if available
        if (widget.originalLoginData != null) ...widget.originalLoginData!,
        // Include selected user data
        ...selectedUser,
        // Override with correct authentication data (this ensures no duplicates)
        'email': email,
        'tokenCode': tokenCode,
        'Name': userName,
        'ContactID': selectedUser['ContactID'],
        'ContactName': selectedUser['ContactName'],
        'ContactNumber': selectedUser['ContactNumber'],
        'APIUserName': selectedUser['APIUserName'],
      };

      print('Enhanced user data: $enhancedUserData');

      // Save the enhanced user data
      await authProvider.loginWithEmailData(
        email,
        userName,
        tokenCode,
        additionalData: enhancedUserData,
      );

      if (mounted) {
        // Navigate to home screen
        context.go('/home');
      }
    } catch (e) {
      print('Error in _continueWithSelectedUser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}