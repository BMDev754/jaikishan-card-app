# Jaikisan Card - Digital Payment App

A comprehensive digital payment application built with Flutter, featuring functionalities similar to PhonePe, Google Pay, and Paytm.

## 🚀 Features

### Core Payment Features
- **Send Money**: Transfer money instantly using phone numbers, UPI IDs, or bank accounts
- **QR Code Payments**: Scan QR codes for instant payments at merchants
- **Mobile Recharge**: Recharge prepaid mobiles for all operators
- **Bill Payments**: Pay electricity, gas, water, DTH, broadband, and other utility bills
- **Wallet Management**: Add money to wallet, check balance, and transaction history

### Security Features
- **PIN Security**: 4-digit PIN for transaction authentication
- **Biometric Authentication**: Fingerprint and face unlock support
- **OTP Verification**: Mobile number verification with OTP
- **Bank-level Encryption**: Secure transactions with advanced encryption

### User Experience
- **Modern UI/UX**: Clean, intuitive interface with smooth animations
- **Dark/Light Theme**: Adaptive theme support
- **Offline Support**: Local data storage with Hive database
- **Real-time Updates**: Live transaction status and notifications

## 📱 Screenshots

*Coming Soon...*

## 🛠 Tech Stack

- **Framework**: Flutter 3.32.2
- **State Management**: Provider
- **Navigation**: GoRouter
- **Local Database**: Hive
- **Authentication**: Local Auth (Biometric)
- **Animations**: Lottie, Custom Flutter Animations
- **Payment Integration**: Razorpay (Ready for integration)
- **Architecture**: Clean Architecture with MVVM pattern

## 📦 Dependencies

### Core Dependencies
```yaml
cupertino_icons: ^1.0.8
provider: ^6.1.2
go_router: ^14.2.7
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.3.2
```

### UI & Animation
```yaml
animations: ^2.0.11
shimmer: ^3.0.0
flutter_svg: ^2.0.10+1
lottie: ^3.1.2
smooth_page_indicator: ^1.2.0
pin_code_fields: ^8.0.1
```

### Payment & Security
```yaml
local_auth: ^2.3.0
razorpay_flutter: ^1.3.7
qr_flutter: ^4.1.0
mobile_scanner: ^5.2.3
encrypt: ^5.0.3
crypto: ^3.0.5
```

### Utilities
```yaml
http: ^1.2.2
dio: ^5.7.0
permission_handler: ^11.3.1
device_info_plus: ^10.1.2
intl: ^0.19.0
uuid: ^4.5.1
```

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/jaikisan_card.git
   cd jaikisan_card
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── app/
│   ├── models/          # Data models (User, Transaction, Beneficiary)
│   ├── providers/       # State management (Auth, Wallet, Transaction)
│   ├── routes/          # App navigation and routing
│   ├── screens/         # UI screens and pages
│   │   ├── auth/        # Authentication screens
│   │   ├── home/        # Home and main navigation
│   │   ├── wallet/      # Wallet management
│   │   ├── transactions/# Transaction history
│   │   ├── send_money/  # Money transfer screens
│   │   ├── qr/          # QR code functionality
│   │   ├── recharge/    # Mobile recharge
│   │   ├── bills/       # Bill payments
│   │   └── profile/     # User profile
│   ├── services/        # Business logic and API calls
│   └── utils/           # Constants, themes, and utilities
├── assets/              # Images, icons, animations
└── main.dart           # App entry point
```

## 🔐 Security Features

- **PIN Authentication**: Secure 4-digit PIN for transactions
- **Biometric Login**: Fingerprint and face recognition support
- **Data Encryption**: All sensitive data is encrypted
- **Secure Storage**: Local data stored securely using Hive
- **OTP Verification**: SMS-based phone number verification

## 💳 Payment Integration

The app is designed to integrate with multiple payment gateways:

- **Razorpay**: Primary payment gateway (configured)
- **UPI**: Direct UPI integration support
- **Bank APIs**: Ready for bank API integration
- **Wallet**: In-app wallet functionality

## 🎨 UI/UX Features

- **Material Design 3**: Latest Material Design guidelines
- **Responsive Design**: Adapts to different screen sizes
- **Smooth Animations**: Custom animations for better UX
- **Professional Theme**: Clean and modern interface
- **Accessibility**: Support for accessibility features

## 🚧 Development Status

### ✅ Completed Features
- App architecture and project setup
- Authentication flow (Login, OTP, PIN)
- Main navigation and bottom tabs
- Home screen with wallet and quick actions
- Profile management
- Theme and styling system
- Local storage with Hive
- State management with Provider

### 🔄 In Progress
- Complete payment flow implementation
- QR code scanning and generation
- Mobile recharge functionality
- Bill payment features
- Transaction history
- Wallet management

### 📋 Upcoming Features
- Bank account linking
- Payment gateway integration
- Push notifications
- Offline transaction support
- Advanced security features
- Admin dashboard

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, email support@jaikisanpay.com or create an issue in this repository.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- Open source community for the packages used

---

**Note**: This is a demo application for educational purposes. For production use, ensure proper security measures, compliance with financial regulations, and integration with certified payment gateways.
