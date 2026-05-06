import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_model.dart';
import '../../services/bank_service.dart';
import '../../widgets/bank_icon_widget.dart';
import 'bank_verification_screen.dart';

class AddBankScreen extends StatefulWidget {
  const AddBankScreen({super.key});

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final _searchController = TextEditingController();
  List<Bank> _filteredBanks = [];
  List<Bank> _popularBanks = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBanks() {
    _popularBanks = BankService.getPopularBanks();
    _filteredBanks = BankService.getAllBanks();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredBanks = BankService.getAllBanks();
      } else {
        _filteredBanks = BankService.searchBanks(query);
      }
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Add Bank Account',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          // Search Section
          _buildSearchSection(),
          
          // Banks List
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildBankCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your bank',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for your bank',
                hintStyle: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF999999),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCategories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Popular Banks Section
          _buildPopularBanksSection(),
          
          // All Banks Section
          _buildAllBanksSection(),
        ],
      ),
    );
  }

  Widget _buildPopularBanksSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(Icons.star, color: Color(0xFFFFB300), size: 20),
                SizedBox(width: 8),
                Text(
                  'Popular Banks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3.0,
            ),
            itemCount: _popularBanks.length,
            itemBuilder: (context, index) {
              final bank = _popularBanks[index];
              return _buildBankGridTile(bank);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllBanksSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'All Banks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _filteredBanks.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFE0E0E0),
            ),
            itemBuilder: (context, index) {
              final bank = _filteredBanks[index];
              return _buildBankListTile(bank);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredBanks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No banks found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Search Results (${_filteredBanks.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filteredBanks.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFE0E0E0),
              ),
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                return _buildBankListTile(bank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankGridTile(Bank bank) {
    return GestureDetector(
      onTap: () => _selectBank(bank),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              child: BankIconWidget(
                bank: bank,
                size: 32,
                fontSize: 8,
                showBorder: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bank.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    bank.code,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankListTile(Bank bank) {
    return GestureDetector(
      onTap: () => _selectBank(bank),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            BankIconWidget(
              bank: bank,
              size: 40,
              fontSize: 12,
              showBorder: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bank.code,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (bank.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF999999),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _selectBank(Bank bank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankVerificationScreen(selectedBank: bank),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }
}



