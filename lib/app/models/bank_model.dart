class Bank {
  final String id;
  final String name;
  final String code;
  final String logo;
  final String? imageUrl; // Bank logo image URL
  final String? color; // Brand color in hex format
  final bool isPopular;

  Bank({
    required this.id,
    required this.name,
    required this.code,
    required this.logo,
    this.imageUrl,
    this.color,
    this.isPopular = false,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      logo: json['logo'],
      imageUrl: json['imageUrl'],
      color: json['color'],
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'logo': logo,
      'imageUrl': imageUrl,
      'color': color,
      'isPopular': isPopular,
    };
  }
}

class SavedBankAccount {
  final String id;
  final String bankId;
  final String bankName;
  final String bankLogo;
  final String? bankColor; // Add bank color
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final bool isVerified;
  final DateTime addedDate;

  SavedBankAccount({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.bankLogo,
    this.bankColor,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    this.isVerified = false,
    required this.addedDate,
  });

  factory SavedBankAccount.fromJson(Map<String, dynamic> json) {
    return SavedBankAccount(
      id: json['id'],
      bankId: json['bankId'],
      bankName: json['bankName'],
      bankLogo: json['bankLogo'],
      bankColor: json['bankColor'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
      accountHolderName: json['accountHolderName'],
      isVerified: json['isVerified'] ?? false,
      addedDate: DateTime.parse(json['addedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankId': bankId,
      'bankName': bankName,
      'bankLogo': bankLogo,
      'bankColor': bankColor,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'isVerified': isVerified,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  // Get corresponding Bank object
  Bank get bank {
    return Bank(
      id: bankId,
      name: bankName,
      code: ifscCode.substring(0, 4), // Extract bank code from IFSC
      logo: bankLogo,
      color: bankColor,
      isPopular: false,
    );
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return 'XXXX${accountNumber.substring(accountNumber.length - 4)}';
  }
}
