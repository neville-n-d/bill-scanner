import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/electricity_bill.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/camera_service.dart';
import '../utils/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Added for jsonDecode
import '../services/auth_service.dart'; // Added for AuthService
import 'package:http_parser/http_parser.dart';

class BillProvider with ChangeNotifier {
  List<ElectricityBill> _bills = [];
  bool _isLoading = false;
  String? _error;
  ElectricityBill? _currentBill;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _suggestions;
  bool _isGeneratingSuggestions = false;
  DateTime? _lastSuggestionGenerated;

  // Getters
  List<ElectricityBill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ElectricityBill? get currentBill => _currentBill;
  Map<String, dynamic>? get statistics => _statistics;
  Map<String, dynamic>? get suggestions => _suggestions;
  bool get isGeneratingSuggestions => _isGeneratingSuggestions;
  DateTime? get lastSuggestionGenerated => _lastSuggestionGenerated;

  // Helper to get current userId
  String? getCurrentUserId() {
    final authService = AuthService();
    return authService.currentUser?.id;
  }

  // Helper to safely parse a double from dynamic input
  double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final v = double.tryParse(value);
      if (v != null) return v;
    }
    return 0.0;
  }

  // Sync local bills to backend
  Future<void> syncLocalBillsToBackend() async {
    try {
      print('🔄 Syncing local bills to backend...');
      final authService = AuthService();
      final token = authService.token;
      final userId = getCurrentUserId();
      if (token == null || userId == null) {
        print('❌ No authentication token or userId for sync');
        return;
      }
      final localBills = await DatabaseService.getAllBills(userId: userId);
      print(
        '📱 Found ${localBills.length} local bills to sync for user $userId',
      );
      for (final bill in localBills) {
        if (!bill.id.startsWith('sample-') && bill.id.length < 24) {
          print('🔄 Syncing local bill: ${bill.id}');
          try {
            final imageFile = File(bill.imagePath);
            if (await imageFile.exists()) {
              final imageBytes = await imageFile.readAsBytes();
              await _uploadBillToBackend(bill, imageBytes);
            } else {
              print('⚠️ Image file not found for bill: ${bill.id}');
            }
          } catch (e) {
            print('❌ Failed to sync bill ${bill.id}: $e');
          }
        } else {
          print('⏭️ Skipping bill ${bill.id} (already synced or sample data)');
        }
      }
      print('✅ Local bill sync complete');
    } catch (e) {
      print('❌ Error syncing local bills: $e');
    }
  }

  // Initialize provider
  Future<void> initialize() async {
    print('🔧 Initializing BillProvider...');

    // Check if user is authenticated before trying to load bills
    final authService = AuthService();
    if (authService.token != null) {
      print('🔑 User is authenticated, loading bills from backend...');
      await loadBills();
      print('📊 Loaded ${_bills.length} bills from backend');

      // Sync any local bills that haven't been uploaded yet
      await syncLocalBillsToBackend();
    } else {
      print('🔒 User not authenticated, skipping bill loading');
      _bills = [];
    }

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
        final userId = getCurrentUserId();
        if (userId != null) {
          await DatabaseService.insertSampleData();
          print('📝 Sample data inserted into database for user $userId');
        } else {
          print('❌ No userId available for sample data insertion');
        }
      }

      await loadBills();
      print('📊 Reloaded bills, now have ${_bills.length} bills');
      await loadStatistics();
    } catch (e) {
      print('❌ Failed to load sample data: $e');
    }
  }

  // Create sample bills
  List<ElectricityBill> _createSampleBills() {
    return [
      ElectricityBill(
        id: 'sample-1',
        userId: '0',
        imagePath: '/sample/bill1.jpg',
        extractedText: 'Sample electricity bill text 1',
        summary:
            'January 2024 electricity bill showing 450 kWh consumption with a total amount of \$125.50.',
        billDate: DateTime(2024, 1, 15),
        totalAmount: 125.50,
        consumptionKwh: 450.0,
        ratePerKwh: 0.12,
        insights: [
          'Your usage is within normal range',
          'Consistent with previous months',
        ],
        createdAt: DateTime(2024, 1, 15),
        tags: ['residential', 'monthly'],
        additionalData: {},
      ),
      ElectricityBill(
        id: 'sample-2',
        userId: '0',
        imagePath: '/sample/bill2.jpg',
        extractedText: 'Sample electricity bill text 2',
        summary:
            'February 2024 electricity bill showing 480 kWh consumption with a total amount of \$138.60.',
        billDate: DateTime(2024, 2, 15),
        totalAmount: 138.60,
        consumptionKwh: 480.0,
        ratePerKwh: 0.12,
        insights: [
          'Usage increased by 6.7%',
          'Higher than average for February',
        ],
        createdAt: DateTime(2024, 2, 15),
        tags: ['residential', 'monthly'],
        additionalData: {},
      ),
      ElectricityBill(
        id: 'sample-3',
        userId: '0',
        imagePath: '/sample/bill3.jpg',
        extractedText: 'Sample electricity bill text 3',
        summary:
            'March 2024 electricity bill showing 520 kWh consumption with a total amount of \$149.60.',
        billDate: DateTime(2024, 3, 15),
        totalAmount: 149.60,
        consumptionKwh: 520.0,
        ratePerKwh: 0.12,
        insights: [
          'Usage increased by 8.3%',
          'Spring heating may be contributing',
        ],
        createdAt: DateTime(2024, 3, 15),
        tags: ['residential', 'monthly'],
        additionalData: {},
      ),
      ElectricityBill(
        id: 'sample-4',
        userId: '0',
        imagePath: '/sample/bill4.jpg',
        extractedText: 'Sample electricity bill text 4',
        summary:
            'April 2024 electricity bill showing 380 kWh consumption with a total amount of \$109.60.',
        billDate: DateTime(2024, 4, 15),
        totalAmount: 109.60,
        consumptionKwh: 380.0,
        ratePerKwh: 0.12,
        insights: [
          'Usage decreased by 26.9%',
          'Excellent improvement',
        ],
        createdAt: DateTime(2024, 4, 15),
        tags: ['residential', 'monthly'],
        additionalData: {},
      ),
      ElectricityBill(
        id: 'sample-5',
        userId: '0',
        imagePath: '/sample/bill5.jpg',
        extractedText: 'Sample electricity bill text 5',
        summary:
            'May 2024 electricity bill showing 420 kWh consumption with a total amount of \$121.20.',
        billDate: DateTime(2024, 5, 15),
        totalAmount: 121.20,
        consumptionKwh: 420.0,
        ratePerKwh: 0.12,
        insights: [
          'Usage increased by 10.5%',
          'AC usage starting',
        ],
        createdAt: DateTime(2024, 5, 15),
        tags: ['residential', 'monthly'],
        additionalData: {},
      ),
    ];
  }

  // Load all bills from backend API
  Future<void> loadBills() async {
    _setLoading(true);
    try {
      print('🌐 Fetching bills from backend API...');
      final authService = AuthService();
      final token = authService.token;
      final userId = getCurrentUserId();

      List<ElectricityBill> backendBills = [];

      if (token != null) {
        print('🔑 Using token: ${token.substring(0, 20)}...');
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/bills'),
          headers: authService.getAuthHeaders(),
        );

        print('📡 Response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final billList = data['data']['bills'] as List<dynamic>;
          backendBills = billList.map((json) {
            return ElectricityBill(
              id: json['_id'] ?? json['id'] ?? '',
              userId: userId ?? '',
              imagePath: json['image']?['originalPath'] ?? '',
              extractedText: json['aiAnalysis']?['summary'] ?? '',
              summary: json['aiAnalysis']?['summary'] ?? '',
              billDate:
                  DateTime.tryParse(json['billDate'] ?? '') ?? DateTime.now(),
              totalAmount: (json['costs']?['total'] ?? 0).toDouble(),
              consumptionKwh: (json['consumption']?['total'] ?? 0).toDouble(),
              ratePerKwh: 0.0,
              insights: List<String>.from(json['insights'] ?? []),
              createdAt:
                  DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
              tags: [],
              additionalData: json,
            );
          }).toList();
          print(
            '🌐 Successfully fetched ${backendBills.length} bills from backend',
          );
          await loadStatistics();
        } else {
          print(
            '❌ Failed to fetch bills: ${response.statusCode} - ${response.body}',
          );
        }
      } else {
        print('❌ No authentication token found');
      }

      // Also load local bills for this user
      List<ElectricityBill> localBills = [];
      try {
        if (userId != null) {
          localBills = await DatabaseService.getAllBills(userId: userId);
          print(
            '📱 Loaded ${localBills.length} bills from local database for user $userId',
          );
        }
      } catch (e) {
        print('❌ Failed to load local bills: $e');
      }

      // Merge bills: backend bills take priority, add local bills that aren't in backend
      final Map<String, ElectricityBill> mergedBills = {};
      for (final bill in backendBills) {
        mergedBills[bill.id] = bill;
      }
      for (final bill in localBills) {
        if (!mergedBills.containsKey(bill.id)) {
          mergedBills[bill.id] = bill;
          print('📱 Added local bill to merged list: ${bill.id}');
        }
      }

      _bills = mergedBills.values.toList();
      _bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('📊 Total bills after merge: ${_bills.length}');
      _error = null;
      await loadStatistics();
    } catch (e) {
      print('❌ Failed to load bills: $e');
      _bills = [];
      _error = 'Failed to load bills: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      // Calculate statistics from the _bills list (fetched from backend)
      double totalAmount = 0;
      double totalConsumption = 0;
      int totalBills = _bills.length;
      double averageMonthlyConsumption = 0;
      double averageMonthlyCost = 0;
      if (_bills.isNotEmpty) {
        totalAmount = _bills.fold(0, (sum, b) => sum + b.totalAmount);
        totalConsumption = _bills.fold(0, (sum, b) => sum + b.consumptionKwh);
        // Group by month/year for average monthly
        final Map<String, List<ElectricityBill>> billsByMonth = {};
        for (final bill in _bills) {
          final key = '${bill.billDate.year}-${bill.billDate.month}';
          billsByMonth.putIfAbsent(key, () => []).add(bill);
        }
        averageMonthlyConsumption =
            billsByMonth.values
                .map(
                  (bills) =>
                      bills.fold(0.0, (sum, b) => sum + b.consumptionKwh),
                )
                .fold(0.0, (sum, v) => sum + v) /
            (billsByMonth.length > 0 ? billsByMonth.length : 1);
        averageMonthlyCost =
            billsByMonth.values
                .map(
                  (bills) => bills.fold(0.0, (sum, b) => sum + b.totalAmount),
                )
                .fold(0.0, (sum, v) => sum + v) /
            (billsByMonth.length > 0 ? billsByMonth.length : 1);
      }
      _statistics = {
        'totalBills': totalBills,
        'totalAmount': totalAmount,
        'totalConsumption': totalConsumption,
        'averageMonthlyConsumption': averageMonthlyConsumption,
        'averageMonthlyCost': averageMonthlyCost,
      };
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
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      // Save image to app directory
      final String savedImagePath = await CameraService.saveImageToAppDirectory(
        imageFile,
      );
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillImage(
        imageBytes,
      );
      // Compose insights: add all new info as a single string
      String detailedInsight = '';
      if (aiResponse['insights'] != null && aiResponse['insights'] is List) {
        detailedInsight += (aiResponse['insights'] as List).join('\n');
      }
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate:
            DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [detailedInsight],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      await _uploadBillToBackend(bill, imageBytes); // Re-enabled backend upload
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Process a new bill from multiple images
  Future<void> processBillFromImages(List<File> imageFiles) async {
    _setLoading(true);
    _error = null;

    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      final String savedImagePath = '';
      final List<Uint8List> imageBytesList = [];
      for (final file in imageFiles) {
        imageBytesList.add(await file.readAsBytes());
      }
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillImages(
        imageBytesList,
      );
      String detailedInsight = '';
      if (aiResponse['insights'] != null && aiResponse['insights'] is List) {
        detailedInsight += (aiResponse['insights'] as List).join('\n');
      }
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate:
            DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [detailedInsight],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      await _uploadBillToBackendMulti(bill, imageBytesList); // Re-enabled backend upload
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Process a new bill from multiple images (bytes)
  Future<void> processBillFromImagesBytes(List<Uint8List> imageBytesList) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      final String savedImagePath = '';
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillImages(imageBytesList);
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate: DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [aiResponse['insights']?.join('\n') ?? ''],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      // await _uploadBillToBackendMulti(bill, imageBytesList); // Disabled backend upload
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Process a new bill from base64 JPEGs
  Future<void> processBillFromBase64Jpegs(List<String> base64Jpegs) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      final String savedImagePath = '';
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillBase64Jpegs(base64Jpegs);
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate: DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [aiResponse['insights']?.join('\n') ?? ''],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      // Optionally upload to backend if needed (disabled)
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Process a new bill from base64 PNGs
  Future<void> processBillFromBase64Pngs(List<String> base64Pngs) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      final String savedImagePath = '';
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillBase64Pngs(base64Pngs);
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate: DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [aiResponse['insights']?.join('\n') ?? ''],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Upload bill to backend API (single image)
  Future<void> _uploadBillToBackend(
    ElectricityBill bill,
    Uint8List imageBytes,
  ) async {
    try {
      print('🌐 Uploading bill to backend...');
      final authService = AuthService();
      final token = authService.token;
      final userId = getCurrentUserId();

      if (token == null || userId == null) {
        print('❌ No authentication token or userId for bill upload');
        return;
      }

      // Create multipart request to /upload endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/bills/upload'),
      );

      // Add headers
      request.headers.addAll(authService.getAuthHeaders());

      // Add image file with correct field name 'billImages' for consistency
      request.files.add(
        http.MultipartFile.fromBytes(
          'billImages', // <-- use plural for consistency
          imageBytes,
          filename: 'bill_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'), // <-- Set content type
        ),
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📡 Upload response status: ${response.statusCode}');
      print('📡 Upload response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Bill uploaded successfully to backend');
        final responseData = jsonDecode(responseBody);
        // Optionally update local DB with backend ID if needed
      } else {
        print(
          '❌ Failed to upload bill to backend: ${response.statusCode} - $responseBody',
        );
        throw Exception(
          'Failed to upload bill to backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error uploading bill to backend: $e');
      // Don't throw here - we still want to save locally even if backend upload fails
    }
  }

  // Upload bill with multiple images to backend API
  Future<void> _uploadBillToBackendMulti(
    ElectricityBill bill,
    List<Uint8List> imageBytesList,
  ) async {
    try {
      print('🌐 Uploading bill with multiple images to backend...');
      final authService = AuthService();
      final token = authService.token;
      final userId = getCurrentUserId();

      if (token == null || userId == null) {
        print('❌ No authentication token or userId for bill upload');
        return;
      }

      if (imageBytesList.isEmpty) {
        // No images: send JSON only
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/bills/upload'),
          headers: {
            ...authService.getAuthHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(bill.toJson()),
        );
        print('📡 Upload response status: ${response.statusCode}');
        print('📡 Upload response body: ${response.body}');
        if (response.statusCode == 201 || response.statusCode == 200) {
          print('✅ Bill uploaded successfully to backend (JSON only)');
        } else {
          print('❌ Failed to upload bill to backend: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to upload bill to backend: ${response.statusCode}');
        }
        return;
      }

      // Create multipart request to /upload endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/bills/upload'),
      );

      // Add headers
      request.headers.addAll(authService.getAuthHeaders());

      // Add all image files with field name 'billImages'
      for (int i = 0; i < imageBytesList.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'billImages', // <-- must match backend
            imageBytesList[i],
            filename: 'bill_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            contentType: MediaType('image', 'jpeg'), // <-- Set content type
          ),
        );
      }

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📡 Upload response status: ${response.statusCode}');
      print('📡 Upload response body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Bill uploaded successfully to backend');
        final responseData = jsonDecode(responseBody);

        // Update bill ID with backend ID if provided
        if (responseData['data']?['billIds'] != null) {
          // Optionally update local DB with backend IDs if needed
        }
      } else {
        print(
          '❌ Failed to upload bill to backend: ${response.statusCode} - $responseBody',
        );
        throw Exception(
          'Failed to upload bill to backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error uploading bill to backend: $e');
      // Don't throw here - we still want to save locally even if backend upload fails
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
      await DatabaseService.deleteBill(billId);
      _bills.removeWhere((bill) => bill.id == billId);

      if (_currentBill?.id == billId) {
        _currentBill = null;
      }

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
  Future<List<ElectricityBill>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
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

  // Generate personalized suggestions based on recent bills
  Future<Map<String, dynamic>?> generatePersonalizedSuggestions() async {
    // Check if we have at least 3 bills
    if (_bills.length < 3) {
      _error = 'You need at least 3 bills to generate personalized suggestions';
      notifyListeners();
      return null;
    }

    // Check if suggestions were already generated after the last bill upload
    if (_lastSuggestionGenerated != null && _suggestions != null) {
      final lastBillUpload = _bills.isNotEmpty ? _bills.first.createdAt : DateTime.now();
      if (_lastSuggestionGenerated!.isAfter(lastBillUpload)) {
        _error = 'Suggestions already generated. Upload a new bill to generate new suggestions.';
        notifyListeners();
        return null;
      }
    }

    // Check if already generating
    if (_isGeneratingSuggestions) {
      return null;
    }

    _setGeneratingSuggestions(true);
    _error = null;

    try {
      print('🤖 Generating personalized suggestions...');
      
      // Get the 3 most recent bills by billDate
      final sortedByBillDate = List<ElectricityBill>.from(_bills)
        ..sort((a, b) => b.billDate.compareTo(a.billDate));
      // In generatePersonalizedSuggestions, use the new model fields for insights and recommendations
      final recentBills = sortedByBillDate.take(3).map((bill) => {
        'billDate': bill.billDate.toIso8601String(),
        'totalAmount': bill.totalAmount,
        'consumptionKwh': bill.consumptionKwh,
        'ratePerKwh': bill.ratePerKwh,
        'summary': bill.summary,
        'insights': bill.insights,
      }).toList();

      // Get TeraHive status from AuthProvider
      final hasTerahiveEss = AuthService().currentUser?.hasTerahiveEss ?? false;

      // Generate suggestions using AI service
      final suggestions = await AIService.generatePersonalizedSuggestions(recentBills, hasTerahiveEss: hasTerahiveEss);
      
      _suggestions = suggestions;
      _lastSuggestionGenerated = DateTime.now();
      
      print('✅ Personalized suggestions generated successfully');
      return suggestions;
    } catch (e) {
      print('❌ Failed to generate suggestions: $e');
      _error = 'Failed to generate suggestions: $e';
      return null;
    } finally {
      _setGeneratingSuggestions(false);
    }
  }

  // Clear suggestions
  void clearSuggestions() {
    _suggestions = null;
    _lastSuggestionGenerated = null;
    notifyListeners();
  }

  // Set generating suggestions state
  void _setGeneratingSuggestions(bool generating) {
    _isGeneratingSuggestions = generating;
    notifyListeners();
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

  // Handle authentication state change
  Future<void> onAuthStateChanged(bool isLoggedIn) async {
    print('🔐 Auth state changed: isLoggedIn = $isLoggedIn');
    if (isLoggedIn) {
      print('🔑 User logged in, fetching bills...');
      await loadBills();
    } else {
      print('🚪 User logged out, clearing bills...');
      clearBills();
    }
  }

  // Clear all bills (for logout)
  void clearBills() {
    _bills.clear();
    _currentBill = null;
    _statistics = null;
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

  // Refresh bills from backend to get AI-processed data
  Future<void> refreshBillsFromBackend() async {
    try {
      print('🔄 Refreshing bills from backend to get AI-processed data...');
      final authService = AuthService();
      final token = authService.token;
      final userId = getCurrentUserId();

      if (token == null || userId == null) {
        print('❌ No authentication token or userId for refresh');
        return;
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/bills'),
        headers: authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final billList = data['data']['bills'] as List<dynamic>;

        // Update existing bills with backend data
        for (final json in billList) {
          final backendBill = ElectricityBill(
            id: json['_id'] ?? json['id'] ?? '',
            userId: userId,
            imagePath: json['image']?['originalPath'] ?? '',
            extractedText: json['aiAnalysis']?['summary'] ?? '',
            summary: json['aiAnalysis']?['summary'] ?? '',
            billDate:
                DateTime.tryParse(json['billDate'] ?? '') ?? DateTime.now(),
            totalAmount: (json['costs']?['total'] ?? 0).toDouble(),
            consumptionKwh: (json['consumption']?['total'] ?? 0).toDouble(),
            ratePerKwh: 0.0,
            insights: List<String>.from(json['insights'] ?? []),
            createdAt:
                DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
            tags: [],
            additionalData: json,
          );

          // Update local bill if it exists
          final localIndex = _bills.indexWhere((b) => b.id == backendBill.id);
          if (localIndex != -1) {
            _bills[localIndex] = backendBill;
            print('🔄 Updated bill with AI data: ${backendBill.id}');
          } else {
            _bills.add(backendBill);
            print('➕ Added new bill from backend: ${backendBill.id}');
          }
        }

        // Sort by newest first
        _bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Reload statistics
        await loadStatistics();

        print('✅ Bills refreshed from backend');
      } else {
        print('❌ Failed to refresh bills: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error refreshing bills: $e');
    }
  }

  // Process a new bill from image bytes (for PDF-to-image backend integration)
  Future<void> processBillFromImageBytes(List<Uint8List> imageBytes) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('No userId for bill creation');
      final String savedImagePath = '';
      final Map<String, dynamic> aiResponse = await AIService.analyzeBillImages(imageBytes);
      String detailedInsight = '';
      if (aiResponse['insights'] != null && aiResponse['insights'] is List) {
        detailedInsight += (aiResponse['insights'] as List).join('\n');
      }
      final bill = ElectricityBill(
        id: const Uuid().v4(),
        userId: userId,
        imagePath: savedImagePath,
        extractedText: aiResponse['summary'] ?? 'No text extracted',
        summary: aiResponse['summary'] ?? 'No summary available',
        billDate: DateTime.tryParse(aiResponse['billDate'] ?? '') ?? DateTime.now(),
        totalAmount: parseDouble(aiResponse['totalAmount']),
        consumptionKwh: parseDouble(aiResponse['consumptionKwh']),
        ratePerKwh: parseDouble(aiResponse['ratePerKwh']),
        insights: [detailedInsight],
        createdAt: DateTime.now(),
        tags: [],
        additionalData: aiResponse,
      );
      await DatabaseService.insertBill(bill);
      await _uploadBillToBackendMulti(bill, imageBytes); // Re-enabled backend upload
      _bills.insert(0, bill);
      _currentBill = bill;
      await loadStatistics();
      _error = null;
    } catch (e) {
      _error = 'Failed to process bill: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
