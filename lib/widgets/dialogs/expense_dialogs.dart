// widgets/dialogs/expense_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense.dart';

// --- Add Expense Dialog ---
class ExpenseAddDialog extends StatefulWidget {
  final String addedBy;
  const ExpenseAddDialog({required this.addedBy, super.key});

  @override
  State<ExpenseAddDialog> createState() => _ExpenseAddDialogState();
}

class _ExpenseAddDialogState extends State<ExpenseAddDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _categoryId;
  double _amount = 0;
  double _cgst = 0;
  double _sgst = 0;
  String _invoiceNumber = '';
  String _bankAccount = 'Cash';
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return AlertDialog(
      title: const Text('Add Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _categoryId,
                items: categoryProvider.categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _categoryId = val),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (val) => val == null ? 'Select category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _amount = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Enter amount'
                    : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CGST %'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _cgst = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Enter CGST %'
                    : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'SGST %'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _sgst = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Enter SGST %'
                    : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter invoice number' : null,
              ),
              DropdownButtonFormField<String>(
                value: _bankAccount,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank1', child: Text('Bank1')),
                  DropdownMenuItem(value: 'Bank2', child: Text('Bank2')),
                  DropdownMenuItem(value: 'Bank3', child: Text('Bank3')),
                  DropdownMenuItem(value: 'Bank4', child: Text('Bank4')),
                  DropdownMenuItem(value: 'Bank5', child: Text('Bank5')),
                ],
                onChanged: (val) =>
                    setState(() => _bankAccount = val ?? 'Cash'),
                decoration: const InputDecoration(labelText: 'Bank Account'),
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
              Provider.of<ExpenseProvider>(context, listen: false).addExpense(
                categoryId: _categoryId!,
                amount: _amount,
                cgst: _cgst,
                sgst: _sgst,
                invoiceNumber: _invoiceNumber,
                date: _date,
                addedBy: widget.addedBy,
                bankAccount: _bankAccount,
              );
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
  late double _cgst;
  late double _sgst;
  late String _invoiceNumber;
  late String _bankAccount;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.expense.categoryId;
    _amount = widget.expense.amount;
    _cgst = widget.expense.cgst;
    _sgst = widget.expense.sgst;
    _invoiceNumber = widget.expense.invoiceNumber;
    _bankAccount = widget.expense.bankAccount;
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
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Select a category'),
                  ),
                  ...categoryProvider.categories.map(
                    (cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  ),
                ],
                onChanged: (val) => setState(() => _categoryId = val ?? ''),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select a category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                initialValue: _amount.toString(),
                onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CGST (%)'),
                keyboardType: TextInputType.number,
                initialValue: _cgst.toString(),
                onChanged: (val) => _cgst = double.tryParse(val) ?? 0.0,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter CGST' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'SGST (%)'),
                keyboardType: TextInputType.number,
                initialValue: _sgst.toString(),
                onChanged: (val) => _sgst = double.tryParse(val) ?? 0.0,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter SGST' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                initialValue: _invoiceNumber,
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter invoice number' : null,
              ),
              DropdownButtonFormField<String>(
                value: _bankAccount,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank1', child: Text('Bank1')),
                  DropdownMenuItem(value: 'Bank2', child: Text('Bank2')),
                  DropdownMenuItem(value: 'Bank3', child: Text('Bank3')),
                  DropdownMenuItem(value: 'Bank4', child: Text('Bank4')),
                  DropdownMenuItem(value: 'Bank5', child: Text('Bank5')),
                ],
                onChanged: (val) =>
                    setState(() => _bankAccount = val ?? 'Cash'),
                decoration: const InputDecoration(labelText: 'Bank Account'),
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
              Provider.of<ExpenseProvider>(context, listen: false).editExpense(
                widget.expense.id,
                _amount,
                _cgst,
                _sgst,
                _invoiceNumber,
                widget.editedBy,
                _bankAccount,
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
                'Amount: ${h.amount.toStringAsFixed(2)} | CGST: ${h.cgst.toStringAsFixed(2)} | SGST: ${h.sgst.toStringAsFixed(2)} | Invoice: ${h.invoiceNumber}',
              ),
              subtitle: Text(
                'By: ${h.editedBy} at ${dt.format(h.timestamp.toLocal())} | Bank: ${expense.bankAccount}',
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
