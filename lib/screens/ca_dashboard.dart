import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'management_screens.dart';

class CADashboard extends StatelessWidget {
  const CADashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CA Dashboard'),
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
            title: const Text('CA Details'),
            onTap: () => Navigator.pushNamed(context, '/ca_details'),
          ),
          ListTile(
            title: const Text('Income/Expense Viewer'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeExpenseManagerScreen()),
            ),
          ),
          ListTile(
            title: const Text('Income Management'),
            onTap: () => Navigator.pushNamed(context, '/income_management'),
          ),
          ListTile(
            title: const Text('Expense Management'),
            onTap: () => Navigator.pushNamed(context, '/expense_management'),
          ),
          ListTile(
            title: const Text('Tax Summary'),
            onTap: () => Navigator.pushNamed(context, '/tax_summary'),
          ),
          ListTile(
            title: const Text('Bank Statements'),
            onTap: () => Navigator.pushNamed(context, '/bank_statements'),
          ),
        ],
      ),
    );
  }
}