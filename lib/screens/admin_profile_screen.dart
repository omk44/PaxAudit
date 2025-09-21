import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  void _loadCompanyData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final company = auth.selectedCompany;
    
    if (company != null) {
      _companyNameController.text = company.name;
      _gstNumberController.text = company.gstNumber ?? '';
      _panNumberController.text = company.panNumber ?? '';
      _addressController.text = company.address ?? '';
      _cityController.text = company.city ?? '';
      _stateController.text = company.state ?? '';
      _pincodeController.text = company.pincode ?? '';
      _phoneController.text = company.phoneNumber ?? '';
      _emailController.text = company.email ?? '';
      _websiteController.text = company.website ?? '';
      _contactPersonController.text = company.contactPerson ?? '';
      _contactPhoneController.text = company.contactPhone ?? '';
      _contactEmailController.text = company.contactEmail ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final company = auth.selectedCompany;

    if (company == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Profile'),
        ),
        body: const Center(
          child: Text('No company selected'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            )
          else ...[
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 30,
                          color: Colors.blue,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GST: ${company.gstNumber ?? "Not provided"}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Admin: ${auth.user?.email ?? "Unknown"}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Company Details Section
              const Text(
                'Company Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        icon: Icons.business,
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _gstNumberController,
                              label: 'GST Number',
                              icon: Icons.receipt,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(value)) {
                                    return 'Invalid GST format';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _panNumberController,
                              label: 'PAN Number',
                              icon: Icons.credit_card,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
                                    return 'Invalid PAN format';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        enabled: _isEditing,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _stateController,
                              label: 'State',
                              icon: Icons.map,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              icon: Icons.pin_drop,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                                    return 'Invalid pincode';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contact Details Section
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Company Phone',
                        icon: Icons.phone,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
                              return 'Invalid phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _emailController,
                        label: 'Company Email',
                        icon: Icons.email,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Invalid email format';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        icon: Icons.web,
                        enabled: _isEditing,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contact Person Section
              const Text(
                'Contact Person Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _contactPersonController,
                        label: 'Contact Person Name',
                        icon: Icons.person,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _contactPhoneController,
                              label: 'Contact Phone',
                              icon: Icons.phone,
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
                                    return 'Invalid phone number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _contactEmailController,
                              label: 'Contact Email',
                              icon: Icons.email,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Invalid email format';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Company Statistics
              const Text(
                'Company Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Created',
                              _formatDate(company.createdAt),
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Last Updated',
                              _formatDate(company.updatedAt),
                              Icons.update,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _loadCompanyData(); // Reset to original values
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      
      final updatedCompany = auth.selectedCompany!.copyWith(
        name: _companyNameController.text.trim(),
        gstNumber: _gstNumberController.text.trim().isEmpty ? null : _gstNumberController.text.trim(),
        panNumber: _panNumberController.text.trim().isEmpty ? null : _panNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        updatedAt: DateTime.now(),
      );

      final success = await companyProvider.updateCompany(updatedCompany);
      
      if (success && mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(companyProvider.error ?? 'Failed to update company details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }
}
