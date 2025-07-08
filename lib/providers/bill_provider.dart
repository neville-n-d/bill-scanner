import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/electricity_bill.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../services/camera_service.dart';
import '../utils/config.dart';

class BillProvider with ChangeNotifier {
  List<ElectricityBill> _bills = [];
  bool _isLoading = false;
  String? _error;
  ElectricityBill? _currentBill;
  Map<String, dynamic>? _statistics;

  // Getters
  List<ElectricityBill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ElectricityBill? get currentBill => _currentBill;
  Map<String, dynamic>? get statistics => _statistics;

  // Initialize provider
  Future<void> initialize() async {
    print('🔧 Initializing BillProvider...');
    await loadBills();
    print('📊 Loaded ${_bills.length} bills from storage');
    
    // Load sample data if no bills exist and sample data is enabled
    if (_bills.isEmpty && AppConfig.enableSampleData) {
      print('📝 No bills found, loading sample data...');
      await loadSampleData();
    }
    
    await loadStatistics();
    print('✅ BillProvider initialization complete');
  }

  // Force reload sample data (for testing)
  Future<void> forceReloadSampleData() async {
    print('🔄 Force reloading sample data...');
    try {
      // Clear existing bills
      _bills.clear();
      notifyListeners();
      
      // Insert sample data
      await loadSampleData();
      
      // Reload statistics
      await loadStatistics();
      
      print('✅ Sample data force reload complete');
    } catch (e) {
      print('❌ Failed to force reload sample data: $e');
    }
  }

  Future<void> deleteAll() async {
    _bills.clear();
    await loadStatistics();
  }

  // Load sample data for UI testing
  Future<void> loadSampleData() async {
    try {
      print('📝 Creating sample data...');
      final sampleBills = _createSampleBills();
      print('📝 Created ${sampleBills.length} sample bills');
      
      if (kIsWeb) {
        // Use storage service for web
        await StorageService.saveBills(sampleBills);
        print('📝 Sample data saved to SharedPreferences');
      } else {
        // Use database service for mobile
        await DatabaseService.insertSampleData();
        print('📝 Sample data inserted into database');
      }
      
      await loadBills();
      print('📊 Reloaded bills, now have ${_bills.length} bills');
    } catch (e) {
      print('❌ Failed to load sample data: $e');
    }
  }

  // Create sample bills
  List<ElectricityBill> _createSampleBills() {
    return [
      ElectricityBill(
        id: 'sample-1',
        imagePath: '/sample/bill1.jpg',
        extractedText: 'Sample electricity bill text 1',
        summary: 'January 2024 electricity bill showing 450 kWh consumption with a total amount of \$125.50.',
        billDate: DateTime(2024, 1, 15),
        totalAmount: 125.50,
        consumptionKwh: 450.0,
        ratePerKwh: 0.12,
        createdAt: DateTime(2024, 1, 15),
        tags: ['residential', 'monthly'],
        additionalData: {
          'insights': ['Your usage is within normal range', 'Consistent with previous months'],
          'recommendations': ['Consider LED bulbs', 'Unplug unused devices'],
        },
      ),
      ElectricityBill(
        id: 'sample-2',
        imagePath: '/sample/bill2.jpg',
        extractedText: 'Sample electricity bill text 2',
        summary: 'February 2024 electricity bill showing 480 kWh consumption with a total amount of \$138.60.',
        billDate: DateTime(2024, 2, 15),
        totalAmount: 138.60,
        consumptionKwh: 480.0,
        ratePerKwh: 0.12,
        createdAt: DateTime(2024, 2, 15),
        tags: ['residential', 'monthly'],
        additionalData: {
          'insights': ['Usage increased by 6.7%', 'Higher than average for February'],
          'recommendations': ['Check for air leaks', 'Optimize thermostat settings'],
        },
      ),
      ElectricityBill(
        id: 'sample-3',
        imagePath: '/sample/bill3.jpg',
        extractedText: 'Sample electricity bill text 3',
        summary: 'March 2024 electricity bill showing 520 kWh consumption with a total amount of \$149.60.',
        billDate: DateTime(2024, 3, 15),
        totalAmount: 149.60,
        consumptionKwh: 520.0,
        ratePerKwh: 0.12,
        createdAt: DateTime(2024, 3, 15),
        tags: ['residential', 'monthly'],
        additionalData: {
          'insights': ['Usage increased by 8.3%', 'Spring heating may be contributing'],
          'recommendations': ['Consider energy audit', 'Upgrade insulation'],
        },
      ),
      ElectricityBill(
        id: 'sample-4',
        imagePath: '/sample/bill4.jpg',
        extractedText: 'Sample electricity bill text 4',
        summary: 'April 2024 electricity bill showing 380 kWh consumption with a total amount of \$109.60.',
        billDate: DateTime(2024, 4, 15),
        totalAmount: 109.60,
        consumptionKwh: 380.0,
        ratePerKwh: 0.12,
        createdAt: DateTime(2024, 4, 15),
        tags: ['residential', 'monthly'],
        additionalData: {
          'insights': ['Usage decreased by 26.9%', 'Excellent improvement'],
          'recommendations': ['Maintain current practices', 'Consider solar panels'],
        },
      ),
      ElectricityBill(
        id: 'sample-5',
        imagePath: '/sample/bill5.jpg',
        extractedText: 'Sample electricity bill text 5',
        summary: 'May 2024 electricity bill showing 420 kWh consumption with a total amount of \$121.20.',
        billDate: DateTime(2024, 5, 15),
        totalAmount: 121.20,
        consumptionKwh: 420.0,
        ratePerKwh: 0.12,
        createdAt: DateTime(2024, 5, 15),
        tags: ['residential', 'monthly'],
        additionalData: {
          'insights': ['Usage increased by 10.5%', 'AC usage starting'],
          'recommendations': ['Use ceiling fans', 'Set thermostat to 78°F'],
        },
      ),
    ];
  }

  // Load all bills from storage
  Future<void> loadBills() async {
    _setLoading(true);
    try {
      print('📊 Loading bills from storage...');
      
      if (kIsWeb) {
        // Use storage service for web
        _bills = await StorageService.loadBills();
      } else {
        // Use database service for mobile
        _bills = await DatabaseService.getAllBills();
      }
      
      print('📊 Successfully loaded ${_bills.length} bills');
      _error = null;
    } catch (e) {
      print('❌ Failed to load bills: $e');
      _error = 'Failed to load bills: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      if (kIsWeb) {
        // Calculate statistics from bills for web
        _statistics = StorageService.calculateStatistics(_bills);
        await StorageService.saveStatistics(_statistics!);
      } else {
        // Use database service for mobile
        _statistics = await DatabaseService.getStatistics();
      }
      notifyListeners();
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  // Process a new bill from image
  Future<void> processBillFromImage(File imageFile) async {
    _setLoading(true);
    _error = null;

    try {
      // Save image to app directory
      final String savedImagePath = await CameraService.saveImageToAppDirectory(imageFile);

      // Extract text using OCR (currently returns mock data)
      final String extractedText = await OCRService.extractTextFromImage(savedImagePath);

      // Generate summary using AI (currently returns mock data)
      final Map<String, dynamic> aiResponse = await AIService.generateBillSummary(extractedText);

      // Create bill object
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        imagePath: savedImagePath,
        extractedText: extractedText,
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate: DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: (aiResponse['totalAmount'] ?? 0.0).toDouble(),
        consumptionKwh: (aiResponse['consumptionKwh'] ?? 0.0).toDouble(),
        ratePerKwh: (aiResponse['ratePerKwh'] ?? 0.0).toDouble(),
        createdAt: DateTime.now(),
        tags: [],
        additionalData: {
          'insights': aiResponse['insights'] ?? [],
          'recommendations': aiResponse['recommendations'] ?? [],
        },
      );

      // Save to database
      //await DatabaseService.insertBill(bill);

      // Add to local list
      _bills.insert(0, bill);
      _currentBill = bill;

      // Reload statistics
      await loadStatistics();

      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update a bill
  Future<void> updateBill(ElectricityBill bill) async {
    _setLoading(true);
    try {
      await DatabaseService.updateBill(bill);
      
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to update bill: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Delete a bill
  Future<void> deleteBill(String billId) async {
    _setLoading(true);
    try {
      print(billId);
      //await DatabaseService.deleteBill(billId);
      _bills.removeWhere((bill) => bill.id == billId);
      
      if (_currentBill?.id == billId) {
        _currentBill = null;
      }
      print(_bills.length);
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete bill: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get bill by ID
  Future<ElectricityBill?> getBillById(String id) async {
    try {
      return await DatabaseService.getBillById(id);
    } catch (e) {
      _error = 'Failed to get bill: $e';
      return null;
    }
  }

  // Get bills by date range
  Future<List<ElectricityBill>> getBillsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await DatabaseService.getBillsByDateRange(startDate, endDate);
    } catch (e) {
      _error = 'Failed to get bills by date range: $e';
      return [];
    }
  }

  // Get monthly consumption data for charts
  Future<List<Map<String, dynamic>>> getMonthlyConsumptionData() async {
    try {
      return await DatabaseService.getMonthlyConsumptionData();
    } catch (e) {
      _error = 'Failed to get consumption data: $e';
      return [];
    }
  }

  // Generate energy saving recommendations
  Future<List<String>> generateRecommendations() async {
    try {
      final billHistory = _bills.map((bill) => bill.toJson()).toList();
      return await AIService.generateEnergySavingRecommendations(billHistory);
    } catch (e) {
      _error = 'Failed to generate recommendations: $e';
      return [];
    }
  }

  // Analyze consumption patterns
  Future<Map<String, dynamic>> analyzeConsumptionPatterns() async {
    try {
      final billHistory = _bills.map((bill) => bill.toJson()).toList();
      return await AIService.analyzeConsumptionPatterns(billHistory);
    } catch (e) {
      _error = 'Failed to analyze patterns: $e';
      return {};
    }
  }

  // Set current bill
  void setCurrentBill(ElectricityBill? bill) {
    _currentBill = bill;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get bills for a specific month
  List<ElectricityBill> getBillsForMonth(int year, int month) {
    return _bills.where((bill) {
      return bill.billDate.year == year && bill.billDate.month == month;
    }).toList();
  }

  // Get total consumption for a month
  double getTotalConsumptionForMonth(int year, int month) {
    final monthBills = getBillsForMonth(year, month);
    return monthBills.fold(0.0, (sum, bill) => sum + bill.consumptionKwh);
  }

  // Get total amount for a month
  double getTotalAmountForMonth(int year, int month) {
    final monthBills = getBillsForMonth(year, month);
    return monthBills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
  }

  // Get average consumption
  double get averageConsumption {
    if (_bills.isEmpty) return 0.0;
    final total = _bills.fold(0.0, (sum, bill) => sum + bill.consumptionKwh);
    return total / _bills.length;
  }

  // Get average amount
  double get averageAmount {
    if (_bills.isEmpty) return 0.0;
    final total = _bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
    return total / _bills.length;
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
} 