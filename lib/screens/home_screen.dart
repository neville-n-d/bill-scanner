import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/bill_card.dart';
// import '../widgets/energy_tips_card.dart'; // Remove energy tips
import '../utils/config.dart';
import '../screens/settings_screen.dart'; // Added import for SettingsScreen
import '../widgets/usage_analysis_chart.dart';
import '../widgets/ess_savings_simulation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bill Analyzer',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await context.read<BillProvider>().refreshBillsFromBackend();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, child) {
          if (billProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context, billProvider),
                const SizedBox(height: 24),
                _buildQuickStats(context, billProvider),
                const SizedBox(height: 24),
                _buildAnalyzeGraph(context, billProvider),
                if (AppConfig.enableDebugLogs) ...[
                  const SizedBox(height: 24),
                  _buildDebugInfo(context, billProvider),
                ],
              ],
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (billProvider.bills.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/camera');
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                value:
                    '${(stats['averageMonthlyConsumption'] ?? 0).toStringAsFixed(1)} kWh',
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
                value:
                    '\$${(stats['averageMonthlyCost'] ?? 0).toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Spent',
                value: '\$${(stats['totalAmount'] ?? 0).toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyzeGraph(BuildContext context, BillProvider billProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        UsageAnalysisChart(bills: billProvider.bills),
        EssSavingsSimulation(bills: billProvider.bills),
      ],
    );
  }

  Widget _buildDebugInfo(BuildContext context, BillProvider billProvider) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Debug Info:\nBills: ${billProvider.bills.length}\nError: ${billProvider.error ?? "None"}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
