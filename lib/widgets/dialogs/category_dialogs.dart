// widgets/dialogs/category_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../models/category.dart';

// --- Add Category Dialog ---
class CategoryAddDialog extends StatefulWidget {
  final String editedBy;
  const CategoryAddDialog({required this.editedBy, super.key});

  @override
  State<CategoryAddDialog> createState() => _CategoryAddDialogState();
}

class _CategoryAddDialogState extends State<CategoryAddDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Category Name'),
          onChanged: (val) => _name = val,
          validator: (val) =>
              val == null || val.isEmpty ? 'Enter category name' : null,
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
              Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).addCategory(_name, widget.editedBy);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// --- Edit Category Dialog ---
class CategoryEditDialog extends StatefulWidget {
  final Category category;
  final String editedBy;
  const CategoryEditDialog({
    required this.category,
    required this.editedBy,
    super.key,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.category.name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          initialValue: _name,
          decoration: const InputDecoration(labelText: 'Category Name'),
          onChanged: (val) => _name = val,
          validator: (val) =>
              val == null || val.isEmpty ? 'Enter category name' : null,
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
              Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).editCategory(widget.category.id, _name, widget.editedBy);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Category History Dialog ---
class CategoryHistoryDialog extends StatelessWidget {
  final Category category;
  const CategoryHistoryDialog({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit History'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: category.history.length,
          itemBuilder: (context, index) {
            final h = category.history[index];
            return ListTile(
              title: Text('Name: ${h.name}'),
              subtitle: Text('By: ${h.editedBy} at ${h.timestamp.toLocal()}'),
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
