import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank_model.dart';

class BankService {
  static const String _savedBanksKey = 'saved_banks';

  // Popular banks in India with brand colors and logo URLs
  static final List<Bank> _allBanks = [
    // Popular Banks
    Bank(
      id: 'sbi', 
      name: 'State Bank of India', 
      code: 'SBIN', 
      logo: 'SBI', 
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/SBI-logo.svg/2048px-SBI-logo.svg.png',
      color: '0xFF1F4E79', 
      isPopular: true
    ),
    Bank(
      id: 'hdfc', 
      name: 'HDFC Bank', 
      code: 'HDFC', 
      logo: 'HDFC', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSSquouX3qJzp6uZwleCOtTBppHfDKlN6vDHg&s',
      color: '0xFF004C8F', 
      isPopular: true
    ),
    Bank(
      id: 'icici', 
      name: 'ICICI Bank', 
      code: 'ICIC', 
      logo: 'ICICI', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT3Yfl3u_FGS0L-sfnzW1kBeUqtwZnmAoztlg&s',
      color: '0xFFFF6600',
      isPopular: true
    ),
    Bank(
      id: 'axis', 
      name: 'Axis Bank', 
      code: 'UTIB', 
      logo: 'AXIS', 
      imageUrl: 'https://yt3.googleusercontent.com/ytc/AIdro_kRDjb2TyoKdJDBQWukW50C8KCeOLO6AykhCHd8MSJSY0s=s900-c-k-c0x00ffffff-no-rj',
      color: '0xFF800080', 
      isPopular: true
    ),
    Bank(
      id: 'pnb', 
      name: 'Punjab National Bank', 
      code: 'PUNB', 
      logo: 'PNB', 
      imageUrl: 'https://www.pnbindia.in/images/pnb-logo.png',
      color: '0xFF8B0000', 
      isPopular: true
    ),
    Bank(
      id: 'kotak', 
      name: 'Kotak Mahindra Bank', 
      code: 'KKBK', 
      logo: 'KOTAK', 
      imageUrl: 'https://play-lh.googleusercontent.com/LNebn4Bl_U21COFhW1_l3c6wZK9vwTQP5is0YNJ35TRr9fPjdVLHtf1rdpG1Qdxdbw',
      color: '0xFFDC143C', 
      isPopular: true
    ),
    Bank(
      id: 'boi', 
      name: 'Bank of India', 
      code: 'BKID', 
      logo: 'BOI', 
      imageUrl: 'https://logos-world.net/wp-content/uploads/2020/01/Bank-of-India-Logo-before-2011.png',
      color: '0xFF0066CC', 
      isPopular: true
    ),
    Bank(
      id: 'canara', 
      name: 'Canara Bank', 
      code: 'CNRB', 
      logo: 'CANARA', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTRlAs2-MSfdlAoJ5c_GZwKgx1vAvpB_3Og0w&s',
      color: '0xFF8B4513', 
      isPopular: true
    ),
    
    // Other Banks
    Bank(
      id: 'bob', 
      name: 'Bank of Baroda', 
      code: 'BARB', 
      logo: 'BOB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBiBkDnKwaGRjh6dTFoCnMY_jwXWjqRAthtg&s',
      color: '0xFF228B22'
    ),
    Bank(
      id: 'union', 
      name: 'Union Bank of India', 
      code: 'UBIN', 
      logo: 'UNION', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTYq-2EugzZQ_-nRmJM8vJwVuQ-rPZl_pDcHA&s',
      color: '0xFF4169E1'
    ),
    Bank(
      id: 'idbi', 
      name: 'IDBI Bank', 
      code: 'IBKL', 
      logo: 'IDBI', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWLqx1N-OFT2N0ysm5U_2sPo5lNSS4R1U2zg&s',
      color: '0xFF32CD32'
    ),
    Bank(
      id: 'iob', 
      name: 'Indian Overseas Bank', 
      code: 'IOBA', 
      logo: 'IOB', 
      imageUrl: 'https://i.pinimg.com/736x/4d/36/80/4d3680df49d67fa9d800c7f072e9a33f.jpg',
      color: '0xFF9932CC'
    ),
    Bank(
      id: 'central', 
      name: 'Central Bank of India', 
      code: 'CBIN', 
      logo: 'CBI', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFuHvWLvEVTsVOr2jn7VaiWNoFZwEkLrtrMQ&s',
      color: '0xFF2E8B57'
    ),
    Bank(
      id: 'indian', 
      name: 'Indian Bank', 
      code: 'IDIB', 
      logo: 'IB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWLqx1N-OFT2N0ysm5U_2sPo5lNSS4R1U2zg&s',
      color: '0xFF8A2BE2'
    ),
    Bank(
      id: 'uco', 
      name: 'UCO Bank', 
      code: 'UCBA', 
      logo: 'UCO', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDPmOLmtKFrco9RzvbN4wM3LmfWaiKs_A-4A&s',
      color: '0xFF20B2AA'
    ),
    Bank(
      id: 'bom', 
      name: 'Bank of Maharashtra', 
      code: 'MAHB', 
      logo: 'BOM', 
      imageUrl: 'https://content.jdmagicbox.com/v2/comp/howrah/l7/9999p3214.3214.151109161436.e2l7/catalogue/bank-of-maharashtra-kadamtala-howrah-nationalised-banks-6dcp7opp05.jpg',
      color: '0xFFCD853F'
    ),
    Bank(
      id: 'yes', 
      name: 'YES Bank', 
      code: 'YESB', 
      logo: 'YES', 
      imageUrl: 'https://www.greenclimate.fund/sites/default/files/organisation/logo-yesbank.png',
      color: '0xFF4682B4'
    ),
    Bank(
      id: 'indusind', 
      name: 'IndusInd Bank', 
      code: 'INDB', 
      logo: 'IND', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvhv54BCIZTc_imhpq7Us0LQwuEYVuWKTDEA&s',
      color: '0xFF800000'
    ),
    Bank(
      id: 'federal', 
      name: 'Federal Bank', 
      code: 'FDRL', 
      logo: 'FED', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT_Ca2mGRwfnsUTAHHmNQMG8fRPjbwT_4lhg&s',
      color: '0xFF008B8B'
    ),
    Bank(
      id: 'south', 
      name: 'South Indian Bank', 
      code: 'SIBL', 
      logo: 'SIB', 
      imageUrl: 'https://brandeps.com/logo-download/S/South-Indian-Bank-logo-01.png',
      color: '0xFF6A5ACD'
    ),
    Bank(
      id: 'karur', 
      name: 'Karur Vysya Bank', 
      code: 'KVBL', 
      logo: 'KVB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSq9pTtuy9ziKJiV8nJfGkgYemdhO3t-EZ0zw&s',
      color: '0xFFB22222'
    ),
    Bank(
      id: 'city', 
      name: 'City Union Bank', 
      code: 'CIUB', 
      logo: 'CUB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT9BR346oP8X7nHy3caZm_KIzL9C5ulqLLhA&s',
      color: '0xFF008080'
    ),
    Bank(
      id: 'rbl', 
      name: 'RBL Bank', 
      code: 'RATN', 
      logo: 'RBL', 
      imageUrl: 'https://yt3.googleusercontent.com/U4_QJjAwGhUYDStdq5EbjMx8KOooiXTHu9AStxkKcQEpJwc8D94LC7CwPi2KQoRbXe6gd7scUg=s900-c-k-c0x00ffffff-no-rj',
      color: '0xFF4B0082'
    ),
    Bank(
      id: 'dcb', 
      name: 'DCB Bank', 
      code: 'DCBL', 
      logo: 'DCB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRSUVkI-pVuaeplsh0eLCd5CRimmIhN36umfQ&s',
      color: '0xFF556B2F'
    ),
    Bank(
      id: 'nainital', 
      name: 'Nainital Bank', 
      code: 'NTBL', 
      logo: 'NB', 
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT0bxocS-rwSW1uTCCu4hfHVPMO10Pgdm5BnQ&s',
      color: '0xFF8FBC8F'
    ),
    Bank(
      id: 'tamilnad', 
      name: 'Tamilnad Mercantile Bank', 
      code: 'TMBL', 
      logo: 'TMB', 
      imageUrl: 'https://static.vecteezy.com/system/resources/previews/013/948/616/non_2x/bank-icon-logo-design-vector.jpg',
      color: '0xFF9370DB'
    ),
    Bank(
      id: 'paytm', 
      name: 'Paytm Payments Bank', 
      code: 'PYTM', 
      logo: 'PAYTM', 
      imageUrl: 'https://logos-world.net/wp-content/uploads/2020/11/Paytm-Logo.png',
      color: '0xFF00BAF2'
    ),
    Bank(
      id: 'airtel', 
      name: 'Airtel Payments Bank', 
      code: 'AIRP', 
      logo: 'AIRTEL', 
      imageUrl: 'https://play-lh.googleusercontent.com/uFg3zOsnGZkIrswmvXyFYhoF3gC4tv0ovFZv0zisJFQ2DZqJyh9SUGrK6D-Tnn1lGqc',
      color: '0xFFED1C24'
    ),
    Bank(
      id: 'fino', 
      name: 'Fino Payments Bank', 
      code: 'FINO', 
      logo: 'FINO', 
      imageUrl: 'https://static.vecteezy.com/system/resources/previews/013/948/616/non_2x/bank-icon-logo-design-vector.jpg',
      color: '0xFF2E7D32'
    ),
    Bank(
      id: 'jio', 
      name: 'Jio Payments Bank', 
      code: 'JIOP', 
      logo: 'JIO', 
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Reliance_Jio_Logo.svg/1200px-Reliance_Jio_Logo.svg.png',
      color: '0xFF0066CC'
    ),
  ];

  static List<Bank> getAllBanks() {
    return _allBanks;
  }

  static List<Bank> getPopularBanks() {
    return _allBanks.where((bank) => bank.isPopular).toList();
  }

  static List<Bank> searchBanks(String query) {
    if (query.isEmpty) return _allBanks;
    
    return _allBanks.where((bank) {
      return bank.name.toLowerCase().contains(query.toLowerCase()) ||
             bank.code.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static Bank? getBankById(String id) {
    try {
      return _allBanks.firstWhere((bank) => bank.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<SavedBankAccount>> getSavedBanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final banksJson = prefs.getString(_savedBanksKey);
      
      if (banksJson == null) return [];
      
      final List<dynamic> banksList = json.decode(banksJson);
      return banksList.map((bank) => SavedBankAccount.fromJson(bank)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveBankAccount(SavedBankAccount bankAccount) async {
    try {
      final savedBanks = await getSavedBanks();
      
      // Check if account already exists
      final existingIndex = savedBanks.indexWhere(
        (bank) => bank.accountNumber == bankAccount.accountNumber && 
                  bank.ifscCode == bankAccount.ifscCode
      );
      
      if (existingIndex != -1) {
        // Update existing account
        savedBanks[existingIndex] = bankAccount;
      } else {
        // Add new account
        savedBanks.add(bankAccount);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final banksJson = json.encode(savedBanks.map((bank) => bank.toJson()).toList());
      
      return await prefs.setString(_savedBanksKey, banksJson);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteBankAccount(String accountId) async {
    try {
      final savedBanks = await getSavedBanks();
      savedBanks.removeWhere((bank) => bank.id == accountId);
      
      final prefs = await SharedPreferences.getInstance();
      final banksJson = json.encode(savedBanks.map((bank) => bank.toJson()).toList());
      
      return await prefs.setString(_savedBanksKey, banksJson);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyBankAccount(String accountNumber, String ifscCode) async {
    // Simulate bank verification process
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock verification logic (in real app, this would call actual bank API)
    if (accountNumber.length >= 9 && ifscCode.length == 11) {
      return true;
    }
    
    return false;
  }

  static String? validateAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) {
      return 'Account number is required';
    }
    if (accountNumber.length < 9 || accountNumber.length > 20) {
      return 'Account number must be between 9-20 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(accountNumber)) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  static String? validateIFSC(String ifsc) {
    if (ifsc.isEmpty) {
      return 'IFSC code is required';
    }
    if (ifsc.length != 11) {
      return 'IFSC code must be 11 characters';
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.toUpperCase())) {
      return 'Invalid IFSC code format';
    }
    return null;
  }

  static String? validateAccountHolderName(String name) {
    if (name.isEmpty) {
      return 'Account holder name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name must contain only letters and spaces';
    }
    return null;
  }
}
