import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ca_provider.dart';
import '../../models/ca.dart';

// --- Add CA Dialog ---
class CAAddDialog extends StatefulWidget {
  const CAAddDialog({super.key});
  
  @override
  State<CAAddDialog> createState() => _CAAddDialogState();
}

class _CAAddDialogState extends State<CAAddDialog> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add CA'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: (val) => _username = val,
              validator: (val) => val == null || val.isEmpty ? 'Enter username' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (val) => _password = val,
              validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
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
              Provider.of<CAProvider>(context, listen: false).addCA(_username, _password);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// --- Edit CA Dialog ---
class CAEditDialog extends StatefulWidget {
  final CA ca;
  const CAEditDialog({required this.ca, super.key});
  
  @override
  State<CAEditDialog> createState() => _CAEditDialogState();
}

class _CAEditDialogState extends State<CAEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _username;
  late String _password;
  
  @override
  void initState() {
    super.initState();
    _username = widget.ca.username;
    _password = widget.ca.password;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit CA'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _username,
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: (val) => _username = val,
              validator: (val) => val == null || val.isEmpty ? 'Enter username' : null,
            ),
            TextFormField(
              initialValue: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (val) => _password = val,
              validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
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
              Provider.of<CAProvider>(context, listen: false)
                  .editCA(widget.ca.id, _username, _password);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}