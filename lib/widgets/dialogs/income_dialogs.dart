// widgets/dialogs/income_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/income_provider.dart';
import '../../models/income.dart';

// --- Add Income Dialog ---
class IncomeAddDialog extends StatefulWidget {
  final String addedBy;
  const IncomeAddDialog({required this.addedBy, super.key});

  @override
  State<IncomeAddDialog> createState() => _IncomeAddDialogState();
}

class _IncomeAddDialogState extends State<IncomeAddDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter amount' : null,
            ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Provider.of<IncomeProvider>(context, listen: false).addIncome(
                amount: _amount,
                date: _date,
                addedBy: widget.addedBy,
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

  @override
  void initState() {
    super.initState();
    _amount = widget.income.amount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Income'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          initialValue: _amount.toString(),
          decoration: const InputDecoration(labelText: 'Amount'),
          keyboardType: TextInputType.number,
          onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
          validator: (val) =>
              val == null || val.isEmpty ? 'Enter amount' : null,
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
              Provider.of<IncomeProvider>(
                context,
                listen: false,
              ).editIncome(widget.income.id, _amount, widget.editedBy);
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
