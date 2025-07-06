import 'dart:io';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../utils/config.dart';

class OCRService {
  // OCR functionality controlled by config
  static bool get _ocrEnabled => AppConfig.enableOCR;
  // static final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  static Future<String> extractTextFromImage(String imagePath) async {
    // Return mock text for UI testing
    if (!_ocrEnabled) {
      return _generateMockExtractedText();
    }

    // OCR functionality disabled for UI testing
    throw Exception('OCR is currently disabled for UI testing');
  }

  static Future<String> extractTextFromImageBytes(List<int> imageBytes) async {
    // Return mock text for UI testing
    if (!_ocrEnabled) {
      return _generateMockExtractedText();
    }

    // OCR functionality disabled for UI testing
    throw Exception('OCR is currently disabled for UI testing');
  }

  // Mock text generator for UI testing
  static String _generateMockExtractedText() {
    return '''
ELECTRICITY BILL

Account Number: 123456789
Service Address: 123 Main Street, City, State 12345
Bill Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
Due Date: ${DateTime.now().add(Duration(days: 30)).day}/${DateTime.now().add(Duration(days: 30)).month}/${DateTime.now().add(Duration(days: 30)).year}

USAGE SUMMARY
Current Reading: 5,250 kWh
Previous Reading: 4,800 kWh
Usage: 450 kWh

RATE INFORMATION
Rate per kWh: \$0.12
Energy Charge: \$54.00
Service Charge: \$15.50
Taxes and Fees: \$6.00

TOTAL AMOUNT DUE: \$125.50

PAYMENT OPTIONS
Online: www.utilitycompany.com
Phone: 1-800-UTILITY
Mail: P.O. Box 12345, City, State 12345

Thank you for choosing our service!
''';
  }

  static void dispose() {
    // _textRecognizer.close();
  }
} 