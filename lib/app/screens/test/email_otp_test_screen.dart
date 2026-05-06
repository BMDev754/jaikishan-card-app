import 'package:flutter/material.dart';
import '../../services/email_otp_service.dart';

/// Test screen to demonstrate email OTP API functionality
/// This can be removed in production or used for testing
class EmailOTPTestScreen extends StatefulWidget {
  const EmailOTPTestScreen({super.key});

  @override
  State<EmailOTPTestScreen> createState() => _EmailOTPTestScreenState();
}

class _EmailOTPTestScreenState extends State<EmailOTPTestScreen> {
  final _emailController = TextEditingController(text: 'acbrightsymonm@gmail.com');
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _response = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _testSendOTP() async {
    setState(() {
      _isLoading = true;
      _response = 'Sending OTP...';
    });

    final result = await EmailOTPService.sendOTP(_emailController.text);
    
    setState(() {
      _isLoading = false;
      _response = 'Send OTP Result:\n${result.toString()}';
    });
  }

  Future<void> _testVerifyOTP() async {
    setState(() {
      _isLoading = true;
      _response = 'Verifying OTP...';
    });

    final result = await EmailOTPService.verifyOTP(_emailController.text, _otpController.text);
    
    setState(() {
      _isLoading = false;
      _response = 'Verify OTP Result:\n${result.toString()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email OTP API Test'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send OTP'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testVerifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify OTP'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response.isEmpty ? 'Response will appear here...' : _response,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
