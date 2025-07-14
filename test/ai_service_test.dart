import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_app/services/ai_service.dart';

void main() {
  group('AIService Tests', () {
    test('generateBillSummary should return structured data', () async {
      final result = await AIService.generateBillSummary('Sample bill text');
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['summary'], isA<String>());
      expect(result['billDate'], isA<String>());
      expect(result['totalAmount'], isA<double>());
      expect(result['consumptionKwh'], isA<double>());
      expect(result['ratePerKwh'], isA<double>());
      expect(result['insights'], isA<List>());
      expect(result['recommendations'], isA<List>());
    });

    test('generateEnergySavingRecommendations should return list of recommendations', () async {
      final billHistory = [
        {
          'billDate': '2024-01-15',
          'consumptionKwh': 450.0,
          'totalAmount': 125.50,
        }
      ];
      
      final result = await AIService.generateEnergySavingRecommendations(billHistory);
      
      expect(result, isA<List<String>>());
      expect(result.isNotEmpty, true);
    });

    test('analyzeConsumptionPatterns should return analysis data', () async {
      final billHistory = [
        {
          'billDate': '2024-01-15',
          'consumptionKwh': 450.0,
          'totalAmount': 125.50,
        }
      ];
      
      final result = await AIService.analyzeConsumptionPatterns(billHistory);
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['analysis'], isA<String>());
      expect(result['trends'], isA<Map<String, dynamic>>());
      expect(result['seasonalPatterns'], isA<Map<String, dynamic>>());
    });
  });
} 