import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/electricity_bill.dart';

class StorageService {
  static const String _billsKey = 'electricity_bills';
  static const String _statisticsKey = 'bill_statistics';
  
  // Check if we're running on web
  static bool get isWeb => kIsWeb;
  
  // Save bills to storage
  static Future<void> saveBills(List<ElectricityBill> bills) async {
    if (isWeb) {
      await _saveBillsToSharedPreferences(bills);
    } else {
      // Use database service for mobile
      // This will be handled by DatabaseService
    }
  }
  
  // Load bills from storage
  static Future<List<ElectricityBill>> loadBills() async {
    if (isWeb) {
      return await _loadBillsFromSharedPreferences();
    } else {
      // Use database service for mobile
      return [];
    }
  }
  
  // Save statistics to storage
  static Future<void> saveStatistics(Map<String, dynamic> statistics) async {
    if (isWeb) {
      await _saveStatisticsToSharedPreferences(statistics);
    }
  }
  
  // Load statistics from storage
  static Future<Map<String, dynamic>> loadStatistics() async {
    if (isWeb) {
      return await _loadStatisticsFromSharedPreferences();
    } else {
      return {};
    }
  }
  
  // Add a new bill
  static Future<void> addBill(ElectricityBill bill) async {
    if (isWeb) {
      final bills = await _loadBillsFromSharedPreferences();
      bills.insert(0, bill);
      await _saveBillsToSharedPreferences(bills);
    }
  }
  
  // Update a bill
  static Future<void> updateBill(ElectricityBill bill) async {
    if (isWeb) {
      final bills = await _loadBillsFromSharedPreferences();
      final index = bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        bills[index] = bill;
        await _saveBillsToSharedPreferences(bills);
      }
    }
  }
  
  // Delete a bill
  static Future<void> deleteBill(String billId) async {
    if (isWeb) {
      final bills = await _loadBillsFromSharedPreferences();
      bills.removeWhere((bill) => bill.id == billId);
      await _saveBillsToSharedPreferences(bills);
    }
  }
  
  // Clear all data
  static Future<void> clearAllData() async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_billsKey);
      await prefs.remove(_statisticsKey);
    }
  }
  
  // Private methods for SharedPreferences
  static Future<void> _saveBillsToSharedPreferences(List<ElectricityBill> bills) async {
    final prefs = await SharedPreferences.getInstance();
    final billsJson = bills.map((bill) => bill.toJson()).toList();
    await prefs.setString(_billsKey, jsonEncode(billsJson));
    print('💾 Saved ${bills.length} bills to SharedPreferences');
  }
  
  static Future<List<ElectricityBill>> _loadBillsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final billsString = prefs.getString(_billsKey);
    
    if (billsString == null || billsString.isEmpty) {
      print('💾 No bills found in SharedPreferences');
      return [];
    }
    
    try {
      final billsJson = jsonDecode(billsString) as List;
      final bills = billsJson.map((json) => ElectricityBill.fromJson(json)).toList();
      print('💾 Loaded ${bills.length} bills from SharedPreferences');
      return bills;
    } catch (e) {
      print('❌ Error loading bills from SharedPreferences: $e');
      return [];
    }
  }
  
  static Future<void> _saveStatisticsToSharedPreferences(Map<String, dynamic> statistics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statisticsKey, jsonEncode(statistics));
    print('💾 Saved statistics to SharedPreferences');
  }
  
  static Future<Map<String, dynamic>> _loadStatisticsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsString = prefs.getString(_statisticsKey);
    
    if (statisticsString == null || statisticsString.isEmpty) {
      print('💾 No statistics found in SharedPreferences');
      return {};
    }
    
    try {
      final statistics = jsonDecode(statisticsString) as Map<String, dynamic>;
      print('💾 Loaded statistics from SharedPreferences');
      return statistics;
    } catch (e) {
      print('❌ Error loading statistics from SharedPreferences: $e');
      return {};
    }
  }

  // Calculate statistics from bills
  static Map<String, dynamic> calculateStatistics(List<ElectricityBill> bills) {
    if (bills.isEmpty) {
      return {
        'totalBills': 0,
        'avgConsumption': 0.0,
        'avgAmount': 0.0,
        'totalSpent': 0.0,
        'totalConsumption': 0.0,
        'firstBill': null,
        'lastBill': null,
      };
    }

    final totalBills = bills.length;
    final totalConsumption = bills.fold(0.0, (sum, bill) => sum + bill.consumptionKwh);
    final totalSpent = bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
    final avgConsumption = totalConsumption / totalBills;
    final avgAmount = totalSpent / totalBills;

    // Sort bills by date to find first and last
    final sortedBills = List<ElectricityBill>.from(bills)
      ..sort((a, b) => a.billDate.compareTo(b.billDate));

    return {
      'totalBills': totalBills,
      'avgConsumption': avgConsumption,
      'avgAmount': avgAmount,
      'totalSpent': totalSpent,
      'totalConsumption': totalConsumption,
      'firstBill': sortedBills.first.billDate.toIso8601String(),
      'lastBill': sortedBills.last.billDate.toIso8601String(),
    };
  }
} 