import 'dart:io';
import 'dart:typed_data';
import 'lib/services/ai_service.dart';

void main() async {
  print('🔍 Azure OpenAI Bill Analysis Example');
  print('=====================================');
  
  try {
    // Example 1: Analyze bill from text (existing functionality)
    print('\n📝 Example 1: Analyzing bill from text...');
    final textResult = await AIService.generateBillSummary(
      'Electricity Bill - January 2024\nTotal Amount: \$125.50\nConsumption: 450 kWh\nRate: \$0.12 per kWh'
    );
    
    print('✅ Text Analysis Result:');
    print('Summary: ${textResult['summary']}');
    print('Total Amount: \$${textResult['totalAmount']}');
    print('Consumption: ${textResult['consumptionKwh']} kWh');
    print('Rate: \$${textResult['ratePerKwh']} per kWh');
    print('Insights: ${textResult['insights']}');
    print('Recommendations: ${textResult['recommendations']}');
    
    // Example 2: Generate energy saving recommendations
    print('\n💡 Example 2: Generating energy saving recommendations...');
    final billHistory = [
      {
        'billDate': '2024-01-15',
        'consumptionKwh': 450.0,
        'totalAmount': 125.50,
      },
      {
        'billDate': '2024-02-15',
        'consumptionKwh': 480.0,
        'totalAmount': 138.60,
      },
      {
        'billDate': '2024-03-15',
        'consumptionKwh': 520.0,
        'totalAmount': 149.60,
      }
    ];
    
    final recommendations = await AIService.generateEnergySavingRecommendations(billHistory);
    print('✅ Energy Saving Recommendations:');
    for (int i = 0; i < recommendations.length; i++) {
      print('${i + 1}. ${recommendations[i]}');
    }
    
    // Example 3: Analyze consumption patterns
    print('\n📊 Example 3: Analyzing consumption patterns...');
    final patternAnalysis = await AIService.analyzeConsumptionPatterns(billHistory);
    print('✅ Pattern Analysis Result:');
    print('Analysis: ${patternAnalysis['analysis']}');
    print('Trends: ${patternAnalysis['trends']}');
    print('Seasonal Patterns: ${patternAnalysis['seasonalPatterns']}');
    
    // Example 4: Analyze bill from image (new functionality)
    print('\n📸 Example 4: Analyzing bill from image...');
    print('Note: This requires an actual image file. Creating a mock example...');
    
    // Create a mock image file for demonstration
    final mockImagePath = 'mock_bill.jpg';
    final mockImageFile = File(mockImagePath);
    
    if (await mockImageFile.exists()) {
      final imageBytes = await mockImageFile.readAsBytes();
      final imageResult = await AIService.analyzeBillImage(imageBytes);
      
      print('✅ Image Analysis Result:');
      print('Summary: ${imageResult['summary']}');
      print('Total Amount: \$${imageResult['totalAmount']}');
      print('Consumption: ${imageResult['consumptionKwh']} kWh');
      print('Rate: \$${imageResult['ratePerKwh']} per kWh');
      print('Insights: ${imageResult['insights']}');
      print('Recommendations: ${imageResult['recommendations']}');
    } else {
      print('⚠️  Mock image file not found. Skipping image analysis example.');
      print('To test image analysis, place a bill image at: $mockImagePath');
    }
    
    print('\n🎉 All examples completed successfully!');
    
  } catch (e) {
    print('❌ Error running examples: $e');
    print('\n💡 Troubleshooting:');
    print('1. Make sure Azure OpenAI API is properly configured');
    print('2. Check your internet connection');
    print('3. Verify API key and endpoint are correct');
    print('4. Ensure AI is enabled in config.dart (enableAI = true)');
  }
}

// Helper function to create a mock image file for testing
Future<void> createMockImageFile() async {
  // This would create a simple test image
  // For now, just create a placeholder
  final file = File('mock_bill.jpg');
  if (!await file.exists()) {
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // Minimal JPEG header
    print('📁 Created mock image file for testing');
  }
} 