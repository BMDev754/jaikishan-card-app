import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'This app needs camera access to scan QR codes. Please grant camera permission in app settings.',
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

  static Future<String?> scanQRCode(BuildContext context) async {
    // Check if camera permission is granted
    bool hasPermission = await checkCameraPermission();
    
    if (!hasPermission) {
      hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        await showPermissionDeniedDialog(context);
        return null;
      }
    }

    // Navigate to QR scanner screen
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _foundBarcode(BarcodeCapture capture) {
    if (!_screenOpened) {
      final String code = capture.barcodes.first.rawValue ?? '';
      _screenOpened = true;
      Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off, color: Colors.grey),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_front, color: Colors.white),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _foundBarcode,
          ),
          
          // Overlay with scanning area
          Container(
            decoration: ShapeDecoration(
              shape: QRScannerOverlayShape(
                borderColor: const Color(0xFF0066FF),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          
          // Instructions
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Place QR code inside the frame to scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerOverlayShape extends ShapeBorder {
  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderOffset
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    // Draw corner borders
    final path = Path()
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + _borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset, cutOutRect.left + borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left + _borderLength, cutOutRect.top - borderOffset);

    canvas.drawPath(path, borderPaint);

    final path2 = Path()
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.top + _borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset, cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right - _borderLength, cutOutRect.top - borderOffset);

    canvas.drawPath(path2, borderPaint);

    final path3 = Path()
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.bottom - _borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset, cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left + _borderLength, cutOutRect.bottom + borderOffset);

    canvas.drawPath(path3, borderPaint);

    final path4 = Path()
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - _borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset, cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.right - _borderLength, cutOutRect.bottom + borderOffset);

    canvas.drawPath(path4, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
