# Azure OpenAI Implementation for Bill Parsing

## Overview

This document describes the implementation of Azure OpenAI Vision API for electricity bill parsing in the Flutter app. The implementation uses direct image analysis with Azure OpenAI's GPT-4 Vision model, eliminating the need for separate OCR processing.

## Key Changes

### 1. AI Service Updates (`lib/services/ai_service.dart`)

- **Azure OpenAI Configuration**: Added Azure OpenAI endpoint, deployment name, and API key configuration
- **New Method**: `analyzeBillImage(Uint8List imageBytes)` - Directly analyzes bill images using Azure OpenAI Vision
- **New Method**: `analyzeBillFromFile(String filePath)` - Analyzes bills from file paths (useful for PDF conversion)
- **Updated Methods**: All existing methods now use Azure OpenAI instead of the previous Copilot API

### 2. Bill Provider Updates (`lib/providers/bill_provider.dart`)

- **Direct Image Processing**: Removed OCR dependency and directly uses Azure OpenAI Vision
- **Image Analysis**: Reads image bytes and sends them directly to Azure OpenAI for analysis
- **Structured Response**: Parses JSON response from Azure OpenAI to extract bill information

### 3. Configuration Updates (`lib/utils/config.dart`)

- **AI Enabled**: Set `enableAI = true` to activate Azure OpenAI functionality
- **OCR Removed**: Removed OCR-related configuration flags
- **Feature Flags**: Maintained existing feature flags for testing and development

## API Configuration

```dart
// Azure OpenAI Configuration
static const String _azureEndpoint = "https://nevil-mctuioss-eastus2.openai.azure.com/";
static const String _deploymentName = "gpt-4.1";
static const String _apiKey = "EzBHgcxCWWIdYZb90MF6funaU7P1SOBy6YCidKz35MmKhytHaT0kJQQJ99BGACHYHv6XJ3w3AAAAACOG4H6y";
static const String _apiVersion = "2025-01-01-preview";
```

## Usage

### Analyzing Bill Images

```dart
// Read image file
final File imageFile = File('path/to/bill.jpg');
final Uint8List imageBytes = await imageFile.readAsBytes();

// Analyze with Azure OpenAI
final Map<String, dynamic> result = await AIService.analyzeBillImage(imageBytes);

// Extract bill information
final String summary = result['summary'];
final double totalAmount = result['totalAmount'];
final double consumptionKwh = result['consumptionKwh'];
final List<String> insights = result['insights'];
final List<String> recommendations = result['recommendations'];
```

### Expected Response Format

The Azure OpenAI service returns structured JSON data:

```json
{
  "summary": "Brief summary of the bill",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["Array of insights about the bill"],
  "recommendations": ["Array of energy-saving recommendations"]
}
```

## Benefits

1. **Direct Image Analysis**: Azure OpenAI Vision handles all text extraction and analysis in one step
2. **Better Accuracy**: Azure OpenAI Vision provides more accurate text extraction and understanding
3. **Structured Data**: Returns structured JSON instead of raw text
4. **Insights and Recommendations**: Provides AI-generated insights and energy-saving recommendations
5. **Simplified Architecture**: Eliminates OCR dependency completely
6. **Faster Processing**: Single API call instead of OCR + AI pipeline

## Error Handling

The implementation includes comprehensive error handling:

- **API Failures**: Catches and reports Azure OpenAI API errors
- **JSON Parsing**: Handles cases where the response is not valid JSON
- **Fallback Data**: Provides default values when data extraction fails
- **Mock Data**: Falls back to mock data when AI is disabled for testing

## Testing

A test file has been created (`test/ai_service_test.dart`) to verify the AI service functionality:

```bash
flutter test test/ai_service_test.dart
```

## Security Considerations

- API keys are currently hardcoded for development
- In production, these should be stored securely (environment variables, secure storage)
- Consider implementing API key rotation and monitoring

## Future Enhancements

1. **PDF Support**: Add PDF to image conversion for PDF bill uploads
2. **Batch Processing**: Support for processing multiple bills simultaneously
3. **Caching**: Implement response caching to reduce API calls
4. **Rate Limiting**: Add rate limiting to prevent API quota exhaustion
5. **Alternative Models**: Support for different Azure OpenAI models based on use case

## Dependencies

The implementation uses the following Flutter packages:
- `http`: For making HTTP requests to Azure OpenAI API
- `dart:typed_data`: For handling image bytes
- `dart:io`: For file operations
- `dart:convert`: For JSON encoding/decoding

## Architecture Simplification

The removal of OCR dependency simplifies the architecture significantly. Azure OpenAI Vision handles all text extraction and analysis in a single API call, providing better accuracy and faster processing while reducing complexity. 