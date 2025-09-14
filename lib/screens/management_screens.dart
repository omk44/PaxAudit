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
class CAManagementScreen extends StatefulWidget {
  const CAManagementScreen({super.key});

  @override
  State<CAManagementScreen> createState() => _CAManagementScreenState();
}

class _CAManagementScreenState extends State<CAManagementScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ignore: discarded_futures
        _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caProvider = Provider.of<CAProvider>(context, listen: false);
    final companyId = auth.selectedCompany?.id;
    if (companyId != null) {
      await caProvider.loadCAsForCompany(companyId);
    } else {
      // Fallback: show none if no company selected
      await caProvider.loadCAsForCompany('__none__');
    }
  }

  @override
  Widget build(BuildContext context) {
    final caProvider = Provider.of<CAProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('CA Management')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: caProvider.cas.length,
                itemBuilder: (context, index) {
                  final ca = caProvider.cas[index];
                  return ListTile(
                    title: Text(ca.name),
                    subtitle: Text('ID: ${ca.id}  •  Email: ${ca.email}'),
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add CA'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const CAAddDialog(),
                );
                // Reload list after adding
                if (mounted) _refresh();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Category Management Screen ---
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ap = Provider.of<AuthProvider>(context, listen: false);
        final cid = ap.companyId ?? ap.selectedCompany?.id;
        if (cid != null && cid.isNotEmpty) {
          await Provider.of<CategoryProvider>(
            context,
            listen: false,
          ).loadCategoriesForCompany(cid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.category_rounded),
            SizedBox(width: 8),
            Text('Category Management'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Seed Indian GST categories',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () async {
              final ap = Provider.of<AuthProvider>(context, listen: false);
              final cid = ap.companyId ?? ap.selectedCompany?.id;
              if (cid == null || cid.isEmpty) return;
              await Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).seedDefaultIndianCategories(
                companyId: cid,
                editedBy: ap.role ?? 'admin',
              );
              if (mounted) {
                await Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                ).loadCategoriesForCompany(cid);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seeded default Indian GST categories'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categoryProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = categoryProvider.categories[index];
                return ListTile(
                  leading: const Icon(Icons.label_outline_rounded),
                  title: Text(cat.name),
                  subtitle: Text(
                    'GST: ${cat.gstPercentage.toStringAsFixed(2)}%  •  ID: ${cat.id}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      await Provider.of<CategoryProvider>(
                        context,
                        listen: false,
                      ).deleteCategory(cat.id);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_rounded),
              label: const Text('Add Category'),
              onPressed: () {
                final ap = Provider.of<AuthProvider>(context, listen: false);
                final cid = ap.companyId ?? ap.selectedCompany?.id ?? '';
                showDialog(
                  context: context,
                  builder: (_) =>
                      CategoryAddDialog(editedBy: 'admin', companyId: cid),
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
class IncomeManagementScreen extends StatefulWidget {
  const IncomeManagementScreen({super.key});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final companyId = auth.companyId ?? auth.selectedCompany?.id;
        if (companyId != null) {
          // Load data for the company (provider will handle clearing if needed)
          await Provider.of<IncomeProvider>(
            context,
            listen: false,
          ).loadIncomesForCompany(companyId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = incomeProvider.incomes.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.trending_up_rounded),
            SizedBox(width: 8),
            Text('Income Management'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final ap = Provider.of<AuthProvider>(context, listen: false);
          final cid = ap.companyId ?? ap.selectedCompany?.id ?? '';
          showDialog(
            context: context,
            builder: (_) =>
                IncomeAddDialog(addedBy: auth.role ?? 'admin', companyId: cid),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final companyId =
                          auth.companyId ?? auth.selectedCompany?.id;
                      if (companyId != null) {
                        await Provider.of<IncomeProvider>(
                          context,
                          listen: false,
                        ).loadIncomesForCompany(companyId);
                      }
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: incomeProvider.incomes.length,
                      itemBuilder: (context, index) {
                        final inc = incomeProvider.incomes[index];
                        return ListTile(
                          title: Text(
                            'Amount: ₹${inc.amount.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            'Date: ${dt.format(inc.date.toLocal())}\nAdded by: ${inc.addedBy}',
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
                    onPressed: () {
                      final ap = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final cid = ap.companyId ?? ap.selectedCompany?.id ?? '';
                      showDialog(
                        context: context,
                        builder: (_) => IncomeAddDialog(
                          addedBy: auth.role ?? 'admin',
                          companyId: cid,
                        ),
                      );
                    },
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
class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final companyId = auth.companyId ?? auth.selectedCompany?.id;
        if (companyId != null) {
          // Load data for the company (provider will handle clearing if needed)
          await Provider.of<ExpenseProvider>(
            context,
            listen: false,
          ).loadExpensesForCompany(companyId);
          await Provider.of<CategoryProvider>(
            context,
            listen: false,
          ).loadCategoriesForCompany(companyId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = expenseProvider.expenses.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.trending_down_rounded),
            SizedBox(width: 8),
            Text('Expense Management'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final ap = Provider.of<AuthProvider>(context, listen: false);
          final cid = ap.companyId ?? ap.selectedCompany?.id ?? '';
          showDialog(
            context: context,
            builder: (_) =>
                ExpenseAddDialog(addedBy: auth.role ?? 'admin', companyId: cid),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final companyId =
                          auth.companyId ?? auth.selectedCompany?.id;
                      if (companyId != null) {
                        await Provider.of<ExpenseProvider>(
                          context,
                          listen: false,
                        ).loadExpensesForCompany(companyId);
                        await Provider.of<CategoryProvider>(
                          context,
                          listen: false,
                        ).loadCategoriesForCompany(companyId);
                      }
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: expenseProvider.expenses.length,
                      itemBuilder: (context, index) {
                        final exp = expenseProvider.expenses[index];
                        final catName = categoryProvider.categories
                            .firstWhere(
                              (c) => c.id == exp.categoryId,
                              orElse: () => Category(
                                id: '',
                                name: 'Unknown',
                                gstPercentage: 0.0,
                                lastEditedBy: '',
                                lastEditedAt: DateTime.now(),
                                history: [],
                                companyId: '',
                              ),
                            )
                            .name;
                        return ListTile(
                          title: Text(
                            'Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.gstAmount.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            'Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.paymentMethod.name}\nDate: ${dt.format(exp.date.toLocal())}\nAdded by: ${exp.addedBy}',
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
                    onPressed: () {
                      final ap = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final cid = ap.companyId ?? ap.selectedCompany?.id ?? '';
                      showDialog(
                        context: context,
                        builder: (_) => ExpenseAddDialog(
                          addedBy: auth.role ?? 'admin',
                          companyId: cid,
                        ),
                      );
                    },
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
      ...allExpenses.map((e) => e.paymentMethod.name),
    }.toList()..sort();

    final incomes = allIncomes; // no bank filter for incomes
    final expenses = allExpenses
        .where(
          (e) => _bankFilter == 'All' || e.paymentMethod.name == _bankFilter,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.attach_money_rounded),
            SizedBox(width: 8),
            Text('Income/Expense Viewer'),
          ],
        ),
      ),
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
                    subtitle: Text(
                      'Date: ${_formatDate(inc.date)}\nAdded by: ${inc.addedBy}',
                    ),
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
                          gstPercentage: 0.0,
                          lastEditedBy: '',
                          lastEditedAt: DateTime.now(),
                          history: [],
                          companyId: '',
                        ),
                      )
                      .name;
                  return ListTile(
                    title: Text(
                      'Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.gstAmount.toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      'Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.paymentMethod.name}\nDate: ${_formatDate(exp.date)}\nAdded by: ${exp.addedBy}',
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
