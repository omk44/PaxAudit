import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import 'management_screens.dart';

class CADashboard extends StatefulWidget {
  const CADashboard({super.key});

  @override
  State<CADashboard> createState() => _CADashboardState();
}

class _CADashboardState extends State<CADashboard> {
  String? _lastLoadedCompanyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data if company changes
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentCompanyId = auth.companyId ?? auth.selectedCompany?.id;
    
    if (currentCompanyId != null && currentCompanyId != _lastLoadedCompanyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final companyId = auth.companyId ?? auth.selectedCompany?.id;
    
    if (companyId != null && companyId != _lastLoadedCompanyId) {
      // Load all necessary data for the dashboard
      await Future.wait([
        Provider.of<ExpenseProvider>(context, listen: false)
            .loadExpensesForCompany(companyId),
        Provider.of<IncomeProvider>(context, listen: false)
            .loadIncomesForCompany(companyId),
        Provider.of<CategoryProvider>(context, listen: false)
            .loadCategoriesForCompany(companyId),
      ]);
      
      _lastLoadedCompanyId = companyId;
    }
  }

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
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.selectedCompany == null) {
            return const Center(
              child: Text('No company selected'),
            );
          }
          
          return ListView(
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
          );
        },
      ),
    );
  }
}