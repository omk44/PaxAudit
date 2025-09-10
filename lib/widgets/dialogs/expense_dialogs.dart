// widgets/dialogs/expense_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense.dart';
import '../../models/category.dart';

// --- Add Expense Dialog ---
class ExpenseAddDialog extends StatefulWidget {
  final String addedBy;
  final String companyId;
  const ExpenseAddDialog({required this.addedBy, required this.companyId, super.key});

  @override
  State<ExpenseAddDialog> createState() => _ExpenseAddDialogState();
}

class _ExpenseAddDialogState extends State<ExpenseAddDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  double _amount = 0;
  double _gstPercentage = 0.0;
  double _gstAmount = 0.0;
  String _invoiceNumber = '';
  String _description = '';
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    // Ensure categories are loaded after first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = Provider.of<AuthProvider>(context, listen: false);
      final companyId = ap.companyId ?? ap.selectedCompany?.id;
      if (categoryProvider.categories.isEmpty && companyId != null && companyId.isNotEmpty) {
        // ignore: discarded_futures
        categoryProvider.loadCategoriesForCompany(companyId);
      }
    });
    return AlertDialog(
      title: const Text('Add Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                items: categoryProvider.categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedCategoryId = val ?? '';
                  final selected = categoryProvider.categories
                      .firstWhere(
                        (cat) => cat.id == _selectedCategoryId,
                        orElse: () => Category(
                          id: '',
                          name: '',
                          gstPercentage: 0.0,
                          lastEditedBy: '',
                          lastEditedAt: DateTime.now(),
                          history: [],
                          companyId: '',
                        ),
                      );
                  _selectedCategoryName = selected.name;
                  _gstPercentage = selected.gstPercentage;
                  _gstAmount = (_amount * _gstPercentage) / 100;
                }),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (val) => val == null ? 'Select category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    _amount = double.tryParse(val) ?? 0;
                    // Calculate GST based on selected category
                    if (_selectedCategoryId.isNotEmpty) {
                      final category = categoryProvider.categories
                          .firstWhere((cat) => cat.id == _selectedCategoryId);
                      _gstPercentage = category.gstPercentage;
                      _gstAmount = (_amount * _gstPercentage) / 100;
                    }
                  });
                },
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Enter amount'
                    : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'GST % (Auto-calculated)'),
                readOnly: true,
                controller: TextEditingController(text: _gstPercentage.toStringAsFixed(2)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'GST Amount (Auto-calculated)'),
                readOnly: true,
                controller: TextEditingController(text: _gstAmount.toStringAsFixed(2)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) => _description = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter invoice number' : null,
              ),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                items: PaymentMethod.values.map((method) => DropdownMenuItem(
                  value: method,
                  child: Text('${method.icon} ${method.displayName}'),
                )).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val ?? PaymentMethod.cash),
                decoration: const InputDecoration(labelText: 'Payment Method'),
                validator: (val) => val == null ? 'Select payment method' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                controller: TextEditingController(
                  text: _date.toLocal().toString().split(' ').first,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Provider.of<ExpenseProvider>(context, listen: false).addExpense(Expense(
                id: '',
                categoryId: _selectedCategoryId,
                categoryName: _selectedCategoryName,
                amount: _amount,
                gstPercentage: _gstPercentage,
                gstAmount: _gstAmount,
                invoiceNumber: _invoiceNumber,
                description: _description,
                date: _date,
                addedBy: widget.addedBy,
                paymentMethod: _paymentMethod,
                history: [],
                companyId: widget.companyId,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// --- Edit Expense Dialog ---
class ExpenseEditDialog extends StatefulWidget {
  final Expense expense;
  final String editedBy;
  const ExpenseEditDialog({
    required this.expense,
    required this.editedBy,
    super.key,
  });

  @override
  State<ExpenseEditDialog> createState() => _ExpenseEditDialogState();
}

class _ExpenseEditDialogState extends State<ExpenseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _categoryId;
  late double _amount;
  late double _gstPercentage;
  late double _gstAmount;
  late String _invoiceNumber;
  late String _description;
  late PaymentMethod _paymentMethod;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.expense.categoryId;
    _amount = widget.expense.amount;
    _gstPercentage = widget.expense.gstPercentage;
    _gstAmount = widget.expense.gstAmount;
    _invoiceNumber = widget.expense.invoiceNumber;
    _description = widget.expense.description;
    _paymentMethod = widget.expense.paymentMethod;
    _date = widget.expense.date;
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return AlertDialog(
      title: const Text('Edit Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: categoryProvider.categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categoryProvider.categories
                    .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
                    .toList(),
                onChanged: (val) => setState(() {
                  _categoryId = val ?? '';
                  final selected = categoryProvider.categories.firstWhere(
                    (c) => c.id == _categoryId,
                    orElse: () => Category(
                      id: '',
                      name: '',
                      gstPercentage: 0.0,
                      lastEditedBy: '',
                      lastEditedAt: DateTime.now(),
                      history: [],
                      companyId: '',
                    ),
                  );
                  _gstPercentage = selected.gstPercentage;
                  _gstAmount = (_amount * _gstPercentage) / 100;
                }),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select a category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                initialValue: _amount.toString(),
                onChanged: (val) => setState(() {
                  _amount = double.tryParse(val) ?? 0.0;
                  _gstAmount = (_amount * _gstPercentage) / 100;
                }),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'GST % (Auto-calculated)'),
                readOnly: true,
                controller: TextEditingController(text: _gstPercentage.toStringAsFixed(2)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'GST Amount (Auto-calculated)'),
                readOnly: true,
                controller: TextEditingController(text: _gstAmount.toStringAsFixed(2)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                initialValue: _invoiceNumber,
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter invoice number' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                initialValue: _description,
                onChanged: (val) => _description = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter description' : null,
              ),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                items: PaymentMethod.values.map((method) => DropdownMenuItem(
                  value: method,
                  child: Text('${method.icon} ${method.displayName}'),
                )).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val ?? PaymentMethod.cash),
                decoration: const InputDecoration(labelText: 'Payment Method'),
                validator: (val) => val == null ? 'Select payment method' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                controller: TextEditingController(
                  text: _date.toLocal().toString().split(' ').first,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedExpense = widget.expense.copyWith(
                  categoryId: _categoryId,
                  categoryName: categoryProvider.categories
                      .firstWhere(
                        (c) => c.id == _categoryId,
                        orElse: () => Category(
                          id: '', name: '', gstPercentage: 0, lastEditedBy: '', lastEditedAt: DateTime.now(), history: [], companyId: '',
                        ),
                      )
                      .name,
                  amount: _amount,
                  gstPercentage: _gstPercentage,
                  gstAmount: _gstAmount,
                  invoiceNumber: _invoiceNumber,
                  description: _description,
                  date: _date,
                  paymentMethod: _paymentMethod,
              );
              Provider.of<ExpenseProvider>(context, listen: false).editExpense(
                updatedExpense,
                editedBy: widget.editedBy,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Expense History Dialog ---
class ExpenseHistoryDialog extends StatelessWidget {
  final Expense expense;
  final CategoryProvider categoryProvider;
  const ExpenseHistoryDialog({
    required this.expense,
    required this.categoryProvider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateFormat('yyyy-MM-dd HH:mm');
    return AlertDialog(
      title: const Text('Edit History'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: expense.history.length,
          itemBuilder: (context, index) {
            final h = expense.history[index];
            return ListTile(
              title: Text(
                'Amount: ${h.amount.toStringAsFixed(2)} | GST: ${h.gstAmount.toStringAsFixed(2)} | Invoice: ${h.invoiceNumber}',
              ),
              subtitle: Text(
                'By: ${h.editedBy} at ${dt.format(h.timestamp.toLocal())} | Bank: ${expense.paymentMethod.displayName}',
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
