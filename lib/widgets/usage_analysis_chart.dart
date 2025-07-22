import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/electricity_bill.dart';

class UsageAnalysisChart extends StatefulWidget {
  final List<ElectricityBill> bills;

  const UsageAnalysisChart({Key? key, required this.bills}) : super(key: key);

  @override
  State<UsageAnalysisChart> createState() => _UsageAnalysisChartState();
}

class _UsageAnalysisChartState extends State<UsageAnalysisChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.bills.isEmpty) {
      return _buildEmptyState();
    }

    final chartData = _prepareChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(),
        const SizedBox(height: 16),
        _buildChart(chartData),
        const SizedBox(height: 16),
        _buildInsights(chartData),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Add bills to see usage analysis',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Monthly Trends',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _buildLegendItem('Consumption', Colors.blue),
            const SizedBox(width: 16),
            _buildLegendItem('Cost', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildChart(Map<String, dynamic> chartData) {
    double maxY = _getMaxY(chartData);
    double interval = (maxY / 5).ceilToDouble();
    // Round up to the next multiple of 500
    if (interval < 250)
      interval = 250;
    else
      interval = ((interval / 250).ceil()) * 250;
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < chartData['labels']!.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        chartData['labels']![value.toInt()],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value % interval == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minX: 0,
          maxX: (chartData['consumption']!.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxY(chartData),
          lineBarsData: [
            // Consumption line
            LineChartBarData(
              spots: chartData['consumption']!,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.blue.withOpacity(0.3),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            // Cost line
            LineChartBarData(
              spots: chartData['cost']!,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.8),
                  Colors.orange.withOpacity(0.3),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  String label = '';
                  if (flSpot.barIndex == 0) {
                    label = 'Consumption: ${flSpot.y.toStringAsFixed(1)} kWh';
                  } else {
                    label = 'Cost: \$${flSpot.y.toStringAsFixed(2)}';
                  }
                  return LineTooltipItem(
                    label,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  Widget _buildInsights(Map<String, dynamic> chartData) {
    final insights = _generateInsights(chartData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  insight['type'] == 'positive'
                      ? Icons.trending_up
                      : insight['type'] == 'negative'
                      ? Icons.trending_down
                      : Icons.info_outline,
                  color: insight['type'] == 'positive'
                      ? Colors.green
                      : insight['type'] == 'negative'
                      ? Colors.red
                      : Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight['message'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _prepareChartData() {
    // Group bills by month
    final Map<String, List<ElectricityBill>> billsByMonth = {};
    for (final bill in widget.bills) {
      final key =
          '${bill.billDate.year}-${bill.billDate.month.toString().padLeft(2, '0')}';
      billsByMonth.putIfAbsent(key, () => []).add(bill);
    }

    // Sort months
    final sortedMonths = billsByMonth.keys.toList()..sort();

    // Prepare data for chart
    final List<FlSpot> consumptionSpots = [];
    final List<FlSpot> costSpots = [];
    final List<String> labels = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final bills = billsByMonth[month]!;

      final totalConsumption = bills.fold(
        0.0,
        (sum, bill) => sum + bill.consumptionKwh,
      );
      final totalCost = bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);

      consumptionSpots.add(FlSpot(i.toDouble(), totalConsumption));
      costSpots.add(FlSpot(i.toDouble(), totalCost));

      // Format label as MM/yy (e.g., 01/25)
      final date = DateTime.parse('$month-01');
      labels.add(DateFormat('MM/yy').format(date));
    }

    return {
      'consumption': consumptionSpots,
      'cost': costSpots,
      'labels': labels,
    };
  }

  double _getMaxY(Map<String, dynamic> chartData) {
    double maxConsumption = 0;
    double maxCost = 0;

    for (final spot in chartData['consumption']!) {
      if (spot.y > maxConsumption) maxConsumption = spot.y;
    }
    for (final spot in chartData['cost']!) {
      if (spot.y > maxCost) maxCost = spot.y;
    }

    // Return the larger value with some padding
    return (maxConsumption > maxCost ? maxConsumption : maxCost) * 1.2;
  }

  List<Map<String, dynamic>> _generateInsights(Map<String, dynamic> chartData) {
    final insights = <Map<String, dynamic>>[];

    if (chartData['consumption']!.length < 2) {
      insights.add({
        'message': 'Add more bills to see usage trends and insights',
        'type': 'neutral',
      });
      return insights;
    }

    // Calculate trends
    final consumptionSpots = chartData['consumption']!;
    final costSpots = chartData['cost']!;

    // Consumption trend
    final firstConsumption = consumptionSpots.first.y;
    final lastConsumption = consumptionSpots.last.y;
    final consumptionChange =
        ((lastConsumption - firstConsumption) / firstConsumption) * 100;

    if (consumptionChange > 10) {
      insights.add({
        'message':
            'Consumption increased by ${consumptionChange.toStringAsFixed(1)}% over the period',
        'type': 'negative',
      });
    } else if (consumptionChange < -10) {
      insights.add({
        'message':
            'Great! Consumption decreased by ${(-consumptionChange).toStringAsFixed(1)}% over the period',
        'type': 'positive',
      });
    } else {
      insights.add({
        'message':
            'Consumption is relatively stable (${consumptionChange.toStringAsFixed(1)}% change)',
        'type': 'neutral',
      });
    }

    // Cost trend
    final firstCost = costSpots.first.y;
    final lastCost = costSpots.last.y;
    final costChange = ((lastCost - firstCost) / firstCost) * 100;

    if (costChange > 10) {
      insights.add({
        'message':
            'Cost increased by ${costChange.toStringAsFixed(1)}% over the period',
        'type': 'negative',
      });
    } else if (costChange < -10) {
      insights.add({
        'message':
            'Excellent! Cost decreased by ${(-costChange).toStringAsFixed(1)}% over the period',
        'type': 'positive',
      });
    } else {
      insights.add({
        'message':
            'Cost is relatively stable (${costChange.toStringAsFixed(1)}% change)',
        'type': 'neutral',
      });
    }

    // Average consumption
    final avgConsumption =
        consumptionSpots.fold(0.0, (sum, spot) => sum + spot.y) /
        consumptionSpots.length;
    insights.add({
      'message':
          'Average monthly consumption: ${avgConsumption.toStringAsFixed(1)} kWh',
      'type': 'neutral',
    });

    // Peak month
    final peakIndex = consumptionSpots.indexWhere(
      (spot) =>
          spot.y ==
          consumptionSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b),
    );
    if (peakIndex != -1) {
      final peakMonth = chartData['labels']![peakIndex];
      insights.add({
        'message': 'Peak consumption was in $peakMonth',
        'type': 'neutral',
      });
    }

    return insights;
  }
}
