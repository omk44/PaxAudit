import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/ca_provider.dart';
import '../providers/category_provider.dart';
import '../models/company.dart';

class AdminDetailsScreen extends StatefulWidget {
  const AdminDetailsScreen({super.key});

  @override
  State<AdminDetailsScreen> createState() => _AdminDetailsScreenState();
}

class _AdminDetailsScreenState extends State<AdminDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final company = auth.selectedCompany;

    if (company != null) {
      // Clear existing data first to prevent cross-company data leakage
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).clearExpensesForCompanySwitch();
      Provider.of<IncomeProvider>(
        context,
        listen: false,
      ).clearIncomesForCompanySwitch();

      // Load expenses and income for the company
      await Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).loadExpensesForCompany(company.id);
      await Provider.of<IncomeProvider>(
        context,
        listen: false,
      ).loadIncomesForCompany(company.id);
      await Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).loadCategoriesForCompany(company.id);
      await Provider.of<CAProvider>(
        context,
        listen: false,
      ).loadCAsForCompany(company.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final company = auth.selectedCompany;
        if (company == null) {
          return const Scaffold(
            body: Center(child: Text('No company selected')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${company.name} - Admin Dashboard'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyInfoCard(company),
                  const SizedBox(height: 20),
                  _buildStatisticsCards(),
                  const SizedBox(height: 20),
                  _buildCAsSection(),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyInfoCard(Company company) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admin: ${company.adminName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (company.description != null) ...[
              _buildInfoRow(
                Icons.description,
                'Description',
                company.description!,
              ),
              const SizedBox(height: 12),
            ],
            if (company.address != null) ...[
              _buildInfoRow(Icons.location_on, 'Address', company.address!),
              const SizedBox(height: 12),
            ],
            if (company.phoneNumber != null) ...[
              _buildInfoRow(Icons.phone, 'Phone', company.phoneNumber!),
              const SizedBox(height: 12),
            ],
            if (company.website != null) ...[
              _buildInfoRow(Icons.web, 'Website', company.website!),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              Icons.calendar_today,
              'Created',
              '${company.createdAt.day}/${company.createdAt.month}/${company.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer2<ExpenseProvider, IncomeProvider>(
      builder: (context, expenseProvider, incomeProvider, child) {
        final totalExpenses = expenseProvider.expenses.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        );
        final totalIncome = incomeProvider.incomes.fold(
          0.0,
          (sum, income) => sum + income.amount,
        );
        final netProfit = totalIncome - totalExpenses;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Income',
                '₹${totalIncome.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Expenses',
                '₹${totalExpenses.toStringAsFixed(2)}',
                Icons.trending_down,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Net Profit',
                '₹${netProfit.toStringAsFixed(2)}',
                netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                netProfit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCAsSection() {
    return Consumer<CAProvider>(
      builder: (context, caProvider, child) {
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Chartered Accountants (${caProvider.cas.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (caProvider.cas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No CAs added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...caProvider.cas.map(
                    (ca) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              ca.name.isNotEmpty
                                  ? ca.name[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ca.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ca.email,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ca.licenseNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Licensed',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return Consumer2<ExpenseProvider, IncomeProvider>(
      builder: (context, expenseProvider, incomeProvider, child) {
        final allTransactions = <Map<String, dynamic>>[];

        // Add expenses
        for (var expense in expenseProvider.expenses.take(5)) {
          allTransactions.add({
            'type': 'expense',
            'amount': expense.amount,
            'description': expense.description,
            'date': expense.date,
            'category': expense.categoryName,
          });
        }

        // Add incomes
        for (var income in incomeProvider.incomes.take(5)) {
          allTransactions.add({
            'type': 'income',
            'amount': income.amount,
            'description': income.description,
            'date': income.date,
            'category': income.category,
          });
        }

        // Sort by date (most recent first)
        allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...allTransactions
                      .take(10)
                      .map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: transaction['type'] == 'income'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  transaction['type'] == 'income'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: transaction['type'] == 'income'
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction['description'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      transaction['category'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${transaction['amount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: transaction['type'] == 'income'
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${transaction['date'].day}/${transaction['date'].month}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
