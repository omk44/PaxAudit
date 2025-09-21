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
<<<<<<< Updated upstream
  
=======
  bool _isLoading = false;

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add CA'),
      content: Form(
        key: _formKey,
<<<<<<< Updated upstream
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
=======
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => _email = val.trim(),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(val)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                onChanged: (val) => _name = val.trim(),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter full name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) => _phoneNumber = val.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'License Number (Optional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onChanged: (val) => _licenseNumber = val.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Temporary Password for CA',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                onChanged: (val) => _password = val,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please set a password';
                  if (val.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
            ],
          ),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final caProvider = Provider.of<CAProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(
        context,
        listen: false,
      );
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Get the selected company ID for linking
      final selectedCompany = auth.selectedCompany;
      if (selectedCompany == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No company selected. Please select a company first.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final companyIds = [selectedCompany.id];

      // Create CA with Firebase Auth user
      final success = await caProvider.addCAWithAuth(
        email: _email,
        password: _password,
        name: _name,
        phoneNumber: _phoneNumber.isEmpty ? null : _phoneNumber,
        licenseNumber: _licenseNumber.isEmpty ? null : _licenseNumber,
        companyIds: companyIds,
      );

      if (success) {
        // Link CA to company (both ways)
        try {
          // 1. Add CA email to company's caEmails array
          await companyProvider.addCAToCompany(selectedCompany.id, _email);

          // 2. Get the created CA and add company to its companyIds
          final createdCA = await caProvider.getCAByEmail(_email);
          if (createdCA != null) {
            await caProvider.addCompanyToCA(createdCA.id, selectedCompany.id);
          }

          print('CA successfully linked to company: ${selectedCompany.name}');
        } catch (linkError) {
          print('Error linking CA to company: $linkError');
          // Don't fail the entire operation if linking fails
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CA added and linked to company successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(caProvider.error ?? 'Failed to add CA')),
        );
      }
    } catch (e) {
      print('Error in _handleAdd: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  late String _username;
  late String _password;
  
=======
  late String _email;
  late String _name;
  late String _phoneNumber;
  late String _licenseNumber;
  bool _isLoading = false;

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                onChanged: (val) => _name = val.trim(),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter full name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) => _phoneNumber = val.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _licenseNumber,
                decoration: const InputDecoration(
                  labelText: 'License Number (Optional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onChanged: (val) => _licenseNumber = val.trim(),
              ),
            ],
          ),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
}
=======

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final caProvider = Provider.of<CAProvider>(context, listen: false);
      final updatedCA = widget.ca.copyWith(
        name: _name,
        phoneNumber: _phoneNumber.isEmpty ? null : _phoneNumber,
        licenseNumber: _licenseNumber.isEmpty ? null : _licenseNumber,
      );

      final success = await caProvider.updateCA(updatedCA);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CA updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(caProvider.error ?? 'Failed to update CA')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
>>>>>>> Stashed changes
