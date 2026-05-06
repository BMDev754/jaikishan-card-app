import 'package:flutter/material.dart';
import '../../services/api/api_service.dart';

class MultipleAccountsTestScreen extends StatefulWidget {
  const MultipleAccountsTestScreen({super.key});

  @override
  State<MultipleAccountsTestScreen> createState() => _MultipleAccountsTestScreenState();
}

class _MultipleAccountsTestScreenState extends State<MultipleAccountsTestScreen> {
  final _emailController = TextEditingController(text: 'acbrightsymonm@gmail.com');
  final _tokenController = TextEditingController(text: '1be0ed59e7a24807af374c88cc9b62c6');
  final _phoneController = TextEditingController(text: '8455943905');
  
  bool _isLoading = false;
  String _result = '';
  List<Map<String, dynamic>> _accounts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Test Multiple Accounts API',
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
              const Text(
                'ProcessGetMultipleAccountListForMember API Test',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Token field
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone field
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              // Test button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testAPI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC143C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
                          'Test API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Results
              if (_result.isNotEmpty) ...[
                const Text(
                  'API Response:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _result,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Account list
              if (_accounts.isNotEmpty) ...[
                const Text(
                  'Accounts Found:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(account['ContactName'] ?? account['Name'] ?? account['name'] ?? 'Account ${index + 1}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (account['ContactID'] != null)
                                Text('Contact ID: ${account['ContactID']}'),
                              if (account['ContactNumber'] != null)
                                Text('Contact Number: ${account['ContactNumber']}'),
                              if (account['APIUserName'] != null)
                                Text('API Username: ${account['APIUserName']}'),
                              // Fallback fields
                              if (account['Email'] != null || account['email'] != null)
                                Text('Email: ${account['Email'] ?? account['email']}'),
                              if (account['Mobile'] != null || account['mobile'] != null)
                                Text('Mobile: ${account['Mobile'] ?? account['mobile']}'),
                              if (account['CardNo'] != null || account['cardNo'] != null)
                                Text('Card: ${account['CardNo'] ?? account['cardNo']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testAPI() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _accounts = [];
    });

    try {
      final result = await ApiService.getMultipleAccountListForMember(
        email: _emailController.text.trim(),
        tokenCode: _tokenController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      setState(() {
        _result = result.toString();
        
        if (result['success'] == true && result['accounts'] != null) {
          _accounts = (result['accounts'] as List)
              .map((account) => account as Map<String, dynamic>)
              .toList();
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}