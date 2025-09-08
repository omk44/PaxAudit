import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'management_screens.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: const Text('Company Details'),
            subtitle: const Text('View company information and statistics'),
            onTap: () => Navigator.pushNamed(context, '/admin_details'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: Colors.green),
            title: const Text('CA Management'),
            subtitle: const Text('Manage Chartered Accountants'),
            onTap: () => Navigator.pushNamed(context, '/ca_management'),
          ),
          ListTile(
            leading: const Icon(Icons.category_rounded, color: Colors.deepPurple),
            title: const Text('Category Management'),
            subtitle: const Text('Manage expense categories and GST %'),
            onTap: () => Navigator.pushNamed(context, '/category_management'),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart_rounded, color: Colors.teal),
            title: const Text('Income/Expense Viewer'),
            subtitle: const Text('Overview with filters and summaries'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeExpenseManagerScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up_rounded, color: Colors.green),
            title: const Text('Income Management'),
            onTap: () => Navigator.pushNamed(context, '/income_management'),
          ),
          ListTile(
            leading: const Icon(Icons.trending_down_rounded, color: Colors.red),
            title: const Text('Expense Management'),
            onTap: () => Navigator.pushNamed(context, '/expense_management'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: Colors.indigo),
            title: const Text('Tax Summary'),
            onTap: () => Navigator.pushNamed(context, '/tax_summary'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_rounded, color: Colors.brown),
            title: const Text('Bank Statements'),
            onTap: () => Navigator.pushNamed(context, '/bank_statements'),
          ),
        ],
      ),
    );
  }
}