import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/electricity_bill.dart';
import 'package:url_launcher/url_launcher.dart';

class EssSavingsSimulation extends StatefulWidget {
  final List<ElectricityBill> bills;
  final bool hasTerahiveEss;
  const EssSavingsSimulation({
    Key? key,
    required this.bills,
    required this.hasTerahiveEss,
  }) : super(key: key);

  @override
  State<EssSavingsSimulation> createState() => _EssSavingsSimulationState();
}

class _EssSavingsSimulationState extends State<EssSavingsSimulation>
    with SingleTickerProviderStateMixin {
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
    _simData = _prepareSimData(widget.bills, widget.hasTerahiveEss);
    _totalSaved = _simData.fold(
      0.0,
      (sum, d) =>
          sum +
          (widget.hasTerahiveEss
              ? (d.withoutEssCost - d.actualCost)
              : (d.actualCost - d.essCost)),
    );
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

  List<_EssSimData> _prepareSimData(
    List<ElectricityBill> bills,
    bool hasTerahiveEss,
  ) {
    final Map<String, List<ElectricityBill>> billsByMonth = {};
    for (final bill in bills) {
      final key =
          '${bill.billDate.year}-${bill.billDate.month.toString().padLeft(2, '0')}';
      billsByMonth.putIfAbsent(key, () => []).add(bill);
    }
    final sortedMonths = billsByMonth.keys.toList()..sort();
    final List<_EssSimData> data = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final bills = billsByMonth[month]!;
      final totalCost = bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
      final essCost = totalCost * 0.7; // 30% savings
      final withoutEssCost = totalCost / 0.7; // what it would be without ESS
      final date = DateTime.parse('$month-01');
      data.add(
        _EssSimData(
          index: i,
          label: DateFormat('MM/yy').format(date),
          actualCost: totalCost,
          essCost: essCost,
          withoutEssCost: withoutEssCost,
        ),
      );
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
                  'TeraHive Saving Simulation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'See how much you could save by installing a TeraHive system!',
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
            _buildLegendItem(
              widget.hasTerahiveEss ? 'Without TeraHive' : 'Current Bill',
              Colors.orange,
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              widget.hasTerahiveEss ? 'Your Bill' : 'With TeraHive',
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_showTotal)
          Column(
            children: [
              Text(
                widget.hasTerahiveEss ? 'You already saved' : 'You could save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_totalSaved.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.hasTerahiveEss
                    ? 'over the analyzed period with your TeraHive!'
                    : 'over the analyzed period with TeraHive!',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        // Replace the celebration icon with a clickable text for TeraHive
        InkWell(
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Curious about TeraHive? Learn more',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 16,
              ),
            ),
          ),
          onTap: () async {
            final url = Uri.parse('https://www.terahive.io');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    double interval = _getDynamicInterval();
    final n = _simData.length;
    final totalProgress = animValue * (n - 1);
    final currentIndex = totalProgress.floor();
    final segmentProgress = totalProgress - currentIndex;
    List<FlSpot> greenSpots = [];
    List<FlSpot> orangeSpots = [];
    for (int i = 0; i <= currentIndex && i < n; i++) {
      if (widget.hasTerahiveEss) {
        orangeSpots.add(
          FlSpot(_simData[i].index.toDouble(), _simData[i].withoutEssCost),
        );
        greenSpots.add(
          FlSpot(_simData[i].index.toDouble(), _simData[i].actualCost),
        );
      } else {
        orangeSpots.add(
          FlSpot(_simData[i].index.toDouble(), _simData[i].actualCost),
        );
        greenSpots.add(
          FlSpot(_simData[i].index.toDouble(), _simData[i].essCost),
        );
      }
    }
    if (currentIndex < n - 1) {
      final prev = _simData[currentIndex];
      final next = _simData[currentIndex + 1];
      if (widget.hasTerahiveEss) {
        final interpOrangeY =
            prev.withoutEssCost +
            (next.withoutEssCost - prev.withoutEssCost) * segmentProgress;
        final interpGreenY =
            prev.actualCost +
            (next.actualCost - prev.actualCost) * segmentProgress;
        final interpX =
            prev.index + (next.index - prev.index) * segmentProgress;
        orangeSpots.add(FlSpot(interpX.toDouble(), interpOrangeY));
        greenSpots.add(FlSpot(interpX.toDouble(), interpGreenY));
      } else {
        final interpOrangeY =
            prev.actualCost +
            (next.actualCost - prev.actualCost) * segmentProgress;
        final interpGreenY =
            prev.essCost + (next.essCost - prev.essCost) * segmentProgress;
        final interpX =
            prev.index + (next.index - prev.index) * segmentProgress;
        orangeSpots.add(FlSpot(interpX.toDouble(), interpOrangeY));
        greenSpots.add(FlSpot(interpX.toDouble(), interpGreenY));
      }
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
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.grey[300]!, strokeWidth: 1),
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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
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
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          minX: 0,
          maxX: (n - 1).toDouble(),
          minY: 0,
          maxY:
              [...orangeSpots, ...greenSpots].map((e) => e.y).reduce(max) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: orangeSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 4,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: greenSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 4,
              dotData: FlDotData(show: true),
            ),
          ],
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
    if (interval < 250)
      interval = 250;
    else
      interval = ((interval / 250).ceil()) * 250;
    return interval;
  }
}

class _EssSimData {
  final int index;
  final String label;
  final double actualCost;
  final double essCost;
  final double withoutEssCost;
  _EssSimData({
    required this.index,
    required this.label,
    required this.actualCost,
    required this.essCost,
    required this.withoutEssCost,
  });
}
