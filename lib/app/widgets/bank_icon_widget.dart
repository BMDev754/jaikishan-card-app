import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bank_model.dart';

class BankIconWidget extends StatelessWidget {
  final Bank bank;
  final double size;
  final double fontSize;
  final bool showBorder;

  const BankIconWidget({
    super.key,
    required this.bank,
    this.size = 40,
    this.fontSize = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    // Parse color from hex string or use default
    Color bankColor = _parseBankColor();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bank.imageUrl != null ? Colors.white : bankColor,
        borderRadius: BorderRadius.circular(8),
        border: showBorder 
          ? Border.all(color: bankColor.withOpacity(0.3), width: 1)
          : null,
        boxShadow: [
          BoxShadow(
            color: bankColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildBankLogo(),
      ),
    );
  }

  Widget _buildBankLogo() {
    // If image URL is available, use cached network image
    if (bank.imageUrl != null && bank.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: bank.imageUrl!,
        width: size * 0.8,
        height: size * 0.8,
        fit: BoxFit.contain,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: fontSize + 4,
            height: fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_parseBankColor()),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: _buildFallbackLogo(),
        ),
      );
    }
    
    // Fallback to text-based logo
    return Center(child: _buildFallbackLogo());
  }

  Widget _buildFallbackLogo() {
    Color bankColor = _parseBankColor();
    
    // Handle special cases for specific banks
    switch (bank.id) {
      case 'paytm':
        return Icon(
          Icons.payment,
          color: bank.imageUrl != null ? bankColor : Colors.white,
          size: fontSize + 4,
        );
      case 'airtel':
        return Icon(
          Icons.signal_cellular_4_bar,
          color: bank.imageUrl != null ? bankColor : Colors.white,
          size: fontSize + 4,
        );
      case 'jio':
        return Icon(
          Icons.network_cell,
          color: bank.imageUrl != null ? bankColor : Colors.white,
          size: fontSize + 4,
        );
      case 'fino':
        return Icon(
          Icons.account_balance_wallet,
          color: bank.imageUrl != null ? bankColor : Colors.white,
          size: fontSize + 4,
        );
      default:
        // Use bank abbreviation for traditional banks
        return Text(
          _getBankAbbreviation(),
          style: TextStyle(
            color: bank.imageUrl != null ? bankColor : Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  String _getBankAbbreviation() {
    // For banks with predefined abbreviations
    if (bank.logo.length <= 6) {
      return bank.logo;
    }
    
    // Generate abbreviation for longer names
    List<String> words = bank.name.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length > 4 ? 4 : words[0].length).toUpperCase();
    } else if (words.length == 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase();
    }
  }

  Color _parseBankColor() {
    if (bank.color != null && bank.color!.isNotEmpty) {
      try {
        // Remove '0x' prefix if present and parse hex color
        String colorStr = bank.color!.replaceAll('0x', '').replaceAll('#', '');
        if (colorStr.length == 8) {
          return Color(int.parse(colorStr, radix: 16));
        } else if (colorStr.length == 6) {
          return Color(int.parse('FF$colorStr', radix: 16));
        }
      } catch (e) {
        // If parsing fails, use default color
      }
    }
    
    // Default colors based on bank type
    if (bank.isPopular) {
      return const Color(0xFF2196F3); // Blue for popular banks
    } else {
      return const Color(0xFF757575); // Grey for other banks
    }
  }
}

// Extended bank icon widget for larger displays
class BankIconLarge extends StatelessWidget {
  final Bank bank;
  final double size;
  final VoidCallback? onTap;

  const BankIconLarge({
    super.key,
    required this.bank,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bankColor = _parseBankColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bank.imageUrl != null ? Colors.white : bankColor,
          gradient: bank.imageUrl == null ? LinearGradient(
            colors: [
              bankColor,
              bankColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bankColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: bank.imageUrl != null ? Border.all(
            color: bankColor.withOpacity(0.3),
            width: 1,
          ) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: bank.imageUrl != null ? _buildImageLogo() : _buildTextLogo(),
        ),
      ),
    );
  }

  Widget _buildImageLogo() {
    return CachedNetworkImage(
      imageUrl: bank.imageUrl!,
      width: size * 0.8,
      height: size * 0.8,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_parseBankColor()),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildTextLogo(),
    );
  }

  Widget _buildTextLogo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBankIcon(),
          const SizedBox(height: 4),
          Text(
            _getBankAbbreviation(),
            style: TextStyle(
              color: bank.imageUrl != null ? _parseBankColor() : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBankIcon() {
    Color iconColor = bank.imageUrl != null ? _parseBankColor() : Colors.white;
    
    switch (bank.id) {
      case 'paytm':
        return Icon(Icons.payment, color: iconColor, size: 24);
      case 'airtel':
        return Icon(Icons.signal_cellular_4_bar, color: iconColor, size: 24);
      case 'jio':
        return Icon(Icons.network_cell, color: iconColor, size: 24);
      case 'fino':
        return Icon(Icons.account_balance_wallet, color: iconColor, size: 24);
      default:
        return Icon(Icons.account_balance, color: iconColor, size: 24);
    }
  }

  String _getBankAbbreviation() {
    if (bank.logo.length <= 4) {
      return bank.logo;
    }
    
    List<String> words = bank.name.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length > 3 ? 3 : words[0].length).toUpperCase();
    } else if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return bank.logo.substring(0, 3).toUpperCase();
  }

  Color _parseBankColor() {
    if (bank.color != null && bank.color!.isNotEmpty) {
      try {
        String colorStr = bank.color!.replaceAll('0x', '').replaceAll('#', '');
        if (colorStr.length == 8) {
          return Color(int.parse(colorStr, radix: 16));
        } else if (colorStr.length == 6) {
          return Color(int.parse('FF$colorStr', radix: 16));
        }
      } catch (e) {
        // If parsing fails, use default color
      }
    }
    
    if (bank.isPopular) {
      return const Color(0xFF2196F3);
    } else {
      return const Color(0xFF757575);
    }
  }
}
