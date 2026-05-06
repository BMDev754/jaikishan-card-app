import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  final _emailController = TextEditingController(text: 'acbrightsymonm@gmail.com');
  final _otpController = TextEditingController(text: '4246');
  String _response = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _testAPI(String method, String endpoint, Map<String, String> headers, String? body) async {
    setState(() {
      _isLoading = true;
      _response = 'Testing $method $endpoint...\n\n';
    });

    try {
      http.Response response;
      final uri = Uri.parse(endpoint);
      
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers, body: body);
      }

      setState(() {
        _response += 'Status: ${response.statusCode}\n';
        _response += 'Headers: ${response.headers}\n';
        _response += 'Body: ${response.body}\n\n';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response += 'Error: $e\n\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSendOTPVariations() async {
    final email = _emailController.text;
    final originalUrl = 'https://api.v2cbazar.com/api/Response/ProcessEmailOTPRequestForMember/000001';
    final newUrl = 'https://api.v2cbazar.com/api/Response/ProcessEmailOTPRequestForMember/V2CBAZAR';
    
    // Test 1: GET with query parameters
    setState(() {
      _response = 'Testing Send OTP - Multiple URL Formats\n\n';
    });
    
    final headers = {
      'Content-Type': 'application/json',
      'CCode': 'V2CBAZAR',
      'EmailID': email,
      'Accept': 'application/json',
      'User-Agent': 'JaykisanCard/1.0',
    };

    // Test NEW URL (V2CBAZAR in path) - This should fix the schoolingkey issue
    await _testAPI('GET', '$newUrl?EmailID=$email', headers, null);
    
    // Test NEW URL with POST
    await _testAPI('POST', newUrl, headers, jsonEncode({
      'EmailID': email,
    }));
    
    // Test Original URL for comparison
    await _testAPI('GET', '$originalUrl?EmailID=$email&CCode=V2CBAZAR', headers, null);
    
    // Test POST with CCode in body (fallback)
    await _testAPI('POST', originalUrl, headers, jsonEncode({
      'EmailID': email,
      'CCode': 'V2CBAZAR'
    }));
  }

  Future<void> _testValidateOTPVariations() async {
    final email = _emailController.text;
    final otp = _otpController.text;
    final originalUrl = 'https://api.v2cbazar.com/api/Response/ProcessValidateEmailOTPLoginForMember/000001';
    final newUrl = 'https://api.v2cbazar.com/api/Response/ProcessValidateEmailOTPLoginForMember/V2CBAZAR';
    
    setState(() {
      _response = 'Testing Validate OTP - Multiple URL Formats\n\n';
    });
    
    final headers = {
      'Content-Type': 'application/json',
      'CCode': 'V2CBAZAR',
      'EmailID': email,
      'OTP': otp,
      'Accept': 'application/json',
      'User-Agent': 'JaykisanCard/1.0',
    };

    // Test NEW URL (V2CBAZAR in path) - This should fix the schoolingkey issue
    await _testAPI('GET', '$newUrl?EmailID=$email&OTP=$otp', headers, null);
    
    // Test NEW URL with POST
    await _testAPI('POST', newUrl, headers, jsonEncode({
      'EmailID': email,
      'OTP': otp,
    }));
    
    // Test Original URL for comparison
    await _testAPI('GET', '$originalUrl?EmailID=$email&OTP=$otp&CCode=V2CBAZAR', headers, null);
    
    // Test POST with original URL
    await _testAPI('POST', originalUrl, headers, jsonEncode({
      'EmailID': email,
      'OTP': otp,
      'CCode': 'V2CBAZAR',
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testSendOTPVariations,
                    child: const Text('Test Send OTP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testValidateOTPVariations,
                    child: const Text('Test Validate OTP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response.isEmpty ? 'Test results will appear here...' : _response,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
