import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

class AIService {
  // API calls controlled by config
  static bool get _apiEnabled => AppConfig.enableAI;
  static const String _baseUrl = 'https://api.githubcopilot.com'; // Replace with actual Copilot API endpoint
  static const String _apiKey = 'YOUR_COPILOT_API_KEY'; // Replace with your actual API key

  static Future<Map<String, dynamic>> generateBillSummary(String extractedText) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary(extractedText);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4', // or appropriate model
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert in analyzing electricity bills. Extract key information and provide insights in the following JSON format:
{
  "summary": "Brief summary of the bill",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["Array of insights about the bill"],
  "recommendations": ["Array of energy-saving recommendations"]
}'''
            },
            {
              'role': 'user',
              'content': 'Please analyze this electricity bill text and extract the key information:\n\n$extractedText'
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse the JSON response
        try {
          return jsonDecode(content);
        } catch (e) {
          // If JSON parsing fails, return a structured response
          return {
            'summary': content,
            'billDate': DateTime.now().toIso8601String().split('T')[0],
            'totalAmount': 0.0,
            'consumptionKwh': 0.0,
            'ratePerKwh': 0.0,
            'insights': ['Unable to extract specific data'],
            'recommendations': ['Consider uploading a clearer image for better analysis'],
          };
        }
      } else {
        throw Exception('Failed to generate summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating bill summary: $e');
    }
  }

  static Future<List<String>> generateEnergySavingRecommendations(
    List<Map<String, dynamic>> billHistory,
  ) async {
    // Return mock recommendations for UI testing
    if (!_apiEnabled) {
      return _generateMockRecommendations();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an energy efficiency expert. Based on the user's electricity bill history, provide personalized recommendations for saving energy and money. Focus on practical, actionable advice that can be implemented immediately.'''
            },
            {
              'role': 'user',
              'content': 'Based on this electricity bill history, provide 5-7 specific recommendations for saving energy and money:\n\n${jsonEncode(billHistory)}'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Split the response into individual recommendations
        final recommendations = content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
            .toList();
        
        return recommendations;
      } else {
        throw Exception('Failed to generate recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating recommendations: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeConsumptionPatterns(
    List<Map<String, dynamic>> billHistory,
  ) async {
    // Return mock analysis for UI testing
    if (!_apiEnabled) {
      return _generateMockAnalysis(billHistory);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an energy analyst. Analyze the consumption patterns from the electricity bill history and provide insights about trends, seasonal variations, and potential anomalies.'''
            },
            {
              'role': 'user',
              'content': 'Analyze this electricity bill history for consumption patterns:\n\n${jsonEncode(billHistory)}'
            }
          ],
          'temperature': 0.5,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        return {
          'analysis': content,
          'trends': _extractTrends(billHistory),
          'seasonalPatterns': _identifySeasonalPatterns(billHistory),
        };
      } else {
        throw Exception('Failed to analyze patterns: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing consumption patterns: $e');
    }
  }

  // Mock data generators for UI testing
  static Map<String, dynamic> _generateMockBillSummary(String extractedText) {
    return {
      'summary': 'This is a mock electricity bill summary for UI testing. The bill shows typical residential consumption patterns with a total amount of \$125.50 for 450 kWh of electricity.',
      'billDate': DateTime.now().toIso8601String().split('T')[0],
      'totalAmount': 125.50,
      'consumptionKwh': 450.0,
      'ratePerKwh': 0.12,
      'insights': [
        'Your electricity consumption is within normal range for residential use',
        'The bill shows consistent usage patterns compared to previous months',
        'Your rate per kWh is competitive with local utility rates'
      ],
      'recommendations': [
        'Consider switching to LED bulbs to reduce lighting costs',
        'Unplug unused devices to eliminate phantom power consumption',
        'Set your thermostat to 78°F in summer for optimal efficiency'
      ],
    };
  }

  static List<String> _generateMockRecommendations() {
    return [
      'Switch to LED bulbs to save up to 90% on lighting costs',
      'Unplug unused devices to eliminate phantom power consumption',
      'Set your thermostat to 78°F in summer and 68°F in winter',
      'Use ceiling fans to circulate air and reduce AC usage',
      'Consider installing a programmable thermostat',
      'Wash clothes in cold water to save on water heating costs',
      'Seal air leaks around windows and doors to improve efficiency'
    ];
  }

  static Map<String, dynamic> _generateMockAnalysis(List<Map<String, dynamic>> billHistory) {
    return {
      'analysis': 'Based on your bill history, your electricity consumption shows a slight upward trend. Summer months typically show higher usage due to air conditioning. Consider implementing energy-saving measures to reduce costs.',
      'trends': {
        'overallChange': 25.0,
        'percentageChange': 5.2,
        'trend': 'increasing',
        'averageConsumption': 425.0,
      },
      'seasonalPatterns': {
        'monthlyAverages': {1: 380.0, 2: 390.0, 3: 400.0, 4: 420.0, 5: 450.0, 6: 480.0, 7: 500.0, 8: 490.0, 9: 460.0, 10: 430.0, 11: 410.0, 12: 395.0},
        'highestMonth': 7,
        'lowestMonth': 1,
      },
    };
  }

  static Map<String, dynamic> _extractTrends(List<Map<String, dynamic>> billHistory) {
    if (billHistory.isEmpty) return {};
    
    // Simple trend analysis
    final sortedBills = billHistory
        .map((bill) => MapEntry(
              DateTime.parse(bill['billDate']),
              bill['consumptionKwh'] as double,
            ))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedBills.length < 2) return {};

    final first = sortedBills.first.value;
    final last = sortedBills.last.value;
    final change = last - first;
    final percentageChange = (change / first) * 100;

    return {
      'overallChange': change,
      'percentageChange': percentageChange,
      'trend': change > 0 ? 'increasing' : change < 0 ? 'decreasing' : 'stable',
      'averageConsumption': sortedBills.map((e) => e.value).reduce((a, b) => a + b) / sortedBills.length,
    };
  }

  static Map<String, dynamic> _identifySeasonalPatterns(List<Map<String, dynamic>> billHistory) {
    if (billHistory.isEmpty) return {};
    
    // Group by month to identify seasonal patterns
    final monthlyAverages = <int, List<double>>{};
    
    for (final bill in billHistory) {
      final date = DateTime.parse(bill['billDate']);
      final month = date.month;
      final consumption = bill['consumptionKwh'] as double;
      
      monthlyAverages.putIfAbsent(month, () => []).add(consumption);
    }
    
    final seasonalData = monthlyAverages.map((month, consumptions) {
      return MapEntry(month, consumptions.reduce((a, b) => a + b) / consumptions.length);
    });
    
    return {
      'monthlyAverages': seasonalData,
      'highestMonth': seasonalData.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'lowestMonth': seasonalData.entries.reduce((a, b) => a.value < b.value ? a : b).key,
    };
  }
} 