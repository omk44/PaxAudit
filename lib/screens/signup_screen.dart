// screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Account details
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  
  // Company details
  String _companyName = '';
  String _adminName = '';
  String _companyDescription = '';
  String _companyAddress = '';
  String _companyCity = '';
  String _companyState = '';
  String _companyPincode = '';
  String _companyPhone = '';
  String _companyEmail = '';
  String _companyWebsite = '';
  String _gstNumber = '';
  String _panNumber = '';
  String _contactPerson = '';
  String _contactPhone = '';
  String _contactEmail = '';
  
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Create Company Account (${_currentStep + 1}/3)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF6366F1),
      ),
      body: Form(
          key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAccountStep(),
            _buildCompanyStep(),
            _buildContactStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                Icons.admin_panel_settings,
                    size: 40,
                    color: Color(0xFF6366F1),
                  ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Administrator Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
                Text(
                  'First, set up your login credentials',
                textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Email Input
          _buildInputCard(
            child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) => _email = val.trim(),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your email address';
                          }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
            ),
                      ),
                      const SizedBox(height: 16),

          // Password Input
          _buildInputCard(
            child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                        ),
                        obscureText: true,
                        onChanged: (val) => _password = val,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
            ),
                      ),
                      const SizedBox(height: 16),

          // Confirm Password Input
          _buildInputCard(
            child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                          prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                        ),
                        obscureText: true,
                        onChanged: (val) => _confirmPassword = val,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (val != _password) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
            ),
          ),
          const SizedBox(height: 32),

          // Next Button
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next: Company Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Login Link
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 40,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Company Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Now, tell us about your company',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // Company Name (Required)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'Enter your company name',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => _companyName = val.trim(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your company name';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Admin Name (Required)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Your Full Name *',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => _adminName = val.trim(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Company Description (Optional)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Description',
                hintText: 'Brief description of your company (optional)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              onChanged: (val) => _companyDescription = val.trim(),
            ),
          ),
          const SizedBox(height: 16),

          // Company Address (Required)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Address *',
                hintText: 'Enter company address',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (val) => _companyAddress = val.trim(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter company address';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // City, State, Pincode Row (Required)
          Row(
            children: [
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      hintText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => _companyCity = val.trim(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter city';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      hintText: 'State',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => _companyState = val.trim(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter state';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      hintText: 'Pincode',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _companyPincode = val.trim(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter pincode';
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(val)) {
                        return 'Enter 6-digit pincode';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GST and PAN Row (Required)
          Row(
            children: [
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'GST Number *',
                      hintText: 'GST Number',
                      prefixIcon: Icon(Icons.receipt_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => _gstNumber = val.trim(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter GST number';
                      }
                      // Basic GSTIN pattern: 15 chars alphanumeric
                      if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(val)) {
                        return 'Enter valid GSTIN';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'PAN Number *',
                      hintText: 'PAN Number',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => _panNumber = val.trim(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Enter PAN number';
                      }
                      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(val)) {
                        return 'Enter valid PAN';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Company Phone (Required)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Phone *',
                hintText: 'Enter company phone number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (val) => _companyPhone = val.trim(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Enter company phone number';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(val)) {
                  return 'Enter 10-digit phone';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Company Email (Required)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Email *',
                hintText: 'Enter company email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => _companyEmail = val.trim(),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Enter company email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                  return 'Enter valid email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Company Website (Optional)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Company Website',
                hintText: 'Enter company website (optional)',
                prefixIcon: Icon(Icons.web_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.url,
              onChanged: (val) => _companyWebsite = val.trim(),
            ),
          ),
          const SizedBox(height: 32),

              // Error Message
          if (_error != null) ...[
                Container(
              padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
          ],

          // Next Button
              ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                    'Next: Contact Details',
                        style: TextStyle(
                      fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

          // Back Button
          OutlinedButton(
            onPressed: _isLoading ? null : _previousStep,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
                child: const Text(
              'Back to Account Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contact_phone,
                    size: 40,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact Person Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add contact person information (optional)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Person Name (Optional)
          _buildInputCard(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Contact Person Name',
                hintText: 'Enter contact person name (optional)',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => _contactPerson = val.trim(),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Phone and Email Row
          Row(
            children: [
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: 'Contact phone (optional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => _contactPhone = val.trim(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputCard(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contact Email',
                      hintText: 'Contact email (optional)',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => _contactEmail = val.trim(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Error Message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Create Account Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Company Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Back Button
          OutlinedButton(
            onPressed: _isLoading ? null : _previousStep,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Company Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate account details
      final emailValid = _email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email);
      final passwordValid = _password.isNotEmpty && _password.length >= 6;
      final confirmPasswordValid = _confirmPassword == _password;

      if (!emailValid) {
        setState(() => _error = 'Please enter a valid email address');
        return;
      }
      if (!passwordValid) {
        setState(() => _error = 'Password must be at least 6 characters');
        return;
      }
      if (!confirmPasswordValid) {
        setState(() => _error = 'Passwords do not match');
        return;
      }

      setState(() {
        _currentStep = 1;
        _error = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
      // Validate company details
      if (_companyName.isEmpty) {
        setState(() => _error = 'Please enter your company name');
        return;
      }
      if (_adminName.isEmpty) {
        setState(() => _error = 'Please enter your full name');
        return;
      }
      if (_companyAddress.isEmpty) {
        setState(() => _error = 'Please enter company address');
        return;
      }
      if (_companyCity.isEmpty) {
        setState(() => _error = 'Please enter city');
        return;
      }
      if (_companyState.isEmpty) {
        setState(() => _error = 'Please enter state');
        return;
      }
      if (_companyPincode.isEmpty || !RegExp(r'^\d{6}$').hasMatch(_companyPincode)) {
        setState(() => _error = 'Please enter a valid 6-digit pincode');
        return;
      }
      if (_gstNumber.isEmpty || !RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(_gstNumber)) {
        setState(() => _error = 'Please enter a valid GSTIN');
        return;
      }
      if (_panNumber.isEmpty || !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(_panNumber)) {
        setState(() => _error = 'Please enter a valid PAN');
        return;
      }
      if (_companyPhone.isEmpty || !RegExp(r'^\d{10}$').hasMatch(_companyPhone)) {
        setState(() => _error = 'Please enter a valid 10-digit company phone');
        return;
      }
      if (_companyEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_companyEmail)) {
        setState(() => _error = 'Please enter a valid company email');
        return;
      }

      setState(() {
        _currentStep = 2;
        _error = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _error = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _error = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required company fields
    if (_companyName.isEmpty) {
      setState(() => _error = 'Please enter your company name');
      return;
    }
    if (_adminName.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }
    if (_companyAddress.isEmpty) {
      setState(() => _error = 'Please enter company address');
      return;
    }
    if (_companyCity.isEmpty) {
      setState(() => _error = 'Please enter city');
      return;
    }
    if (_companyState.isEmpty) {
      setState(() => _error = 'Please enter state');
      return;
    }
    if (_companyPincode.isEmpty || !RegExp(r'^\d{6}$').hasMatch(_companyPincode)) {
      setState(() => _error = 'Please enter a valid 6-digit pincode');
      return;
    }
    if (_gstNumber.isEmpty || !RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(_gstNumber)) {
      setState(() => _error = 'Please enter a valid GSTIN');
      return;
    }
    if (_panNumber.isEmpty || !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(_panNumber)) {
      setState(() => _error = 'Please enter a valid PAN');
      return;
    }
    if (_companyPhone.isEmpty || !RegExp(r'^\d{10}$').hasMatch(_companyPhone)) {
      setState(() => _error = 'Please enter a valid 10-digit company phone');
      return;
    }
    if (_companyEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_companyEmail)) {
      setState(() => _error = 'Please enter a valid company email');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // First create the user account
      final success = await authProvider.createUserWithEmailAndPassword(
        _email,
        _password,
        'admin',
      );

      if (success) {
        // Then create the company with all details
        final companySuccess = await authProvider.createCompanyForAdminWithDetails(
          _companyName,
          _adminName,
          _companyDescription.isEmpty ? null : _companyDescription,
          _companyAddress.isEmpty ? null : _companyAddress,
          _companyCity.isEmpty ? null : _companyCity,
          _companyState.isEmpty ? null : _companyState,
          _companyPincode.isEmpty ? null : _companyPincode,
          _companyPhone.isEmpty ? null : _companyPhone,
          _companyEmail.isEmpty ? null : _companyEmail,
          _companyWebsite.isEmpty ? null : _companyWebsite,
          _gstNumber.isEmpty ? null : _gstNumber,
          _panNumber.isEmpty ? null : _panNumber,
          _contactPerson.isEmpty ? null : _contactPerson,
          _contactPhone.isEmpty ? null : _contactPhone,
          _contactEmail.isEmpty ? null : _contactEmail,
        );

        if (companySuccess) {
          // Navigate to admin dashboard
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          setState(() {
            _error = 'Account created but failed to create company. Please contact support.';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to create account. Email may already be in use.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Signup failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
