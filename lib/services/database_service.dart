import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/electricity_bill.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'electricity_bills';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    print('🗄️ Initializing database...');

    // Initialize database factory for web
    if (kIsWeb) {
      print('🌐 Running on web platform, initializing FFI database factory');
      databaseFactory = databaseFactoryFfi;
    }

    final String path = join(await getDatabasesPath(), 'electricity_bills.db');
    print('🗄️ Database path: $path');

    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  static Future<void> _createTable(Database db, int version) async {
    print('🗄️ Creating database table...');
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        extractedText TEXT NOT NULL,
        summary TEXT NOT NULL,
        billDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        consumptionKwh REAL NOT NULL,
        ratePerKwh REAL NOT NULL,
        createdAt TEXT NOT NULL,
        tags TEXT,
        additionalData TEXT
      )
    ''');
    print('🗄️ Database table created successfully');
  }

  // Insert a new electricity bill
  static Future<void> insertBill(ElectricityBill bill) async {
    final db = await database;
    await db.insert(_tableName, {
      'id': bill.id,
      'userId': bill.userId,
      'imagePath': bill.imagePath,
      'extractedText': bill.extractedText,
      'summary': bill.summary,
      'billDate': bill.billDate.toIso8601String(),
      'totalAmount': bill.totalAmount,
      'consumptionKwh': bill.consumptionKwh,
      'ratePerKwh': bill.ratePerKwh,
      'createdAt': bill.createdAt.toIso8601String(),
      'tags': bill.tags.join(','),
      'additionalData': jsonEncode(bill.additionalData),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Insert sample data for UI testing
  static Future<void> insertSampleData() async {
    print('📝 Starting sample data insertion...');
    final sampleBills = [
      // ElectricityBill(
      //   id: 'sample-1',
      //   userId: 'test-user-1',
      //   imagePath: '/sample/bill1.jpg',
      //   extractedText: 'Sample electricity bill text 1',
      //   summary:
      //       'January 2024 electricity bill showing 450 kWh consumption with a total amount of \$125.50.',
      //   billDate: DateTime(2024, 1, 15),
      //   totalAmount: 125.50,
      //   consumptionKwh: 450.0,
      //   ratePerKwh: 0.12,
      //   createdAt: DateTime(2024, 1, 15),
      //   tags: ['residential', 'monthly'],
      //   additionalData: {
      //     'insights': [
      //       'Your usage is within normal range',
      //       'Consistent with previous months',
      //     ],
      //     'recommendations': ['Consider LED bulbs', 'Unplug unused devices'],
      //   },
      // ),
      // ElectricityBill(
      //   id: 'sample-2',
      //   userId: 'test-user-1',
      //   imagePath: '/sample/bill2.jpg',
      //   extractedText: 'Sample electricity bill text 2',
      //   summary:
      //       'February 2024 electricity bill showing 480 kWh consumption with a total amount of \$138.60.',
      //   billDate: DateTime(2024, 2, 15),
      //   totalAmount: 138.60,
      //   consumptionKwh: 480.0,
      //   ratePerKwh: 0.12,
      //   createdAt: DateTime(2024, 2, 15),
      //   tags: ['residential', 'monthly'],
      //   additionalData: {
      //     'insights': [
      //       'Usage increased by 6.7%',
      //       'Higher than average for February',
      //     ],
      //     'recommendations': [
      //       'Check for air leaks',
      //       'Optimize thermostat settings',
      //     ],
      //   },
      // ),
      // ElectricityBill(
      //   id: 'sample-3',
      //   userId: 'test-user-1',
      //   imagePath: '/sample/bill3.jpg',
      //   extractedText: 'Sample electricity bill text 3',
      //   summary:
      //       'March 2024 electricity bill showing 520 kWh consumption with a total amount of \$149.60.',
      //   billDate: DateTime(2024, 3, 15),
      //   totalAmount: 149.60,
      //   consumptionKwh: 520.0,
      //   ratePerKwh: 0.12,
      //   createdAt: DateTime(2024, 3, 15),
      //   tags: ['residential', 'monthly'],
      //   additionalData: {
      //     'insights': [
      //       'Usage increased by 8.3%',
      //       'Spring heating may be contributing',
      //     ],
      //     'recommendations': ['Consider energy audit', 'Upgrade insulation'],
      //   },
      // ),
      // ElectricityBill(
      //   id: 'sample-4',
      //   userId: 'test-user-1',
      //   imagePath: '/sample/bill4.jpg',
      //   extractedText: 'Sample electricity bill text 4',
      //   summary:
      //       'April 2024 electricity bill showing 380 kWh consumption with a total amount of \$109.60.',
      //   billDate: DateTime(2024, 4, 15),
      //   totalAmount: 109.60,
      //   consumptionKwh: 380.0,
      //   ratePerKwh: 0.12,
      //   createdAt: DateTime(2024, 4, 15),
      //   tags: ['residential', 'monthly'],
      //   additionalData: {
      //     'insights': ['Usage decreased by 26.9%', 'Excellent improvement'],
      //     'recommendations': [
      //       'Maintain current practices',
      //       'Consider solar panels',
      //     ],
      //   },
      // ),
      // ElectricityBill(
      //   id: 'sample-5',
      //   userId: 'test-user-1',
      //   imagePath: '/sample/bill5.jpg',
      //   extractedText: 'Sample electricity bill text 5',
      //   summary:
      //       'May 2024 electricity bill showing 420 kWh consumption with a total amount of \$121.20.',
      //   billDate: DateTime(2024, 5, 15),
      //   totalAmount: 121.20,
      //   consumptionKwh: 420.0,
      //   ratePerKwh: 0.12,
      //   createdAt: DateTime(2024, 5, 15),
      //   tags: ['residential', 'monthly'],
      //   additionalData: {
      //     'insights': ['Usage increased by 10.5%', 'AC usage starting'],
      //     'recommendations': ['Use ceiling fans', 'Set thermostat to 78°F'],
      //   },
      // ),
    ];

    print('📝 Inserting ${sampleBills.length} sample bills...');
    for (int i = 0; i < sampleBills.length; i++) {
      final bill = sampleBills[i];
      print('📝 Inserting sample bill ${i + 1}: ${bill.summary}');
      await insertBill(bill);
    }
    print('📝 Sample data insertion complete');
  }

  // Get all electricity bills for a user
  static Future<List<ElectricityBill>> getAllBills({
    required String userId,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'billDate DESC',
    );

    return List.generate(maps.length, (i) {
      final additionalData = maps[i]['additionalData'] != null
          ? jsonDecode(maps[i]['additionalData']) as Map<String, dynamic>
          : <String, dynamic>{};
      return ElectricityBill(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        imagePath: maps[i]['imagePath'],
        extractedText: maps[i]['extractedText'],
        summary: maps[i]['summary'],
        billDate: DateTime.parse(maps[i]['billDate']),
        totalAmount: maps[i]['totalAmount'],
        consumptionKwh: maps[i]['consumptionKwh'],
        ratePerKwh: maps[i]['ratePerKwh'],
        insights: List<String>.from(additionalData['insights'] ?? []),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        tags: maps[i]['tags']?.split(',') ?? [],
        additionalData: additionalData,
      );
    });
  }

  // Get a specific bill by ID
  static Future<ElectricityBill?> getBillById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final additionalData = maps[0]['additionalData'] != null
        ? jsonDecode(maps[0]['additionalData']) as Map<String, dynamic>
        : <String, dynamic>{};
    return ElectricityBill(
      id: maps[0]['id'],
      userId: maps[0]['userId'],
      imagePath: maps[0]['imagePath'],
      extractedText: maps[0]['extractedText'],
      summary: maps[0]['summary'],
      billDate: DateTime.parse(maps[0]['billDate']),
      totalAmount: maps[0]['totalAmount'],
      consumptionKwh: maps[0]['consumptionKwh'],
      ratePerKwh: maps[0]['ratePerKwh'],
      insights: List<String>.from(additionalData['insights'] ?? []),
      createdAt: DateTime.parse(maps[0]['createdAt']),
      tags: maps[0]['tags']?.split(',') ?? [],
      additionalData: additionalData,
    );
  }

  // Update a bill
  static Future<void> updateBill(ElectricityBill bill) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'imagePath': bill.imagePath,
        'extractedText': bill.extractedText,
        'summary': bill.summary,
        'billDate': bill.billDate.toIso8601String(),
        'totalAmount': bill.totalAmount,
        'consumptionKwh': bill.consumptionKwh,
        'ratePerKwh': bill.ratePerKwh,
        'createdAt': bill.createdAt.toIso8601String(),
        'tags': bill.tags.join(','),
        'additionalData': jsonEncode(bill.additionalData),
      },
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  // Delete a bill
  static Future<void> deleteBill(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Get bills by date range
  static Future<List<ElectricityBill>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'billDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'billDate DESC',
    );

    return List.generate(maps.length, (i) {
      final additionalData = maps[i]['additionalData'] != null
          ? jsonDecode(maps[i]['additionalData']) as Map<String, dynamic>
          : <String, dynamic>{};
      return ElectricityBill(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        imagePath: maps[i]['imagePath'],
        extractedText: maps[i]['extractedText'],
        summary: maps[i]['summary'],
        billDate: DateTime.parse(maps[i]['billDate']),
        totalAmount: maps[i]['totalAmount'],
        consumptionKwh: maps[i]['consumptionKwh'],
        ratePerKwh: maps[i]['ratePerKwh'],
        insights: List<String>.from(additionalData['insights'] ?? []),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        tags: maps[i]['tags']?.split(',') ?? [],
        additionalData: additionalData,
      );
    });
  }

  // Get monthly consumption data for charts
  static Future<List<Map<String, dynamic>>> getMonthlyConsumptionData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', billDate) as month,
        AVG(consumptionKwh) as avgConsumption,
        AVG(totalAmount) as avgAmount,
        COUNT(*) as billCount
      FROM $_tableName
      GROUP BY strftime('%Y-%m', billDate)
      ORDER BY month DESC
    ''');

    return maps;
  }

  // Get total statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalBills,
        AVG(consumptionKwh) as avgConsumption,
        AVG(totalAmount) as avgAmount,
        SUM(totalAmount) as totalSpent,
        SUM(consumptionKwh) as totalConsumption,
        MIN(billDate) as firstBill,
        MAX(billDate) as lastBill
      FROM $_tableName
    ''');

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {};
  }

  // Check if a bill with the given ID exists in the local database
  static Future<bool> billExists(String billId) async {
    final db = await database;
    print('DEBUG: Checking for bill with id: $billId');
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [billId],
      limit: 1,
    );
    print('DEBUG: Query result: $maps');
    return maps.isNotEmpty;
  }

  // Close the database
  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
