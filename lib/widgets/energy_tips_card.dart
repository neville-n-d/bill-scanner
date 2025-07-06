import 'package:flutter/material.dart';

class EnergyTipsCard extends StatelessWidget {
  const EnergyTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Energy Saving Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              icon: Icons.lightbulb_outline,
              title: 'Switch to LED Bulbs',
              description: 'LED bulbs use up to 90% less energy than traditional incandescent bulbs.',
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              icon: Icons.thermostat,
              title: 'Optimize Your Thermostat',
              description: 'Set your thermostat to 78°F in summer and 68°F in winter for optimal efficiency.',
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              icon: Icons.power,
              title: 'Unplug Unused Devices',
              description: 'Many devices consume power even when turned off. Unplug them when not in use.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to detailed tips screen
                },
                icon: const Icon(Icons.trending_up),
                label: const Text('Get Personalized Tips'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.orange,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 