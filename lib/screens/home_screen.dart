import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'camera_screen.dart';
import '../screens/bill_detail_screen.dart';
import '../providers/bill_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/bill_card.dart';
import '../widgets/energy_tips_card.dart';
import '../utils/config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Bill Analyzer'),
        actions: [
          // Debug button to reload sample data
          if (AppConfig.enableDebugLogs)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await context.read<BillProvider>().forceReloadSampleData();
              },
              tooltip: 'Reload Sample Data',
            ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
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

          return RefreshIndicator(
            onRefresh: () async {
              await billProvider.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context, billProvider),
                  const SizedBox(height: 24),
                  _buildQuickStats(context, billProvider),
                  const SizedBox(height: 24),
                  _buildRecentBills(context, billProvider),
                  const SizedBox(height: 24),
                  _buildEnergyTips(context, billProvider),
                  // Debug info section
                  if (AppConfig.enableDebugLogs) ...[
                    const SizedBox(height: 24),
                    _buildDebugInfo(context, billProvider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, BillProvider billProvider) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to analyze your electricity bills and save money?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (billProvider.bills.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to camera screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Your First Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, BillProvider billProvider) {
    final stats = billProvider.statistics;
    
    if (stats == null || stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Bills',
                value: '${stats['totalBills'] ?? 0}',
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Avg. Consumption',
                value: '${(stats['avgConsumption'] ?? 0).toStringAsFixed(1)} kWh',
                icon: Icons.electric_bolt,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Avg. Amount',
                value: '\$${(stats['avgAmount'] ?? 0).toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Spent',
                value: '\$${(stats['totalSpent'] ?? 0).toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentBills(BuildContext context, BillProvider billProvider) {
    final recentBills = billProvider.bills.take(3).toList();
    
    if (recentBills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bills',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to history screen
                Navigator.pushNamed(context, '/history');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recentBills.map((bill) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BillCard(bill: bill, onTap: () {
            Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillDetailScreen(bill: bill),
                        ),
                      );
          },),
        )),
      ],
    );
  }

  Widget _buildEnergyTips(BuildContext context, BillProvider billProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy Saving Tips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        EnergyTipsCard(),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildDebugInfo(BuildContext context, BillProvider billProvider) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Debug Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Platform: ${kIsWeb ? 'Web' : 'Mobile'}'),
            Text('Storage: ${kIsWeb ? 'SharedPreferences' : 'SQLite'}'),
            Text('Total Bills: ${billProvider.bills.length}'),
            Text('Sample Data Enabled: ${AppConfig.enableSampleData}'),
            Text('Loading: ${billProvider.isLoading}'),
            if (billProvider.error != null)
              Text('Error: ${billProvider.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await billProvider.forceReloadSampleData();
              },
              child: const Text('Force Reload Sample Data'),
            ),
          ],
        ),
      ),
    );
  }
} 