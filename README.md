# Electricity Bill Analyzer

A Flutter app that uses OCR and AI to analyze electricity bills, providing insights and energy-saving recommendations.

## Features

### 📸 Bill Scanning & Processing
- **Camera Integration**: Take photos of electricity bills directly in the app
- **Gallery Import**: Import existing bill images from your device
- **OCR Technology**: Extract text from bill images using Google ML Kit
- **AI Analysis**: Generate summaries and insights using Copilot API

### 📊 Analytics & Insights
- **Interactive Charts**: View consumption patterns and trends over time
- **Statistical Analysis**: Track average consumption, costs, and usage patterns
- **Seasonal Analysis**: Identify peak usage periods and seasonal trends
- **Energy Saving Tips**: Get personalized recommendations based on your usage

### 📱 User Experience
- **Modern UI**: Clean, intuitive interface with Material Design 3
- **Bill History**: View and search through all processed bills
- **Detailed Views**: See comprehensive bill analysis and insights
- **Settings**: Customize currency, units, and app preferences

### 💾 Data Management
- **Local Storage**: All data stored securely on your device
- **SQLite Database**: Efficient local database for bill storage
- **Export Capabilities**: Export your data for external analysis
- **Privacy Focused**: Your data stays on your device

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd electricity_bill_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   
   Open `lib/services/ai_service.dart` and replace the placeholder API key:
   ```dart
   static const String _apiKey = 'YOUR_COPILOT_API_KEY'; // Replace with your actual API key
   ```

4. **Platform-specific setup**

   **Android:**
   - Add camera permissions to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

   **iOS:**
   - Add camera permissions to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to scan electricity bills</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app needs photo library access to import bill images</string>
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Usage Guide

### Scanning Your First Bill

1. **Open the app** and tap the "Scan Bill" button
2. **Position your bill** within the camera frame
3. **Take a photo** or import from gallery
4. **Wait for processing** - the app will extract text and generate insights
5. **Review results** - see the summary, details, and recommendations

### Understanding Your Analytics

- **Consumption Chart**: Track your kWh usage over time
- **Amount Chart**: Monitor your spending patterns
- **Trends Analysis**: See if your usage is increasing or decreasing
- **Seasonal Patterns**: Identify peak usage months

### Managing Your Bills

- **View History**: Access all your processed bills
- **Search & Filter**: Find specific bills by date or content
- **Edit Details**: Modify bill information if needed
- **Export Data**: Download your data for external analysis

## Technical Architecture

### Project Structure
```
lib/
├── models/           # Data models
├── services/         # Business logic and external services
├── providers/        # State management
├── screens/          # UI screens
├── widgets/          # Reusable UI components
└── utils/            # Utility functions
```

### Key Dependencies
- **google_ml_kit**: OCR text recognition
- **camera**: Camera functionality
- **sqflite**: Local database
- **provider**: State management
- **fl_chart**: Interactive charts
- **http**: API communication

### Services
- **OCRService**: Text extraction from images
- **AIService**: AI-powered analysis and insights
- **DatabaseService**: Local data storage
- **CameraService**: Camera and image handling

## API Configuration

### Copilot API Setup

1. **Get API Key**: Sign up for GitHub Copilot API access
2. **Configure Endpoint**: Update the API endpoint in `AIService`
3. **Test Connection**: Verify API connectivity

### Custom AI Integration

You can easily replace the Copilot API with other AI services:
- OpenAI GPT
- Google Cloud AI
- Azure Cognitive Services
- Custom ML models

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the code comments

## Future Enhancements

- [ ] Cloud sync capabilities
- [ ] Multiple bill formats support
- [ ] Advanced analytics dashboard
- [ ] Integration with smart meters
- [ ] Energy provider APIs
- [ ] Social sharing features
- [ ] Offline AI processing
- [ ] Multi-language support

## Privacy & Security

- All data is stored locally on your device
- No personal information is shared without consent
- Camera permissions are only used for bill scanning
- API calls are made securely with proper authentication

---

**Note**: This app is for educational and personal use. Always verify bill information manually for important financial decisions.
