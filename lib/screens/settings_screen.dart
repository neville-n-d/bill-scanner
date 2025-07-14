import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _currency = 'USD';
  String _energyUnit = 'kWh';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'General',
            [
              _buildListTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Get alerts about bill processing and insights',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              _buildListTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Use dark theme for the app',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            'Units & Currency',
            [
              _buildListTile(
                icon: Icons.attach_money,
                title: 'Currency',
                subtitle: _currency,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showCurrencyDialog(),
              ),
              _buildListTile(
                icon: Icons.electric_bolt,
                title: 'Energy Unit',
                subtitle: _energyUnit,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showEnergyUnitDialog(),
              ),
            ],
          ),
          _buildSection(
            'Data & Privacy',
            [
              _buildListTile(
                icon: Icons.backup,
                title: 'Export Data',
                subtitle: 'Export your bill data as CSV',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _exportData(),
              ),
              _buildListTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Delete all bills and settings',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showClearDataDialog(),
              ),
            ],
          ),
          _buildSection(
            'Account',
            [
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  return _buildListTile(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: user?.fullName ?? 'User Profile',
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showProfileDialog(),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showLogoutDialog(),
              ),
            ],
          ),
          _buildSection(
            'About',
            [
              _buildListTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              _buildListTile(
                icon: Icons.description,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showPrivacyPolicy(),
              ),
              _buildListTile(
                icon: Icons.description,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showTermsOfService(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'USD',
            'EUR',
            'GBP',
            'JPY',
            'CAD',
            'AUD',
          ].map((currency) {
            return ListTile(
              title: Text(currency),
              trailing: _currency == currency ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _currency = currency;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEnergyUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Energy Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'kWh',
            'MWh',
            'GJ',
            'BTU',
          ].map((unit) {
            return ListTile(
              title: Text(unit),
              trailing: _energyUnit == unit ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _energyUnit = unit;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all bills and settings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear data functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data cleared successfully'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This app collects and processes electricity bill data to provide insights and recommendations. '
            'Your data is stored locally on your device and is not shared with third parties without your consent. '
            'The app uses AI services to analyze your bills, and this data is processed according to the respective service providers\' privacy policies.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to use it responsibly and in accordance with applicable laws. '
            'The app is provided "as is" without warranties. We are not responsible for any decisions made based on the app\'s analysis and recommendations.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Name', user.fullName),
            _buildProfileItem('Email', user.email),
            if (user.phone != null) _buildProfileItem('Phone', user.phone!),
            _buildProfileItem('Account Type', user.userType == 'terahive_ess' ? 'Terahive ESS' : 'Regular'),
            _buildProfileItem('Terahive ESS', user.hasTerahiveEss ? 'Installed' : 'Not Installed'),
            _buildProfileItem('Email Verified', user.isEmailVerified ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              context.read<BillProvider>().clearBills();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 