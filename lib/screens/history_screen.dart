import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../models/electricity_bill.dart';
import '../widgets/bill_card.dart';
import '../screens/bill_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'This Month', 'Last Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filterOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          if (billProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final filteredBills = _getFilteredBills(billProvider.bills);

          if (filteredBills.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await billProvider.loadBills();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBills.length,
              itemBuilder: (context, index) {
                final bill = filteredBills[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BillCard(
                    bill: bill,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillDetailScreen(bill: bill),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<ElectricityBill> _getFilteredBills(List<ElectricityBill> bills) {
    List<ElectricityBill> filteredBills = bills;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredBills = filteredBills.where((bill) {
        final query = _searchQuery.toLowerCase();
        return bill.summary.toLowerCase().contains(query) ||
               bill.extractedText.toLowerCase().contains(query) ||
               DateFormat('MMM dd, yyyy').format(bill.billDate).toLowerCase().contains(query);
      }).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Month':
        filteredBills = filteredBills.where((bill) {
          return bill.billDate.year == now.year && bill.billDate.month == now.month;
        }).toList();
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        filteredBills = filteredBills.where((bill) {
          return bill.billDate.year == lastMonth.year && bill.billDate.month == lastMonth.month;
        }).toList();
        break;
      case 'This Year':
        filteredBills = filteredBills.where((bill) {
          return bill.billDate.year == now.year;
        }).toList();
        break;
    }

    return filteredBills;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Bills Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No bills match your search criteria'
                  : 'Start by scanning your first electricity bill',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to camera screen
                  Navigator.pushNamed(context, '/camera');
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Bill'),
              ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Bills'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by summary, text, or date...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
} 