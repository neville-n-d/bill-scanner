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
              if (onSelectionChanged != null) _buildSelectionCheckbox(context),
              _buildImagePreview(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBillInfo(context),
              ),
              _buildAmountInfo(context),
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
              color: Theme.of(context).colorScheme.surfaceVariant, 
              child: Icon(
                Icons.receipt,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillInfo(BuildContext context) {
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bill.summary.length > 50
              ? '${bill.summary.substring(0, 50)}...'
              : bill.summary,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAmountInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${bill.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM dd').format(bill.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCheckbox(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Checkbox(
        value: isSelected,
        onChanged: (value) {
          onSelectionChanged?.call();
        },
        activeColor: Theme.of(context).colorScheme.primary,
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