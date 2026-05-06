import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  static Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkContactPermission() async {
    final status = await Permission.contacts.status;
    return status == PermissionStatus.granted;
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contacts Permission Required'),
          content: const Text(
            'This app needs access to your contacts to send money. Please grant contacts permission in app settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<List<Contact>> getContacts() async {
    // Check if contacts permission is granted
    bool hasPermission = await checkContactPermission();
    
    if (!hasPermission) {
      hasPermission = await requestContactPermission();
      if (!hasPermission) {
        return [];
      }
    }

    try {
      // Fetch contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      
      // Filter contacts that have phone numbers and valid display names
      return contacts.where((contact) => 
        contact.phones.isNotEmpty && 
        contact.displayName.isNotEmpty &&
        _isValidDisplayName(contact.displayName)
      ).toList();
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }

  static bool _isValidDisplayName(String name) {
    try {
      // Test if the string can be safely displayed
      final testName = name.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
      return testName.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    
    // Clean the name to remove special characters
    final cleanName = name.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
    if (cleanName.isEmpty) return '?';
    
    final words = cleanName.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1).toUpperCase()}${words[1].substring(0, 1).toUpperCase()}';
    }
  }

  static Color getColorForContact(String name) {
    final colors = [
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFF03DAC6),
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFFCDDC39),
      const Color(0xFFFFEB3B),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
      const Color(0xFFF44336),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    
    final hashCode = name.hashCode;
    return colors[hashCode.abs() % colors.length];
  }
}
