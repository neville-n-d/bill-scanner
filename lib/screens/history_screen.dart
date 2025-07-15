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
  final List<String> _filterOptions = [
    'All',
    'This Month',
    'Last Month',
    'This Year',
  ];
  bool _isSelectionMode = false;
  Set<String> _selectedBills = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedBills.length} selected')
            : const Text('Bill History', style: TextStyle(color: Colors.black)),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedBills.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedBills.isNotEmpty
                  ? _deleteSelectedBills
                  : null,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _showSearchDialog();
              },
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              itemBuilder: (context) => _filterOptions.map((option) {
                return PopupMenuItem(value: option, child: Text(option));
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
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          if (billProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                  child: Dismissible(
                    key: Key(bill.id),
                    direction:
                        DismissDirection.endToStart, // Swipe left to delete
                    background: _buildDeleteBackground(),
                    confirmDismiss: (direction) =>
                        _showDeleteConfirmation(context, bill),
                    onDismissed: (direction) {
                      _deleteBill(context, bill);
                    },
                    child: BillCard(
                      bill: bill,
                      isSelected: _selectedBills.contains(bill.id),
                      onTap: () {
                        if (!_isSelectionMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BillDetailScreen(bill: bill),
                            ),
                          );
                        }
                      },
                      onSelectionChanged: _isSelectionMode
                          ? () {
                              setState(() {
                                if (_selectedBills.contains(bill.id)) {
                                  _selectedBills.remove(bill.id);
                                } else {
                                  _selectedBills.add(bill.id);
                                }
                              });
                            }
                          : null,
                      onDelete: _isSelectionMode
                          ? null
                          : () => _showDeleteConfirmation(context, bill).then((
                              confirmed,
                            ) {
                              if (confirmed == true) {
                                _deleteBill(context, bill);
                              }
                            }),
                    ),
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
            DateFormat(
              'MMM dd, yyyy',
            ).format(bill.billDate).toLowerCase().contains(query);
      }).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Month':
        filteredBills = filteredBills.where((bill) {
          return bill.billDate.year == now.year &&
              bill.billDate.month == now.month;
        }).toList();
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        filteredBills = filteredBills.where((bill) {
          return bill.billDate.year == lastMonth.year &&
              bill.billDate.month == lastMonth.month;
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
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Bills Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No bills match your search criteria'
                  : 'Start by scanning your first electricity bill',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
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

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    ElectricityBill bill,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete the bill from ${DateFormat('MMM dd, yyyy').format(bill.billDate)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBill(BuildContext context, ElectricityBill bill) async {
    try {
      final billProvider = context.read<BillProvider>();
      await billProvider.deleteBill(bill.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill from ${DateFormat('MMM dd, yyyy').format(bill.billDate)} deleted successfully',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo functionality coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedBills() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Bills'),
        content: Text(
          'Are you sure you want to delete ${_selectedBills.length} selected bill${_selectedBills.length == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final billProvider = context.read<BillProvider>();
        final filteredBills = _getFilteredBills(billProvider.bills);
        final billsToDelete = filteredBills
            .where((bill) => _selectedBills.contains(bill.id))
            .toList();

        for (final bill in billsToDelete) {
          await billProvider.deleteBill(bill.id);
        }

        if (mounted) {
          setState(() {
            _isSelectionMode = false;
            _selectedBills.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${billsToDelete.length} bill${billsToDelete.length == 1 ? '' : 's'} deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete bills: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
