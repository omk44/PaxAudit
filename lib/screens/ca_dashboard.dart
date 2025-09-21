import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../providers/bank_statement_provider.dart';
import '../providers/notification_provider.dart';

import 'management_screens.dart';
import 'notification_screen.dart';

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
      // Load all necessary data for the dashboard (provider will handle clearing if needed)
      await Future.wait([
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).loadExpensesForCompany(companyId),
        Provider.of<IncomeProvider>(
          context,
          listen: false,
        ).loadIncomesForCompany(companyId),
        Provider.of<CategoryProvider>(
          context,
          listen: false,
        ).loadCategoriesForCompany(companyId),
        Provider.of<BankStatementProvider>(
          context,
          listen: false,
        ).loadBankStatementsForCompany(companyId),
      ]);

      // Load notifications for the current CA
      final caEmail = auth.user?.email;
      if (caEmail != null) {
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).loadNotificationsForCA(caEmail);
      }


      _lastLoadedCompanyId = companyId;
    }
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CA Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.hasUnreadNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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

      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.selectedCompany == null) {
            return const Center(child: Text('No company selected'));
          }

          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_rounded, color: Colors.blue),
                title: const Text('CA Details'),
                subtitle: const Text('View your profile and linked company'),
                onTap: () => Navigator.pushNamed(context, '/ca_details'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.teal,
                ),
                title: const Text('Income/Expense Viewer'),
                subtitle: const Text('Overview with filters and summaries'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncomeExpenseManagerScreen(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.green,
                ),
                title: const Text('Income Management'),
                subtitle: const Text('Add and edit incomes'),
                onTap: () => Navigator.pushNamed(context, '/income_management'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.trending_down_rounded,
                  color: Colors.red,
                ),
                title: const Text('Expense Management'),
                subtitle: const Text('Add and edit expenses with GST'),
                onTap: () =>
                    Navigator.pushNamed(context, '/expense_management'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.indigo,
                ),
                title: const Text('Tax Summary'),
                subtitle: const Text('GST summary and totals'),
                onTap: () => Navigator.pushNamed(context, '/tax_summary'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.brown,
                ),
                title: const Text('Bank Statements'),
                subtitle: const Text('View uploaded bank statements'),
                onTap: () => Navigator.pushNamed(context, '/bank_statements'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.bug_report_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Test Notification'),
                subtitle: const Text(
                  'Create a test notification to verify system',
                ),
                onTap: () async {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final notificationProvider =
                      Provider.of<NotificationProvider>(context, listen: false);
                  final caEmail = auth.user?.email;
                  if (caEmail != null) {
                    await notificationProvider.createTestNotification(caEmail);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification created!'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },

            ],
          );
        },
      ),
    );
  }
}
