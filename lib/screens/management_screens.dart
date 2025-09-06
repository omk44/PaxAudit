// screens/management_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ca_provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../models/category.dart';
import '../widgets/tax_summary_widget.dart';
import '../widgets/dialogs/ca_dialogs.dart';
import '../widgets/dialogs/category_dialogs.dart';
import '../widgets/dialogs/income_dialogs.dart';
import '../widgets/dialogs/expense_dialogs.dart';

// --- CA Management Screen (Admin only) ---
class CAManagementScreen extends StatelessWidget {
  const CAManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caProvider = Provider.of<CAProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('CA Management')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: caProvider.cas.length,
              itemBuilder: (context, index) {
                final ca = caProvider.cas[index];
                return ListTile(
                  title: Text(ca.username),
                  subtitle: Text('ID: ${ca.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CAEditDialog(ca: ca),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          caProvider.deleteCA(ca.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add CA'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CAAddDialog(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Category Management Screen ---
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Category Management')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categoryProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = categoryProvider.categories[index];
                return ListTile(
                  title: Text(cat.name),
                  subtitle: Text('ID: ${cat.id}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Note: This would need a deleteCategory method in CategoryProvider
                      // For now, we'll just remove from the list
                      categoryProvider.categories.removeAt(index);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CategoryAddDialog(editedBy: 'admin'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Income Management Screen ---
class IncomeManagementScreen extends StatelessWidget {
  const IncomeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = incomeProvider.incomes.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Income Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => IncomeAddDialog(addedBy: auth.role ?? 'admin'),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: incomeProvider.incomes.length,
                    itemBuilder: (context, index) {
                      final inc = incomeProvider.incomes[index];
                      return ListTile(
                        title: Text(
                          'Amount: ₹${inc.amount.toStringAsFixed(2)}',
                        ),
                        subtitle: Text(
                          'Date: ${dt.format(inc.date.toLocal())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    IncomeHistoryDialog(income: inc),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => IncomeEditDialog(
                                  income: inc,
                                  editedBy: auth.role ?? 'admin',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  incomeProvider.deleteIncome(inc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 72),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No incomes yet.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          IncomeAddDialog(addedBy: auth.role ?? 'admin'),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- Expense Management Screen ---
class ExpenseManagementScreen extends StatelessWidget {
  const ExpenseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = expenseProvider.expenses.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => ExpenseAddDialog(addedBy: auth.role ?? 'admin'),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                    itemBuilder: (context, index) {
                      final exp = expenseProvider.expenses[index];
                      final catName = categoryProvider.categories
                          .firstWhere(
                            (c) => c.id == exp.categoryId,
                            orElse: () => Category(
                              id: '',
                              name: 'Deleted',
                              lastEditedBy: '',
                              lastEditedAt: DateTime.now(),
                              history: [],
                            ),
                          )
                          .name;
                      return ListTile(
                        title: Text(
                          'Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.totalGst.toStringAsFixed(2)}',
                        ),
                        subtitle: Text(
                          'Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.bankAccount}\nDate: ${dt.format(exp.date.toLocal())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExpenseHistoryDialog(
                                  expense: exp,
                                  categoryProvider: categoryProvider,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExpenseEditDialog(
                                  expense: exp,
                                  editedBy: auth.role ?? 'admin',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  expenseProvider.deleteExpense(exp.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 72),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No expenses yet.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          ExpenseAddDialog(addedBy: auth.role ?? 'admin'),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- Income/Expense Manager Page ---
class IncomeExpenseManagerScreen extends StatefulWidget {
  const IncomeExpenseManagerScreen({super.key});

  @override
  State<IncomeExpenseManagerScreen> createState() =>
      _IncomeExpenseManagerScreenState();
}

class _IncomeExpenseManagerScreenState
    extends State<IncomeExpenseManagerScreen> {
  final DateFormat _dt = DateFormat('yyyy-MM-dd HH:mm');
  DateTime? _startDate;
  DateTime? _endDate;
  bool _newestFirst = true;
  bool _showIncomes = true;
  bool _showExpenses = true;
  String _bankFilter = 'All';

  String _formatDate(DateTime d) => _dt.format(d.toLocal());

  bool _inRange(DateTime d) {
    if (_startDate != null &&
        d.isBefore(
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
        )) {
      return false;
    }
    if (_endDate != null &&
        d.isAfter(
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59),
        )) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final allIncomes =
        incomeProvider.incomes.where((i) => _inRange(i.date)).toList()..sort(
          (a, b) => _newestFirst
              ? b.date.compareTo(a.date)
              : a.date.compareTo(b.date),
        );

    final allExpenses =
        expenseProvider.expenses.where((e) => _inRange(e.date)).toList()..sort(
          (a, b) => _newestFirst
              ? b.date.compareTo(a.date)
              : a.date.compareTo(b.date),
        );

    final bankAccounts = <String>{
      'All',
      ...allExpenses.map((e) => e.bankAccount),
    }.toList()..sort();

    final incomes = allIncomes; // no bank filter for incomes
    final expenses = allExpenses
        .where((e) => _bankFilter == 'All' || e.bankAccount == _bankFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Income/Expense Viewer')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate == null
                          ? 'Start date'
                          : 'Start: ${_formatDate(_startDate!)}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _endDate == null
                          ? 'End date'
                          : 'End: ${_formatDate(_endDate!)}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear dates'),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Newest first'),
                      Switch(
                        value: _newestFirst,
                        onChanged: (v) => setState(() => _newestFirst = v),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    isSelected: [_showIncomes, _showExpenses],
                    onPressed: (index) {
                      setState(() {
                        if (index == 0) {
                          _showIncomes = !_showIncomes;
                        } else {
                          _showExpenses = !_showExpenses;
                        }
                        if (!_showIncomes && !_showExpenses) {
                          _showIncomes = true;
                        }
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Incomes'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Expenses'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _bankFilter,
                    items: bankAccounts
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text('Bank: $b'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _bankFilter = val ?? 'All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_showIncomes) ...[
                const Text(
                  'Incomes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...incomes.map(
                  (inc) => ListTile(
                    title: Text('Amount: ₹${inc.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Date: ${_formatDate(inc.date)}'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => IncomeHistoryDialog(income: inc),
                    ),
                  ),
                ),
                const Divider(),
              ],
              if (_showExpenses) ...[
                const Text(
                  'Expenses',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...expenses.map((exp) {
                  final catName = categoryProvider.categories
                      .firstWhere(
                        (c) => c.id == exp.categoryId,
                        orElse: () => Category(
                          id: '',
                          name: 'Deleted',
                          lastEditedBy: '',
                          lastEditedAt: DateTime.now(),
                          history: [],
                        ),
                      )
                      .name;
                  return ListTile(
                    title: Text(
                      'Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.totalGst.toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      'Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.bankAccount}\nDate: ${_formatDate(exp.date)}',
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ExpenseHistoryDialog(
                        expense: exp,
                        categoryProvider: categoryProvider,
                      ),
                    ),
                  );
                }),
                const Divider(),
              ],
              const TaxSummaryWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
