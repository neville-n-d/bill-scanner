import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/electricity_bill.dart';

class BillCard extends StatelessWidget {
  final ElectricityBill bill;
  final VoidCallback? onTap;

  const BillCard({
    super.key,
    required this.bill,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildImagePreview(),
              const SizedBox(width: 16),
              Expanded(child: _buildBillInfo()),
              _buildAmountInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    Widget imageWidget;

    if (kIsWeb) {
      // Placeholder or Image.network (if `bill.imagePath` is a URL)
      imageWidget = Image.network(
        bill.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    } else {
      // Mobile/desktop: use FileImage
      imageWidget = Image(
        image: FileImage(
          File(bill.imagePath),
        ),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageWidget,
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.receipt, color: Colors.grey),
    );
  }

  Widget _buildBillInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMM dd, yyyy').format(bill.billDate),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${bill.consumptionKwh.toStringAsFixed(1)} kWh',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          bill.summary.length > 50
              ? '${bill.summary.substring(0, 50)}...'
              : bill.summary,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAmountInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${bill.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM dd').format(bill.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
