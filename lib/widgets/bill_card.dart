import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/electricity_bill.dart';

class BillCard extends StatelessWidget {
  final ElectricityBill bill;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const BillCard({
    super.key,
    required this.bill,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onSelectionChanged != null ? onSelectionChanged : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (onSelectionChanged != null) _buildSelectionCheckbox(),
              _buildImagePreview(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBillInfo(),
              ),
              _buildAmountInfo(),
              if (onDelete != null && onSelectionChanged == null) _buildDeleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
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
        child: Image.file(
          File(bill.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.receipt,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMM dd, yyyy').format(bill.billDate),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${bill.consumptionKwh.toStringAsFixed(1)} kWh',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bill.summary.length > 50
              ? '${bill.summary.substring(0, 50)}...'
              : bill.summary,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCheckbox() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Checkbox(
        value: isSelected,
        onChanged: (value) {
          onSelectionChanged?.call();
        },
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
        size: 20,
      ),
      tooltip: 'Delete bill',
    );
  }
} 