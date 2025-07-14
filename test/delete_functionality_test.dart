import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_app/providers/bill_provider.dart';
import 'package:electricity_bill_app/models/electricity_bill.dart';

void main() {
  group('Delete Functionality Tests', () {
    test('deleteBill should remove bill from provider', () async {
      // Create a mock bill provider
      final billProvider = BillProvider();
      
      // Create a sample bill
      final bill = ElectricityBill(
        id: 'test-bill-1',
        imagePath: '/test/path.jpg',
        extractedText: 'Test bill text',
        summary: 'Test bill summary',
        billDate: DateTime.now(),
        totalAmount: 100.0,
        consumptionKwh: 500.0,
        ratePerKwh: 0.12,
        createdAt: DateTime.now(),
        tags: ['test'],
        additionalData: {},
      );
      
      // Add bill to provider
      billProvider.bills.add(bill);
      expect(billProvider.bills.length, 1);
      
      // Delete the bill
      await billProvider.deleteBill(bill.id);
      expect(billProvider.bills.length, 0);
    });

    test('deleteBill should handle non-existent bill gracefully', () async {
      final billProvider = BillProvider();
      
      // Try to delete a non-existent bill
      await billProvider.deleteBill('non-existent-id');
      
      // Should not throw an error
      expect(billProvider.bills.length, 0);
    });

    test('deleteBill should update current bill if it was deleted', () async {
      final billProvider = BillProvider();
      
      // Create a sample bill
      final bill = ElectricityBill(
        id: 'test-bill-1',
        imagePath: '/test/path.jpg',
        extractedText: 'Test bill text',
        summary: 'Test bill summary',
        billDate: DateTime.now(),
        totalAmount: 100.0,
        consumptionKwh: 500.0,
        ratePerKwh: 0.12,
        createdAt: DateTime.now(),
        tags: ['test'],
        additionalData: {},
      );
      
      // Set as current bill
      billProvider.setCurrentBill(bill);
      expect(billProvider.currentBill?.id, 'test-bill-1');
      
      // Delete the bill
      await billProvider.deleteBill(bill.id);
      
      // Current bill should be null
      expect(billProvider.currentBill, null);
    });
  });
} 