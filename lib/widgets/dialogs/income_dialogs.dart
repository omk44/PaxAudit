// widgets/dialogs/income_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/income_provider.dart';
import '../../models/income.dart';
import '../../models/expense.dart';

// --- Add Income Dialog ---
class IncomeAddDialog extends StatefulWidget {
  final String addedBy;
  final String companyId;
  const IncomeAddDialog({
    required this.addedBy,
    required this.companyId,
    super.key,
  });

  @override
  State<IncomeAddDialog> createState() => _IncomeAddDialogState();
}

class _IncomeAddDialogState extends State<IncomeAddDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  String _description = '';
  DateTime _date = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _transactionId = '';

  bool _isValidAmount(String v) =>
      RegExp(r'^(?:\d+)(?:\.\d{1,2})?$').hasMatch(v);

  bool _needsTransactionId(PaymentMethod method) =>
      method != PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter amount';
                if (!_isValidAmount(val))
                  return 'Amount must be digits (max 2 decimals)';
                if ((double.tryParse(val) ?? 0) <= 0)
                  return 'Amount must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (val) => _description = val,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter description' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              items: PaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text('${method.icon} ${method.displayName}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _paymentMethod = val ?? PaymentMethod.cash),
              decoration: const InputDecoration(labelText: 'Payment Method'),
              validator: (val) => val == null ? 'Select payment method' : null,
            ),
            if (_needsTransactionId(_paymentMethod)) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('transaction_id_field'),
                initialValue: '',
                decoration: const InputDecoration(
                  labelText: 'Transaction/UPI ID (12+ chars)',
                  hintText: 'Enter 12-digit transaction ID',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.text,
                onChanged: (v) => _transactionId = v.trim(),
                validator: (val) {
                  if (!_needsTransactionId(_paymentMethod)) return null;
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter transaction/UPI ID';
                  }
                  if (val.trim().length < 12) {
                    return 'Must be at least 12 characters';
                  }
                  if (!RegExp(r'^[A-Za-z0-9\-_.@]+$').hasMatch(val.trim())) {
                    return 'Only letters, digits and - _ . @ allowed';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date'),
              readOnly: true,
              controller: TextEditingController(
                text: _date.toLocal().toString().split(' ').first,
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null && picked != _date) {
                  setState(() {
                    _date = picked;
                  });
                }
              },
            ),
          ],
        ),
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
              Provider.of<IncomeProvider>(context, listen: false).addIncome(
                Income(
                  id: '',
                  amount: _amount,
                  description: _description,
                  category: '',
                  date: _date,
                  addedBy: widget.addedBy,
                  history: [],
                  companyId: widget.companyId,
                  paymentMethod: _paymentMethod,
                  transactionId: _needsTransactionId(_paymentMethod)
                      ? _transactionId
                      : null,
                ),
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

// --- Edit Income Dialog ---
class IncomeEditDialog extends StatefulWidget {
  final Income income;
  final String editedBy;
  const IncomeEditDialog({
    required this.income,
    required this.editedBy,
    super.key,
  });

  @override
  State<IncomeEditDialog> createState() => _IncomeEditDialogState();
}

class _IncomeEditDialogState extends State<IncomeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late double _amount;
  late String _description;
  late PaymentMethod _paymentMethod;
  late String _transactionId;

  bool _isValidAmount(String v) =>
      RegExp(r'^(?:\d+)(?:\.\d{1,2})?$').hasMatch(v);

  bool _needsTransactionId(PaymentMethod method) =>
      method != PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amount = widget.income.amount;
    _description = widget.income.description;
    _paymentMethod = widget.income.paymentMethod;
    _transactionId = widget.income.transactionId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Income'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            TextFormField(
              initialValue: _amount.toString(),
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter amount';
                if (!_isValidAmount(val))
                  return 'Amount must be digits (max 2 decimals)';
                if ((double.tryParse(val) ?? 0) <= 0)
                  return 'Amount must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (val) => _description = val,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter description' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              items: PaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text('${method.icon} ${method.displayName}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => _paymentMethod = val ?? PaymentMethod.cash),
              decoration: const InputDecoration(labelText: 'Payment Method'),
              validator: (val) => val == null ? 'Select payment method' : null,
            ),
            if (_needsTransactionId(_paymentMethod)) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _transactionId,
                decoration: const InputDecoration(
                  labelText: 'Transaction/UPI ID (12+ chars)',
                  hintText: 'Enter 12-digit transaction ID',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.text,
                onChanged: (v) => _transactionId = v.trim(),
                validator: (val) {
                  if (!_needsTransactionId(_paymentMethod)) return null;
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter transaction/UPI ID';
                  }
                  if (val.trim().length < 12) {
                    return 'Must be at least 12 characters';
                  }
                  if (!RegExp(r'^[A-Za-z0-9\-_.@]+$').hasMatch(val.trim())) {
                    return 'Only letters, digits and - _ . @ allowed';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
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
              final updated = widget.income.copyWith(
                amount: _amount,
                description: _description,
                category: '',
                paymentMethod: _paymentMethod,
                transactionId: _needsTransactionId(_paymentMethod)
                    ? _transactionId
                    : null,
              );
              Provider.of<IncomeProvider>(
                context,
                listen: false,
              ).updateIncome(updated, editedBy: widget.editedBy);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Income History Dialog ---
class IncomeHistoryDialog extends StatelessWidget {
  final Income income;
  const IncomeHistoryDialog({required this.income, super.key});

  @override
  Widget build(BuildContext context) {
    final dt = DateFormat('yyyy-MM-dd HH:mm');
    return AlertDialog(
      title: const Text('Edit History'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: income.history.length,
          itemBuilder: (context, index) {
            final h = income.history[index];
            return ListTile(
              title: Text('Amount: ${h.amount.toStringAsFixed(2)}'),
              subtitle: Text(
                'By: ${h.editedBy} at ${dt.format(h.timestamp.toLocal())}',
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
