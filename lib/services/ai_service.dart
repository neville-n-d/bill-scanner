import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class AIService {
  // Azure OpenAI Configuration
  static const String _azureEndpoint =
      "https://nevil-mctuioss-eastus2.openai.azure.com/";
  static const String _deploymentName = "gpt-4.1";
  static const String _apiKey =
      "EzBHgcxCWWIdYZb90MF6funaU7P1SOBy6YCidKz35MmKhytHaT0kJQQJ99BGACHYHv6XJ3w3AAAAACOG4H6y";
  static const String _apiVersion = "2025-01-01-preview";

  // API calls controlled by config
  static bool get _apiEnabled => AppConfig.enableAI;

  static Future<Map<String, dynamic>> generateBillSummary(
    String extractedText,
  ) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary(extractedText);
    }

    try {
      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an expert in analyzing electricity bills and utility rate plans. Extract all available information and organize it in the following JSON format. All detailed extracted information (utility name, tariff, rate plan, seasons, recommendations, etc.) should be included as a single multi-line string in the insights array. If a field is not available in the input document, indicate the value as "N/A".

Return JSON in this format:
{
  "summary": "Brief summary of the electricity bill or plan",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["All detailed extracted information as a single multi-line string"],
}
''',
            },
            {
              'role': 'user',
              'content':
                  'Please analyze this electricity bill text and extract the key information:\n\n$extractedText',
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
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
            'recommendations': [
              'Consider uploading a clearer image for better analysis',
            ],
          };
        }
      } else {
        throw Exception('Failed to generate summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating bill summary: $e');
    }
  }

  /// New method for analyzing bill images using Azure OpenAI Vision
  static Future<Map<String, dynamic>> analyzeBillImage(
    Uint8List imageBytes,
  ) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary("Image analysis");
    }

    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''You are an expert in analyzing electricity bills and utility rate plans. Extract all available information and organize it in the following JSON format. All detailed extracted information (utility name, tariff, rate plan, seasons, recommendations, etc.) should be included as a single multi-line string in the insights array. If a field is not available in the input document, indicate the value as "N/A".

Return JSON in this format:
{
  "summary": "Brief summary of the electricity bill or plan",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["All detailed extracted information as a single multi-line string"],
}
''',
                },
              ],
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
                {
                  'type': 'text',
                  'text': 'Create a summary of this electricity bill',
                },
              ],
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
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
            'insights': ['Unable to extract specific data from image'],
            'recommendations': [
              'Consider uploading a clearer image for better analysis',
            ],
          };
        }
      } else {
        throw Exception(
          'Failed to analyze image: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error analyzing bill image: $e');
    }
  }

  /// Analyze multiple bill images using Azure OpenAI Vision
  static Future<Map<String, dynamic>> analyzeBillImages(
    List<Uint8List> imageBytesList,
  ) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary("Multi-image analysis");
    }

    try {
      // Convert all images to base64
      final List<Map<String, dynamic>> imageMessages = imageBytesList
          .map(
            (bytes) => {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
              },
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''You are an expert in analyzing electricity bills and utility rate plans. Extract all available information and organize it in the following JSON format. Others like utility name, tariff, rate plan, rates during off / peak, duration of rates, seasons. should be included as a single multi-line string in the insights array. If a field is not available in the input document, indicate the value as "N/A" and make it compact and easy to understand and easy to read.

Return JSON in this format:
{
  "summary": "Brief summary of the electricity bill or plan",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["All detailed extracted information as a single multi-line string"],
}
''',
                },
              ],
            },
            {
              'role': 'user',
              'content': [
                ...imageMessages,
                {
                  'type': 'text',
                  'text': 'Create a summary of these electricity bill images',
                },
              ],
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
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
            'utilityName': 'N/A',
            'tariffType': 'N/A',
            'seasons': [],
            'insights': ['Unable to extract specific data'],
            'recommendations': [
              'Consider uploading clearer images for better analysis',
            ],
          };
        }
      } else {
        throw Exception('Failed to generate summary:  [${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating bill summary: $e');
    }
  }

  /// Analyze base64 JPEG images using Azure OpenAI Vision
  static Future<Map<String, dynamic>> analyzeBillBase64Jpegs(
    List<String> base64Jpegs,
  ) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary("Multi-image analysis");
    }

    try {
      // Prepare image messages
      final List<Map<String, dynamic>> imageMessages = base64Jpegs
          .map(
            (b64) => {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$b64'},
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''You are an expert in analyzing electricity bills and utility rate plans. Extract all available information and organize it in the following JSON format. All detailed extracted information (utility name, tariff, rate plan, seasons, recommendations, etc.) should be included as a single multi-line string in the insights array. If a field is not available in the input document, indicate the value as "N/A".

Return JSON in this format:
{
  "summary": "Brief summary of the electricity bill or plan",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["All detailed extracted information as a single multi-line string"],
}
''',
                },
              ],
            },
            {
              'role': 'user',
              'content': [
                ...imageMessages,
                {
                  'type': 'text',
                  'text': 'Create a summary of these electricity bill images',
                },
              ],
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
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
            'utilityName': 'N/A',
            'tariffType': 'N/A',
            'seasons': [],
            'insights': ['Unable to extract specific data'],
            'recommendations': [
              'Consider uploading clearer images for better analysis',
            ],
          };
        }
      } else {
        throw Exception('Failed to generate summary:  [${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating bill summary: $e');
    }
  }

  /// Analyze base64 PNG images using Azure OpenAI Vision
  static Future<Map<String, dynamic>> analyzeBillBase64Pngs(
    List<String> base64Pngs,
  ) async {
    // Return mock data for UI testing
    if (!_apiEnabled) {
      return _generateMockBillSummary("Multi-image analysis");
    }

    try {
      // Prepare image messages
      final List<Map<String, dynamic>> imageMessages = base64Pngs
          .map(
            (b64) => {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$b64'},
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': [
                {
                  'type': 'text',
                  'text':
                      '''You are an expert in analyzing electricity bills and utility rate plans. Extract all available information and organize it in the following JSON format. All detailed extracted information (utility name, tariff, rate plan, seasons, recommendations, etc.) should be included as a single multi-line string in the insights array. If a field is not available in the input document, indicate the value as "N/A".

Return JSON in this format:
{
  "summary": "Brief summary of the electricity bill or plan",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["All detailed extracted information as a single multi-line string"],
}
''',
                },
              ],
            },
            {
              'role': 'user',
              'content': [
                ...imageMessages,
                {
                  'type': 'text',
                  'text': 'Create a summary of these electricity bill images',
                },
              ],
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
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
            'utilityName': 'N/A',
            'tariffType': 'N/A',
            'seasons': [],
            'insights': ['Unable to extract specific data'],
            'recommendations': [
              'Consider uploading clearer images for better analysis',
            ],
          };
        }
      } else {
        throw Exception('Failed to generate summary:  [${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating bill summary: $e');
    }
  }

  /// Method to analyze bill from file path (for PDF conversion support)
  static Future<Map<String, dynamic>> analyzeBillFromFile(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final imageBytes = await file.readAsBytes();
      return await analyzeBillImage(imageBytes);
    } catch (e) {
      throw Exception('Error reading file: $e');
    }
  }

  /// Uploads a PDF to the backend and returns a list of base64 image strings.
  static Future<List<String>> uploadPdfAndGetImages(File pdfFile) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(pdfFile.path, filename: 'bill.pdf'),
    });
    final response = await dio.post(
      'http://172.20.10.3:5001/convert_pdf', // Use your backend IP and port
      data: formData,
    );
    if (response.statusCode == 200) {
      return List<String>.from(response.data['images']);
    } else {
      throw Exception('Failed to convert PDF');
    }
  }

  /// Helper to convert base64 images to Uint8List for further processing
  static List<Uint8List> base64ImagesToUint8List(List<String> base64Images) {
    return base64Images.map((b64) => base64Decode(b64)).toList();
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
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an energy efficiency expert. Based on the user's electricity bill history, provide personalized recommendations for saving energy and money. Focus on practical, actionable advice that can be implemented immediately.''',
            },
            {
              'role': 'user',
              'content':
                  'Based on this electricity bill history, provide 5-7 specific recommendations for saving energy and money:\n\n${jsonEncode(billHistory)}',
            },
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
        throw Exception(
          'Failed to generate recommendations: ${response.statusCode}',
        );
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
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an energy analyst. Analyze the consumption patterns from the electricity bill history and provide insights about trends, seasonal variations, and potential anomalies.''',
            },
            {
              'role': 'user',
              'content':
                  'Analyze this electricity bill history for consumption patterns:\n\n${jsonEncode(billHistory)}',
            },
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

  static Future<Map<String, dynamic>> generatePersonalizedSuggestions(
    List<Map<String, dynamic>> recentBills, {
    bool hasTerahiveEss = false,
  }) async {
    // Return mock suggestions for UI testing
    if (!_apiEnabled) {
      return _generateMockPersonalizedSuggestions(recentBills);
    }

    try {
      final prompt = hasTerahiveEss
          ? '''You are an energy efficiency expert. The user ALREADY has a TeraHive LiteOn Energy Suite system installed. Based on the user's recent electricity bills, provide personalized recommendations for saving even more money and energy. Do NOT recommend installing TeraHive again. Focus on further optimizations, usage habits, and other products or strategies.\n\nProvide your response in this exact JSON format:\n{\n  "summary": "Brief analysis of their consumption patterns",\n  "immediateActions": ["3-5 quick actions they can take today"],\n  "mediumTerm": ["3-5 actions for the next 1-3 months"],\n  "longTerm": ["3-5 actions for long-term savings (no need to mention TeraHive again)"],\n  "potentialSavings": "Estimated monthly/annual savings in dollars"\n}'''
          : '''You are an energy efficiency expert specializing in residential electricity optimization. Based on the user's recent electricity bills, provide personalized recommendations for saving money and energy.\n\nIMPORTANT: Include specific recommendations for TeraHive Energy Suite product where applicable.\n\nProvide your response in this exact JSON format:\n{\n  "summary": "Brief analysis of their consumption patterns",\n  "immediateActions": ["3-5 quick actions they can take today"],\n  "mediumTerm": ["3-5 actions for the next 1-3 months"],\n  "longTerm": ["3-5 actions including TeraHive products"],\n  "potentialSavings": "Estimated monthly/annual savings in dollars",\n  "terahive Recommendations": ["Specific TeraHive product recommendations"]\n}''';

      final response = await http.post(
        Uri.parse(
          '$_azureEndpoint/openai/deployments/$_deploymentName/chat/completions?api-version=$_apiVersion',
        ),
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': prompt},
            {
              'role': 'user',
              'content':
                  'Analyze these 3 most recent electricity bills and provide personalized savings suggestions:\n\n${jsonEncode(recentBills)}',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1200,
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
            'immediateActions': [
              'Switch to LED bulbs',
              'Unplug unused devices',
              'Set thermostat to 78°F in summer',
            ],
            'mediumTerm': [
              'Install a programmable thermostat',
              'Seal air leaks around windows',
              'Consider energy audit',
            ],
            'longTerm': [
              'Install TeraHive LiteOn ESS for energy storage',
              'Consider solar panel installation',
              'Upgrade to energy-efficient appliances',
            ],
            'potentialSavings': 'Estimated \$50-100 per month',
            'terahiveRecommendations': [
              'TeraHive LiteOn residential ESS system',
              'Smart energy management integration',
            ],
          };
        }
      } else {
        throw Exception(
          'Failed to generate suggestions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error generating personalized suggestions: $e');
    }
  }

  // Mock data generators for UI testing
  static Map<String, dynamic> _generateMockBillSummary(String extractedText) {
    return {
      'summary':
          'This is a mock electricity bill summary for UI testing. The bill shows typical residential consumption patterns with a total amount of \$125.50 for 450 kWh of electricity.',
      'billDate': DateTime.now().toIso8601String().split('T')[0],
      'totalAmount': 125.50,
      'consumptionKwh': 450.0,
      'ratePerKwh': 0.12,
      'insights': [
        'Your electricity consumption is within normal range for residential use',
        'The bill shows consistent usage patterns compared to previous months',
        'Your rate per kWh is competitive with local utility rates',
      ],
      'recommendations': [
        'Consider switching to LED bulbs to reduce lighting costs',
        'Unplug unused devices to eliminate phantom power consumption',
        'Set your thermostat to 78°F in summer for optimal efficiency',
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
      'Seal air leaks around windows and doors to improve efficiency',
    ];
  }

  static Map<String, dynamic> _generateMockAnalysis(
    List<Map<String, dynamic>> billHistory,
  ) {
    return {
      'analysis':
          'Based on your bill history, your electricity consumption shows a slight upward trend. Summer months typically show higher usage due to air conditioning. Consider implementing energy-saving measures to reduce costs.',
      'trends': {
        'overallChange': 25.0,
        'percentageChange': 5.2,
        'trend': 'increasing',
        'averageConsumption': 425.0,
      },
      'seasonalPatterns': {
        'monthlyAverages': {
          1: 380.0,
          2: 390.0,
          3: 400.0,
          4: 420.0,
          5: 450.0,
          6: 480.0,
          7: 500.0,
          8: 490.0,
          9: 460.0,
          10: 430.0,
          11: 410.0,
          12: 395.0,
        },
        'highestMonth': 7,
        'lowestMonth': 1,
      },
    };
  }

  static Map<String, dynamic> _generateMockPersonalizedSuggestions(
    List<Map<String, dynamic>> recentBills,
  ) {
    return {
      'summary':
          'Based on your recent bills, your electricity consumption shows a moderate increase, primarily driven by air conditioning usage. Your average monthly consumption of 450 kWh is slightly above the residential average, presenting opportunities for significant savings.',
      'immediateActions': [
        'Switch to LED bulbs to save up to 90% on lighting costs',
        'Unplug unused devices to eliminate phantom power consumption',
        'Set your thermostat to 78°F in summer for optimal efficiency',
        'Use ceiling fans to circulate air and reduce AC usage',
        'Wash clothes in cold water to save on water heating costs',
      ],
      'mediumTerm': [
        'Install a programmable thermostat to better control temperature',
        'Seal air leaks around windows and doors to improve insulation',
        'Consider energy audit to identify potential inefficiencies',
        'Upgrade to energy-efficient appliances when possible',
        'Install smart power strips to control multiple devices',
      ],
      'longTerm': [
        'Install TeraHive LiteOn ESS for energy storage to reduce reliance on grid power',
        'Consider solar panel installation to offset electricity costs',
        'Upgrade to energy-efficient appliances and lighting',
        'Implement smart home automation for better energy management',
        'Consider TeraHive LiteOn peak shaving solutions',
      ],
      'potentialSavings':
          'Estimated \$75-150 per month with full implementation',
      'terahiveRecommendations': [
        'TeraHive LiteOn residential ESS system for energy storage',
        'Smart energy management integration for automated optimization',
        'Peak shaving capabilities to reduce demand charges',
        'Backup power solutions for grid independence',
      ],
    };
  }

  static Map<String, dynamic> _extractTrends(
    List<Map<String, dynamic>> billHistory,
  ) {
    if (billHistory.isEmpty) return {};

    // Simple trend analysis
    final sortedBills =
        billHistory
            .map(
              (bill) => MapEntry(
                DateTime.parse(bill['billDate']),
                bill['consumptionKwh'] as double,
              ),
            )
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
      'trend': change > 0
          ? 'increasing'
          : change < 0
          ? 'decreasing'
          : 'stable',
      'averageConsumption':
          sortedBills.map((e) => e.value).reduce((a, b) => a + b) /
          sortedBills.length,
    };
  }

  static Map<String, dynamic> _identifySeasonalPatterns(
    List<Map<String, dynamic>> billHistory,
  ) {
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
      return MapEntry(
        month,
        consumptions.reduce((a, b) => a + b) / consumptions.length,
      );
    });

    return {
      'monthlyAverages': seasonalData,
      'highestMonth': seasonalData.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
      'lowestMonth': seasonalData.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key,
    };
  }
}
