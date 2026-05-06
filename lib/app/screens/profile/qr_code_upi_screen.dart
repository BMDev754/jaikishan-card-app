import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import '../../providers/auth_provider.dart';

class QRCodeUPIScreen extends StatefulWidget {
  const QRCodeUPIScreen({super.key});

  @override
  State<QRCodeUPIScreen> createState() => _QRCodeUPIScreenState();
}

class _QRCodeUPIScreenState extends State<QRCodeUPIScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _userPhone = '';
  String _userName = '';
  String _contactID = '';
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get user data from AuthProvider (which gets from API)
      final phone = await authProvider.getProfileMobile();
      final name = await authProvider.getProfileName();
      final contactID = await authProvider.getContactID();
      
      print('=== QR Code Data Loading ===');
      print('Phone: $phone');
      print('Name: $name');
      print('ContactID: $contactID');
      print('============================');
      
      setState(() {
        _userPhone = phone.replaceAll('+91', ''); // Remove country code if present
        _userName = name.isNotEmpty ? name : 'Jaikisan User';
        _contactID = contactID;
      });
      
    } catch (e) {
      print('Error loading user data for QR: $e');
      // Fallback to basic data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _userPhone = authProvider.phoneNumber?.replaceAll('+91', '') ?? '';
        _userName = 'Jaikisan User';
        _contactID = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: 24,
          ),
        ),
        title: const Text(
          'QR & JMI',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'QR Code'),
            Tab(text: 'JMI ID'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRCodeTab(),
          _buildUPITab(),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // QR Code Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Scan to Pay',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                
                // QR Code Container
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: _generateQRData(),
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        errorStateBuilder: (cxt, err) {
                          return Container(
                            child: const Center(
                              child: Text(
                                "Something went wrong...",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      // Center Logo with app icon (no background/border)
                      Container(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          'assets/logos/app_icon.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to simple text logo if image fails to load
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0066FF), Color(0xFF00BCD4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  'J',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                
                const SizedBox(height: 24),
                
                // Contact ID Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JMI ID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generateQRData(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(_generateQRData()),
                            icon: const Icon(
                              Icons.copy,
                              color: Color(0xFF00BCD4),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share QR',
                  onTap: _shareQRCode,
                  backgroundColor: const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.download,
                  label: 'Save QR',
                  onTap: _saveQRCode,
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Info Card
          _buildInfoCard(),
        ],
      
      ),
    );
  }

  Widget _buildUPITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // UPI ID Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Your JMI ID',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),
                
                // UPI ID Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _generateQRData(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userPhone.isNotEmpty ? '+91$_userPhone' : 'Phone not available',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Jaikisan ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Phone Number Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Linked Mobile Number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+91 $_userPhone',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy JMI ID',
                  onTap: () => _copyToClipboard(_generateQRData()),
                  backgroundColor: const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share JMI ID',
                  onTap: _shareUPIId,
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // UPI Benefits Card
          _buildUPIBenefitsCard(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'How to use QR Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.qr_code_scanner,
            title: 'Show your QR code',
            description: 'Let others scan this QR code to pay you instantly',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.share,
            title: 'Share with friends',
            description: 'Share your QR code via WhatsApp, SMS, or other apps',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.security,
            title: 'Safe & Secure',
            description: 'All transactions are protected with bank-level security',
          ),
        ],
      ),
    );
  }

  Widget _buildUPIBenefitsCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            'JMI Benefits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.flash_on,
            title: 'Instant transfers',
            description: 'Money transfers happen in seconds, 24x7',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.money_off,
            title: 'Zero charges',
            description: 'No charges for JMI transactions up to ₹1000',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.verified_user,
            title: 'Bank verified',
            description: 'Your JMI ID is linked to your verified bank account',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00BCD4),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generateQRData() {
    // Generate QR code with ContactID@jaikisan format
    if (_contactID.isNotEmpty) {
      return '${_contactID}@jaikisan';
    } else {
      // Fallback to phone-based identifier if ContactID not available
      return '${_userPhone}@jaikisan';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _shareQRCode() async {
    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      final qrData = _generateQRData();
      // Share both image and text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Connect with me on Jaikisan:\n$qrData\n\nScan my QR code to get my contact details!',
        subject: 'My Jaikisan Contact',
      );
    } catch (e) {
      print('Error sharing QR code: $e');
      // Fallback to text only
      final qrData = _generateQRData();
      Share.share(
        'Connect with me on Jaikisan:\n$qrData\n\nScan my QR code to get my contact details!',
        subject: 'My Jaikisan Contact',
      );
    }
  }

  void _shareUPIId() {
    final qrData = _generateQRData();
    Share.share(
      'My Jaikisan Contact ID: $qrData\nMobile: +91$_userPhone\n\nPowered by Jaikisan',
      subject: 'My Jaikisan Contact ID',
    );
  }

  Future<void> _saveQRCode() async {
    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final fileName = 'jaikisan_qr_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code saved to ${downloadsDir.path}/$fileName'),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF4CAF50),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () async {
                await Share.shareXFiles([XFile(file.path)]);
              },
            ),
          ),
        );
      } else {
        throw Exception('Could not access storage directory');
      }
    } catch (e) {
      print('Error saving QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
