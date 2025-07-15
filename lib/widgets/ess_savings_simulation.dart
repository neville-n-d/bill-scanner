import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/electricity_bill.dart';

class EssSavingsSimulation extends StatefulWidget {
  final List<ElectricityBill> bills;
  const EssSavingsSimulation({Key? key, required this.bills}) : super(key: key);

  @override
  State<EssSavingsSimulation> createState() => _EssSavingsSimulationState();
}

class _EssSavingsSimulationState extends State<EssSavingsSimulation> with SingleTickerProviderStateMixin {
  bool _showResult = false;
  late List<_EssSimData> _simData;
  double _totalSaved = 0;
  bool _showTotal = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _simulate() {
    if (widget.bills.isEmpty) return;
    _simData = _prepareSimData(widget.bills);
    _totalSaved = _simData.fold(0.0, (sum, d) => sum + (d.actualCost - d.essCost));
    setState(() {
      _showResult = true;
      _showTotal = false;
    });
    _controller.reset();
    _controller.duration = Duration(milliseconds: 1000 * _simData.length);
    _controller.forward().whenComplete(() {
      setState(() {
        _showTotal = true;
      });
    });
  }

  List<_EssSimData> _prepareSimData(List<ElectricityBill> bills) {
    final Map<String, List<ElectricityBill>> billsByMonth = {};
    for (final bill in bills) {
      final key = '${bill.billDate.year}-${bill.billDate.month.toString().padLeft(2, '0')}';
      billsByMonth.putIfAbsent(key, () => []).add(bill);
    }
    final sortedMonths = billsByMonth.keys.toList()..sort();
    final List<_EssSimData> data = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final bills = billsByMonth[month]!;
      final totalCost = bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
      final reducedCost = totalCost * 0.7; // 30% savings
      final date = DateTime.parse('$month-01');
      data.add(_EssSimData(
        index: i,
        label: DateFormat('MMM yy').format(date),
        actualCost: totalCost,
        essCost: reducedCost,
      ));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.orange[700], size: 28),
                const SizedBox(width: 8),
                const Text(
                  'TeraHive ESS Simulation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'See how much you could save by installing a TeraHive ESS system! This simulation shows a 30% reduction in your electricity bill.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            if (!_showResult)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: const Text('Simulate Savings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _simulate,
                ),
              )
            else
              _buildResult(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => _buildSimChart(_controller.value),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Current Bill', Colors.orange),
            const SizedBox(width: 24),
            _buildLegendItem('With ESS', Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        if (_showTotal)
          Column(
            children: [
              Text(
                'You could save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green[800]),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_totalSaved.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text(
                'over the analyzed period with TeraHive ESS!',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        Icon(Icons.celebration, color: Colors.green, size: 36),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _controller.reset();
            setState(() {
              _showResult = false;
              _showTotal = false;
            });
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSimChart(double animValue) {
    final n = _simData.length;
    final totalProgress = animValue * (n - 1);
    final currentIndex = totalProgress.floor();
    final segmentProgress = totalProgress - currentIndex;
    List<FlSpot> essCostSpots = [];
    // Add all previous points
    for (int i = 0; i <= currentIndex && i < n; i++) {
      essCostSpots.add(FlSpot(_simData[i].index.toDouble(), _simData[i].essCost));
    }
    // Interpolate the next point if not at the end
    if (currentIndex < n - 1) {
      final prev = _simData[currentIndex];
      final next = _simData[currentIndex + 1];
      final interpY = prev.essCost + (next.essCost - prev.essCost) * segmentProgress;
      final interpX = prev.index + (next.index - prev.index) * segmentProgress;
      essCostSpots.add(FlSpot(interpX.toDouble(), interpY));
    }
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
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
                  if (value.toInt() >= 0 && value.toInt() < _simData.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _simData[value.toInt()].label,
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
                interval: _getDynamicInterval(),
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value % _getDynamicInterval() == 0) {
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
          maxX: (_simData.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxY(),
          lineBarsData: [
            // Actual Cost
            LineChartBarData(
              spots: _simData.map((d) => FlSpot(d.index.toDouble(), d.actualCost)).toList(),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            // ESS Cost (smoothly animated left-to-right)
            LineChartBarData(
              spots: essCostSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) {
                  // Only show dots for fully revealed points (not the interpolated one)
                  return spot.x <= currentIndex;
                },
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
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
                    label = 'Actual Cost: \$${flSpot.y.toStringAsFixed(2)}';
                  } else {
                    label = 'ESS Cost: \$${flSpot.y.toStringAsFixed(2)}';
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

  double _getMaxY() {
    double maxY = 0;
    for (final d in _simData) {
      maxY = [maxY, d.actualCost, d.essCost].reduce(max);
    }
    return maxY * 1.2;
  }

  double _getDynamicInterval() {
    final maxY = _getMaxY();
    double interval = (maxY / 5).ceilToDouble();
    // Round up to the next multiple of 500
    if (interval < 500) interval = 500;
    else interval = ((interval / 500).ceil()) * 500;
    return interval;
  }
}

class _EssSimData {
  final int index;
  final String label;
  final double actualCost;
  final double essCost;
  _EssSimData({
    required this.index,
    required this.label,
    required this.actualCost,
    required this.essCost,
  });
}
