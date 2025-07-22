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
import '../providers/auth_provider.dart';

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
    final hasTerahiveEss =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).user?.hasTerahiveEss ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        UsageAnalysisChart(bills: billProvider.bills),
        _buildGenerateSuggestionsSection(context, billProvider),
        const SizedBox(height: 24),
        EssSavingsSimulation(
          bills: billProvider.bills,
          hasTerahiveEss: hasTerahiveEss,
        ),
      ],
    );
  }

  Widget _buildGenerateSuggestionsSection(
    BuildContext context,
    BillProvider billProvider,
  ) {
    final canGenerate =
        billProvider.bills.length >= 3 &&
        !billProvider.isGeneratingSuggestions &&
        (billProvider.suggestions == null ||
            (billProvider.lastSuggestionGenerated != null &&
                billProvider.lastSuggestionGenerated!.isBefore(
                  billProvider.bills.first.createdAt,
                )));

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Suggestions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized tips to save more money based on your 3 most recent bills.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (billProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  billProvider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (billProvider.isGeneratingSuggestions)
              const Center(child: CircularProgressIndicator()),
            if (!billProvider.isGeneratingSuggestions &&
                (billProvider.suggestions == null || canGenerate))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canGenerate
                      ? () async {
                          await billProvider.generatePersonalizedSuggestions();
                        }
                      : null,
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Generate Suggestions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (billProvider.suggestions != null &&
                !billProvider.isGeneratingSuggestions)
              _buildSuggestionsResult(context, billProvider.suggestions!),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsResult(
    BuildContext context,
    Map<String, dynamic> suggestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Summary:',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(suggestions['summary'] ?? ''),
        const SizedBox(height: 12),
        if (suggestions['immediateActions'] != null)
          _buildSuggestionList(
            'Immediate Actions',
            suggestions['immediateActions'],
          ),
        if (suggestions['mediumTerm'] != null)
          _buildSuggestionList('Medium Term', suggestions['mediumTerm']),
        if (suggestions['longTerm'] != null)
          _buildSuggestionList('Long Term', suggestions['longTerm']),
        if (suggestions['potentialSavings'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Potential Savings: ${suggestions['potentialSavings']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        if (suggestions['terahiveRecommendations'] != null)
          _buildSuggestionList(
            'TeraHive Recommendations',
            suggestions['terahiveRecommendations'],
          ),
      ],
    );
  }

  Widget _buildSuggestionList(String title, dynamic items) {
    if (items is! List) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...items.map<Widget>(
            (item) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(item.toString())),
              ],
            ),
          ),
        ],
      ),
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
