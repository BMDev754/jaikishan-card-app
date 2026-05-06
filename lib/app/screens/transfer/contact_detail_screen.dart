import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';
import 'google_pay_style_payment_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  final Contact? contact;

  const ContactDetailScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final initials = ContactService.getInitials(contactName);
    final color = ContactService.getColorForContact(contactName);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () => _handleCall(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _handleMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contact Info Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Image/Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: contact?.photo != null
                      ? ClipOval(
                          child: Image.memory(
                            contact!.photo!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Contact Name
                Text(
                  contactName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Banking Name (optional)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Banking name: ${contactName.split(' ').first.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Phone Number
                if (phoneNumber.isNotEmpty)
                  Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Last Seen/Status
                const Text(
                  'Joined November 2021',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Say Hello Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Say "Hello!"',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        child: const Text(
                          '👋',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Pay Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handlePay(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                
                const SizedBox(width: 12),
                
                // Request Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                
                const SizedBox(width: 12),
                
                // Message Button
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _handleMessage(context),
                    icon: const Icon(
                      Icons.message,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send Arrow Button
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _handleSend(context),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $contactName...'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Contact'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Contact'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Contact'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePay(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GooglePayStylePaymentScreen(
          contactName: contactName,
          phoneNumber: phoneNumber,
          contact: contact,
          isRequest: false,
        ),
      ),
    );
  }

  void _handleRequest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GooglePayStylePaymentScreen(
          contactName: contactName,
          phoneNumber: phoneNumber,
          contact: contact,
          isRequest: true,
        ),
      ),
    );
  }

  void _handleMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening messages with $contactName'),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to messages screen
  }

  void _handleSend(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send options for $contactName'),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Show send options
  }
}
