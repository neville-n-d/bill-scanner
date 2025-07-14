class AppConfig {
  // Feature flags for testing
  static const bool enableAI = true; // Set to true when Azure OpenAI is configured
  static const bool enableSampleData = true; // Set to false in production
  
  // API Configuration
  static const String copilotApiKey = 'YOUR_COPILOT_API_KEY';
  static const String copilotApiUrl = 'https://api.githubcopilot.com';
  
  // App Configuration
  static const String appName = 'Electricity Bill Analyzer';
  static const String appVersion = '1.0.0';
  
  // Database Configuration
  static const String databaseName = 'electricity_bills.db';
  static const int databaseVersion = 1;
  
  // UI Configuration
  static const bool enableDarkMode = false;
  static const String defaultCurrency = 'USD';
  static const String defaultEnergyUnit = 'kWh';
  
  // Camera Configuration
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  
  // Chart Configuration
  static const int chartAnimationDuration = 1000;
  static const bool enableChartAnimations = true;
  
  // Debug Configuration
  static const bool enableDebugLogs = true;
  static const bool enableErrorReporting = false;
} 