import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PaxAuditApp());
}

// --- CA Model ---
class CA {
  final String id;
  String username;
  String password;
  CA({required this.id, required this.username, required this.password});
}

// --- CA Provider ---
class CAProvider extends ChangeNotifier {
  final List<CA> _cas = [];
  List<CA> get cas => List.unmodifiable(_cas);

  CAProvider() {
    _subscribe();
  }

  Future<void> _subscribe() async {
    FirebaseFirestore.instance.collection('cas').snapshots().listen((snapshot) {
      _cas
        ..clear()
        ..addAll(snapshot.docs.map((d) {
          final data = d.data();
          return CA(
            id: d.id,
            username: (data['username'] ?? '') as String,
            password: (data['password'] ?? '') as String,
          );
        }));
      notifyListeners();
    });
  }

  void addCA(String username, String password) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _cas.add(CA(id: id, username: username, password: password));
    notifyListeners();
    FirebaseFirestore.instance.collection('cas').doc(id).set({
      'username': username,
      'password': password,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void editCA(String id, String username, String password) {
    final ca = _cas.firstWhere((c) => c.id == id);
    ca.username = username;
    ca.password = password;
    notifyListeners();
    FirebaseFirestore.instance.collection('cas').doc(id).update({
      'username': username,
      'password': password,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void deleteCA(String id) {
    _cas.removeWhere((c) => c.id == id);
    notifyListeners();
    FirebaseFirestore.instance.collection('cas').doc(id).delete();
  }

  CA? getCAByCredentials(String username, String password) {
    try {
      return _cas.firstWhere((c) => c.username == username && c.password == password);
    } catch (_) {
      return null;
    }
  }

  CA? getCAById(String id) {
    try {
      return _cas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

// --- Update AuthProvider for CA login ---
class AuthProvider extends ChangeNotifier {
  String? _role; // 'admin' or 'ca'
  String? _caId; // If CA, store CA id
  String? _uid; // Firebase UID
  bool get isLoggedIn => _uid != null;
  String? get role => _role;
  String? get caId => _caId;
  String? get uid => _uid;

  Future<void> refreshFromCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _uid = null;
      _role = null;
      _caId = null;
      notifyListeners();
      return;
    }
    _uid = user.uid;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data();
    _role = data != null ? (data['role'] as String?) : null;
    _caId = data != null ? (data['caId'] as String?) : null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    await refreshFromCurrentUser();
  }

  Future<void> signUpAdmin(String email, String password) async {
    final creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await refreshFromCurrentUser();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _uid = null;
    _role = null;
    _caId = null;
    notifyListeners();
  }
}

// --- Main App ---
class PaxAuditApp extends StatelessWidget {
  const PaxAuditApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CAProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
      ],
      child: MaterialApp(
        title: 'PaxAudit',
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF0B5CAD),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF0B5CAD),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/admin_dashboard': (context) => const AdminDashboard(),
          '/ca_dashboard': (context) => const CADashboard(),
          '/ca_management': (context) => const CAManagementScreen(),
          '/ca_details': (context) => const CADetailsScreen(),
          '/category_management': (context) => const CategoryManagementScreen(),
          '/income_management': (context) => const IncomeManagementScreen(),
          '/expense_management': (context) => const ExpenseManagementScreen(),
          '/tax_summary': (context) => const TaxSummaryScreen(),
          '/bank_statements': (context) => const BankStatementsScreen(),
          '/request_statement': (context) => const RequestStatementScreen(),
          '/comment_modal': (context) => const CommentModalScreen(),
        },
      ),
    );
  }
}

// --- Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeFromAuth();
    });
  }

  Future<void> _routeFromAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await authProvider.refreshFromCurrentUser();
    if (!mounted) return;
    if (authProvider.role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (authProvider.role == 'ca') {
      Navigator.pushReplacementNamed(context, '/ca_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PaxAudit', style: TextStyle(fontSize: 32))),
    );
  }
}

// --- Login Screen (update CA logic) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String? _error;
  String _selectedRole = 'ca'; // user-chosen expected role

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'ca', child: Text('CA')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val ?? 'ca'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => _email = val.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => _password = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  try {
                    await authProvider.signIn(_email, _password);
                    var role = authProvider.role;
                    // If no role yet and user chose CA, provision a CA role doc automatically
                    if (role == null && _selectedRole == 'ca' && authProvider.uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(authProvider.uid!).set({
                        'role': 'ca',
                        'createdAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                      await authProvider.refreshFromCurrentUser();
                      role = authProvider.role;
                    }

                    await FirebaseAnalytics.instance.logLogin(loginMethod: role ?? 'email_password');

                    if (role == 'admin' && _selectedRole == 'admin') {
                      if (!mounted) return; Navigator.pushReplacementNamed(context, '/admin_dashboard');
                    } else if (role == 'ca' && _selectedRole == 'ca') {
                      if (!mounted) return; Navigator.pushReplacementNamed(context, '/ca_dashboard');
                    } else if (role == null) {
                      setState(() { _error = 'No role assigned. Choose CA or contact admin.'; });
                    } else {
                      setState(() { _error = 'Selected role does not match your account role ($role).'; });
                    }
                  } catch (e) {
                    setState(() { _error = e.toString(); });
                  }
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Sign up as Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Signup Screen (Admin Only) ---
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Admin Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => _email = val.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => _password = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  try {
                    await Provider.of<AuthProvider>(context, listen: false).signUpAdmin(_email, _password);
                    await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email_password_admin');
                    if (!mounted) return; Navigator.pushReplacementNamed(context, '/admin_dashboard');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Admin Dashboard ---
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('CA Management'),
            onTap: () => Navigator.pushNamed(context, '/ca_management'),
          ),
          ListTile(
            title: const Text('Category Management'),
            onTap: () => Navigator.pushNamed(context, '/category_management'),
          ),
          ListTile(
            title: const Text('Income/Expense Viewer'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeExpenseManagerScreen()),
            ),
          ),
          ListTile(
            title: const Text('Income Management'),
            onTap: () => Navigator.pushNamed(context, '/income_management'),
          ),
          ListTile(
            title: const Text('Expense Management'),
            onTap: () => Navigator.pushNamed(context, '/expense_management'),
          ),
          ListTile(
            title: const Text('Tax Summary'),
            onTap: () => Navigator.pushNamed(context, '/tax_summary'),
          ),
          ListTile(
            title: const Text('Bank Statements'),
            onTap: () => Navigator.pushNamed(context, '/bank_statements'),
          ),
          ListTile(
            title: const Text('Documents & Passbook'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CA Management Screen (Admin only) ---
class CAManagementScreen extends StatelessWidget {
  const CAManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final caProvider = Provider.of<CAProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('CA Management')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: caProvider.cas.length,
              itemBuilder: (context, index) {
                final ca = caProvider.cas[index];
                return ListTile(
                  title: Text(ca.username),
                  subtitle: Text('ID: ${ca.id}'),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add CA'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CAAddDialog(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

// --- CA Details Screen (for CA to view their own info) ---
class CADetailsScreen extends StatelessWidget {
  const CADetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final caProvider = Provider.of<CAProvider>(context);
    final ca = caProvider.getCAById(auth.caId ?? '');
    if (ca == null) {
      return const Scaffold(
        body: Center(child: Text('CA details not found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('CA Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${ca.id}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Username: ${ca.username}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Password: ${ca.password}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// --- Category Model ---
class CategoryEditHistory {
  final String editedBy; // 'admin' or 'ca'
  final DateTime timestamp;
  final String name;
  CategoryEditHistory({required this.editedBy, required this.timestamp, required this.name});
}

class Category {
  final String id;
  String name;
  String lastEditedBy; // 'admin' or 'ca'
  DateTime lastEditedAt;
  List<CategoryEditHistory> history;
  Category({
    required this.id,
    required this.name,
    required this.lastEditedBy,
    required this.lastEditedAt,
    required this.history,
  });
}

// --- Category Provider ---
class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  List<Category> get categories => List.unmodifiable(_categories);

  CategoryProvider() {
    FirebaseFirestore.instance
        .collection('categories')
        .orderBy('lastEditedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _categories
        ..clear()
        ..addAll(snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final List history = (data['history'] as List?) ?? [];
          return Category(
            id: d.id,
            name: (data['name'] ?? '') as String,
            lastEditedBy: (data['lastEditedBy'] ?? '') as String,
            lastEditedAt: ((data['lastEditedAt'] as Timestamp?)?.toDate()) ?? DateTime.now(),
            history: history.map((h) => CategoryEditHistory(
              editedBy: (h['editedBy'] ?? '') as String,
              timestamp: ((h['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now(),
              name: (h['name'] ?? '') as String,
            )).toList(),
          );
        }));
      notifyListeners();
    });
  }

  void addCategory(String name, String editedBy) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final category = Category(
      id: id,
      name: name,
      lastEditedBy: editedBy,
      lastEditedAt: now,
      history: [CategoryEditHistory(editedBy: editedBy, timestamp: now, name: name)],
    );
    _categories.add(category);
    notifyListeners();
    FirebaseFirestore.instance.collection('categories').doc(id).set({
      'name': name,
      'lastEditedBy': editedBy,
      'lastEditedAt': FieldValue.serverTimestamp(),
      'history': [
        {
          'editedBy': editedBy,
          'timestamp': FieldValue.serverTimestamp(),
          'name': name,
        }
      ],
    });
  }

  void editCategory(String id, String newName, String editedBy) {
    final cat = _categories.firstWhere((c) => c.id == id);
    cat.name = newName;
    cat.lastEditedBy = editedBy;
    cat.lastEditedAt = DateTime.now();
    cat.history.add(CategoryEditHistory(editedBy: editedBy, timestamp: cat.lastEditedAt, name: newName));
    notifyListeners();
    FirebaseFirestore.instance.collection('categories').doc(id).update({
      'name': newName,
      'lastEditedBy': editedBy,
      'lastEditedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        {
          'editedBy': editedBy,
          'timestamp': FieldValue.serverTimestamp(),
          'name': newName,
        }
      ]),
    });
  }

  void deleteCategoryById(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    FirebaseFirestore.instance.collection('categories').doc(id).delete();
  }
}

// --- Category Management Screen ---
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Category Management')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categoryProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = categoryProvider.categories[index];
                return ListTile(
                  title: Text(cat.name),
                  subtitle: Text('ID: ${cat.id}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      categoryProvider.deleteCategoryById(cat.id);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CategoryAddDialog(editedBy: 'admin'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
          validator: (val) => val == null || val.isEmpty ? 'Enter category name' : null,
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
              Provider.of<CategoryProvider>(context, listen: false).addCategory(_name, widget.editedBy);
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
  const CategoryEditDialog({required this.category, required this.editedBy, super.key});
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
          validator: (val) => val == null || val.isEmpty ? 'Enter category name' : null,
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
              Provider.of<CategoryProvider>(context, listen: false).editCategory(widget.category.id, _name, widget.editedBy);
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

// --- Show Categories on CA Dashboard ---
class CADashboard extends StatelessWidget {
  const CADashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CA Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('CA Details'),
            onTap: () => Navigator.pushNamed(context, '/ca_details'),
          ),
          ListTile(
            title: const Text('Income/Expense Viewer'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeExpenseManagerScreen()),
            ),
          ),
          ListTile(
            title: const Text('Income Management'),
            onTap: () => Navigator.pushNamed(context, '/income_management'),
          ),
          ListTile(
            title: const Text('Expense Management'),
            onTap: () => Navigator.pushNamed(context, '/expense_management'),
          ),
          ListTile(
            title: const Text('Tax Summary'),
            onTap: () => Navigator.pushNamed(context, '/tax_summary'),
          ),
          ListTile(
            title: const Text('Bank Statements'),
            onTap: () => Navigator.pushNamed(context, '/bank_statements'),
          ),
        ],
      ),
    );
  }
}

// --- Expense Model ---
class ExpenseEditHistory {
  final double amount;
  final double cgst;
  final double sgst;
  final String invoiceNumber;
  final String editedBy;
  final DateTime timestamp;
  ExpenseEditHistory({
    required this.amount,
    required this.cgst,
    required this.sgst,
    required this.invoiceNumber,
    required this.editedBy,
    required this.timestamp,
  });
}

class Expense {
  final String id;
  String categoryId;
  double amount;
  double cgst;
  double sgst;
  String invoiceNumber;
  DateTime date;
  String addedBy;
  String bankAccount;
  List<ExpenseEditHistory> history;
  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.cgst,
    required this.sgst,
    required this.invoiceNumber,
    required this.date,
    required this.addedBy,
    required this.bankAccount,
    required this.history,
  });
  double get totalGst => (cgst + sgst) * amount / 100;
}

// --- Income Model ---
class IncomeEditHistory {
  final double amount;
  final String editedBy;
  final DateTime timestamp;
  IncomeEditHistory({
    required this.amount,
    required this.editedBy,
    required this.timestamp,
  });
}

class Income {
  final String id;
  double amount;
  DateTime date;
  String addedBy;
  List<IncomeEditHistory> history;
  Income({
    required this.id,
    required this.amount,
    required this.date,
    required this.addedBy,
    required this.history,
  });
}

// --- Expense Provider ---
class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  ExpenseProvider() {
    FirebaseFirestore.instance
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _expenses
        ..clear()
        ..addAll(snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final List history = (data['history'] as List?) ?? [];
          return Expense(
            id: d.id,
            categoryId: (data['categoryId'] ?? '') as String,
            amount: (data['amount'] ?? 0).toDouble(),
            cgst: (data['cgst'] ?? 0).toDouble(),
            sgst: (data['sgst'] ?? 0).toDouble(),
            invoiceNumber: (data['invoiceNumber'] ?? '') as String,
            date: ((data['date'] as Timestamp?)?.toDate()) ?? DateTime.now(),
            addedBy: (data['addedBy'] ?? '') as String,
            bankAccount: (data['bankAccount'] ?? 'Cash') as String,
            history: history.map((h) => ExpenseEditHistory(
              amount: (h['amount'] ?? 0).toDouble(),
              cgst: (h['cgst'] ?? 0).toDouble(),
              sgst: (h['sgst'] ?? 0).toDouble(),
              invoiceNumber: (h['invoiceNumber'] ?? '') as String,
              editedBy: (h['editedBy'] ?? '') as String,
              timestamp: ((h['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now(),
            )).toList(),
          );
        }));
      notifyListeners();
    });
  }

  void addExpense({
    required String categoryId,
    required double amount,
    required double cgst,
    required double sgst,
    required String invoiceNumber,
    required DateTime date,
    required String addedBy,
    required String bankAccount,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final expense = Expense(
      id: id,
      categoryId: categoryId,
      amount: amount,
      cgst: cgst,
      sgst: sgst,
      invoiceNumber: invoiceNumber,
      date: date,
      addedBy: addedBy,
      bankAccount: bankAccount,
      history: [ExpenseEditHistory(
        amount: amount,
        cgst: cgst,
        sgst: sgst,
        invoiceNumber: invoiceNumber,
        editedBy: addedBy,
        timestamp: now,
      )],
    );
    _expenses.add(expense);
    notifyListeners();
    FirebaseFirestore.instance.collection('expenses').doc(id).set({
      'categoryId': categoryId,
      'amount': amount,
      'cgst': cgst,
      'sgst': sgst,
      'invoiceNumber': invoiceNumber,
      'date': Timestamp.fromDate(date),
      'addedBy': addedBy,
      'bankAccount': bankAccount,
      'history': [
        {
          'amount': amount,
          'cgst': cgst,
          'sgst': sgst,
          'invoiceNumber': invoiceNumber,
          'editedBy': addedBy,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
    });
  }

  void editExpense(String id, double amount, double cgst, double sgst, String invoiceNumber, String editedBy, String bankAccount) {
    final exp = _expenses.firstWhere((e) => e.id == id);
    exp.amount = amount;
    exp.cgst = cgst;
    exp.sgst = sgst;
    exp.invoiceNumber = invoiceNumber;
    exp.bankAccount = bankAccount;
    exp.history.add(ExpenseEditHistory(
      amount: amount,
      cgst: cgst,
      sgst: sgst,
      invoiceNumber: invoiceNumber,
      editedBy: editedBy,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    FirebaseFirestore.instance.collection('expenses').doc(id).update({
      'amount': amount,
      'cgst': cgst,
      'sgst': sgst,
      'invoiceNumber': invoiceNumber,
      'bankAccount': bankAccount,
      'history': FieldValue.arrayUnion([
        {
          'amount': amount,
          'cgst': cgst,
          'sgst': sgst,
          'invoiceNumber': invoiceNumber,
          'editedBy': editedBy,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
    });
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    FirebaseFirestore.instance.collection('expenses').doc(id).delete();
  }

  double get totalGst => _expenses.fold(0, (sum, e) => sum + e.totalGst);
  double get totalExpense => _expenses.fold(0, (sum, e) => sum + e.amount);
}

// --- Income Provider ---
class IncomeProvider extends ChangeNotifier {
  final List<Income> _incomes = [];
  List<Income> get incomes => List.unmodifiable(_incomes);

  IncomeProvider() {
    FirebaseFirestore.instance
        .collection('incomes')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _incomes
        ..clear()
        ..addAll(snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final List history = (data['history'] as List?) ?? [];
          return Income(
            id: d.id,
            amount: (data['amount'] ?? 0).toDouble(),
            date: ((data['date'] as Timestamp?)?.toDate()) ?? DateTime.now(),
            addedBy: (data['addedBy'] ?? '') as String,
            history: history.map((h) => IncomeEditHistory(
              amount: (h['amount'] ?? 0).toDouble(),
              editedBy: (h['editedBy'] ?? '') as String,
              timestamp: ((h['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now(),
            )).toList(),
          );
        }));
      notifyListeners();
    });
  }

  void addIncome({
    required double amount,
    required DateTime date,
    required String addedBy,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final income = Income(
      id: id,
      amount: amount,
      date: date,
      addedBy: addedBy,
      history: [IncomeEditHistory(
        amount: amount,
        editedBy: addedBy,
        timestamp: now,
      )],
    );
    _incomes.add(income);
    notifyListeners();
    FirebaseFirestore.instance.collection('incomes').doc(id).set({
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'addedBy': addedBy,
      'history': [
        {
          'amount': amount,
          'editedBy': addedBy,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
    });
  }

  void editIncome(String id, double amount, String editedBy) {
    final inc = _incomes.firstWhere((i) => i.id == id);
    inc.amount = amount;
    inc.history.add(IncomeEditHistory(
      amount: amount,
      editedBy: editedBy,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    FirebaseFirestore.instance.collection('incomes').doc(id).update({
      'amount': amount,
      'history': FieldValue.arrayUnion([
        {
          'amount': amount,
          'editedBy': editedBy,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
    });
  }

  void deleteIncome(String id) {
    _incomes.removeWhere((i) => i.id == id);
    notifyListeners();
    FirebaseFirestore.instance.collection('incomes').doc(id).delete();
  }

  double get totalIncome => _incomes.fold(0, (sum, i) => sum + i.amount);
}

// --- Income/Expense Manager Page ---
class IncomeExpenseManagerScreen extends StatefulWidget {
  const IncomeExpenseManagerScreen({super.key});
  @override
  State<IncomeExpenseManagerScreen> createState() => _IncomeExpenseManagerScreenState();
}

class _IncomeExpenseManagerScreenState extends State<IncomeExpenseManagerScreen> {
  final DateFormat _dt = DateFormat('yyyy-MM-dd HH:mm');
  DateTime? _startDate;
  DateTime? _endDate;
  bool _newestFirst = true;
  bool _showIncomes = true;
  bool _showExpenses = true;
  String _bankFilter = 'All';

  String _formatDate(DateTime d) => _dt.format(d.toLocal());

  bool _inRange(DateTime d) {
    if (_startDate != null && d.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) return false;
    if (_endDate != null && d.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final allIncomes = incomeProvider.incomes.where((i) => _inRange(i.date)).toList()
      ..sort((a, b) => _newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date));

    final allExpenses = expenseProvider.expenses.where((e) => _inRange(e.date)).toList()
      ..sort((a, b) => _newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date));

    final bankAccounts = <String>{'All', ...allExpenses.map((e) => e.bankAccount)}.toList()..sort();

    final incomes = allIncomes; // no bank filter for incomes
    final expenses = allExpenses.where((e) => _bankFilter == 'All' || e.bankAccount == _bankFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Income/Expense Viewer')),
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
                    label: Text(_startDate == null ? 'Start date' : 'Start: ${_formatDate(_startDate!)}'),
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
                    label: Text(_endDate == null ? 'End date' : 'End: ${_formatDate(_endDate!)}'),
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
                    onPressed: () => setState(() { _startDate = null; _endDate = null; }),
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
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Incomes')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Expenses')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _bankFilter,
                    items: bankAccounts.map((b) => DropdownMenuItem(value: b, child: Text('Bank: $b'))).toList(),
                    onChanged: (val) => setState(() => _bankFilter = val ?? 'All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_showIncomes) ...[
                const Text('Incomes', style: TextStyle(fontWeight: FontWeight.bold)),
                ...incomes.map((inc) => ListTile(
                      title: Text('Amount: ₹${inc.amount.toStringAsFixed(2)}'),
                      subtitle: Text('Date: ${_formatDate(inc.date)}'),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => IncomeHistoryDialog(income: inc),
                      ),
                    )),
                const Divider(),
              ],
              if (_showExpenses) ...[
                const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                ...expenses.map((exp) {
                  final catName = categoryProvider.categories.firstWhere(
                    (c) => c.id == exp.categoryId,
                    orElse: () => Category(
                      id: '', name: 'Deleted', lastEditedBy: '', lastEditedAt: DateTime.now(), history: [],
                    ),
                  ).name;
                  return ListTile(
                    title: Text('Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.totalGst.toStringAsFixed(2)}'),
                    subtitle: Text('Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.bankAccount}\nDate: ${_formatDate(exp.date)}'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ExpenseHistoryDialog(expense: exp, categoryProvider: categoryProvider),
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

// --- Add/Edit Dialogs and History Dialogs for Income/Expense ---
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
              validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date'),
              readOnly: true,
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
              Provider.of<IncomeProvider>(context, listen: false).addIncome(amount: _amount, date: _date, addedBy: widget.addedBy);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class IncomeEditDialog extends StatefulWidget {
  final Income income;
  final String editedBy;
  const IncomeEditDialog({required this.income, required this.editedBy, super.key});
  @override
  State<IncomeEditDialog> createState() => _IncomeEditDialogState();
}

class _IncomeEditDialogState extends State<IncomeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount = widget.income.amount;
    _date = widget.income.date;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Income'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
              validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date'),
              readOnly: true,
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
              Provider.of<IncomeProvider>(context, listen: false).editIncome(widget.income.id, _amount, widget.editedBy);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

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
              subtitle: Text('By: ${h.editedBy} at ${dt.format(h.timestamp.toLocal())}'),
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
                    .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
                    .toList(),
                onChanged: (val) => setState(() => _categoryId = val),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (val) => val == null ? 'Select category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _amount = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CGST %'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _cgst = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter CGST %' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'SGST %'),
                keyboardType: TextInputType.number,
                onChanged: (val) => _sgst = double.tryParse(val) ?? 0,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter SGST %' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter invoice number' : null,
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
                onChanged: (val) => setState(() => _bankAccount = val ?? 'Cash'),
                decoration: const InputDecoration(labelText: 'Bank Account'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                controller: TextEditingController(text: _date.toLocal().toString().split(' ').first),
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

class ExpenseEditDialog extends StatefulWidget {
  final Expense expense;
  final String editedBy;
  const ExpenseEditDialog({required this.expense, required this.editedBy, super.key});
  @override
  State<ExpenseEditDialog> createState() => _ExpenseEditDialogState();
}

class _ExpenseEditDialogState extends State<ExpenseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  String _categoryId = '';
  double _amount = 0.0;
  double _cgst = 0.0;
  double _sgst = 0.0;
  String _invoiceNumber = '';
  String _bankAccount = 'Cash';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.expense.categoryId;
    _amount = widget.expense.amount;
    _cgst = widget.expense.cgst;
    _sgst = widget.expense.sgst;
    _invoiceNumber = widget.expense.invoiceNumber;
    _date = widget.expense.date;
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
                  const DropdownMenuItem(value: '', child: Text('Select a category')),
                  ...categoryProvider.categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))),
                ],
                onChanged: (val) => setState(() => _categoryId = val ?? ''),
                validator: (val) => val == null || val.isEmpty ? 'Select a category' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                initialValue: _amount.toString(),
                onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
                validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CGST (%)'),
                keyboardType: TextInputType.number,
                initialValue: _cgst.toString(),
                onChanged: (val) => _cgst = double.tryParse(val) ?? 0.0,
                validator: (val) => val == null || val.isEmpty ? 'Enter CGST' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'SGST (%)'),
                keyboardType: TextInputType.number,
                initialValue: _sgst.toString(),
                onChanged: (val) => _sgst = double.tryParse(val) ?? 0.0,
                validator: (val) => val == null || val.isEmpty ? 'Enter SGST' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                initialValue: _invoiceNumber,
                onChanged: (val) => _invoiceNumber = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter invoice number' : null,
              ),
              DropdownButtonFormField<String>(
                value: _bankAccount,
                items: [
                  const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  const DropdownMenuItem(value: 'Bank1', child: Text('Bank1')),
                  const DropdownMenuItem(value: 'Bank2', child: Text('Bank2')),
                  const DropdownMenuItem(value: 'Bank3', child: Text('Bank3')),
                  const DropdownMenuItem(value: 'Bank4', child: Text('Bank4')),
                  const DropdownMenuItem(value: 'Bank5', child: Text('Bank5')),
                ],
                onChanged: (val) => setState(() => _bankAccount = val ?? 'Cash'),
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

class ExpenseHistoryDialog extends StatelessWidget {
  final Expense expense;
  final CategoryProvider categoryProvider;
  const ExpenseHistoryDialog({required this.expense, required this.categoryProvider, super.key});
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
              title: Text('Amount: ${h.amount.toStringAsFixed(2)} | CGST: ${h.cgst.toStringAsFixed(2)} | SGST: ${h.sgst.toStringAsFixed(2)} | Invoice: ${h.invoiceNumber}'),
              subtitle: Text('By: ${h.editedBy} at ${dt.format(h.timestamp.toLocal())} | Bank: ${expense.bankAccount}'),
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

// --- Tax Summary Widget ---
class TaxSummaryWidget extends StatelessWidget {
  const TaxSummaryWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final totalIncome = incomeProvider.totalIncome;
    final totalExpense = expenseProvider.totalExpense;
    final totalGstPaid = expenseProvider.totalGst;

    final isLoss = totalExpense > totalIncome;
    final profitOrLoss = totalIncome - totalExpense; // negative => loss

    final totalIncomeTax = _calculateIncomeTax(totalIncome);
    final payableTaxValue = (totalIncomeTax - totalGstPaid);
    final payableTaxClamped = payableTaxValue.clamp(0, double.infinity);
    final taxCategory = _getTaxCategory(totalIncome);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tax Summary', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Total Income: ₹${totalIncome.toStringAsFixed(2)}'),
          Text('Total Expense: ₹${totalExpense.toStringAsFixed(2)}'),
          Text(profitOrLoss >= 0
              ? 'Profit: ₹${profitOrLoss.toStringAsFixed(2)}'
              : 'Loss: ₹${(-profitOrLoss).toStringAsFixed(2)}'),
          Text('Total Income Tax (slab): ₹${totalIncomeTax.toStringAsFixed(2)}'),
            Text(
            isLoss
                ? 'Total Expense GST Paid: -₹${totalGstPaid.toStringAsFixed(2)}'
                : 'Total Expense GST Paid: ₹${totalGstPaid.toStringAsFixed(2)}',
          ),
          if (isLoss)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Expense greater than Income',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your expenses are more than your income till now. Try to increase your income otherwise your company will be at a loss. It is not possible to calculate GST on negative income. Payable tax is not applicable while in loss; GST paid will be treated as credit for future adjustment.',
            ),
          ],
        ),
      ),
                ],
              ),
            ),
          Text(
            isLoss
                ? 'Payable Tax: N/A (in loss)'
                : 'Payable Tax: ₹${payableTaxClamped.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Income Tax Slab: $taxCategory'),
        ],
      ),
    );
  }

  double _calculateIncomeTax(double income) {
    if (income <= 400000) return 0;
    if (income <= 800000) return (income - 400000) * 0.05;
    if (income <= 1200000) return 20000 + (income - 800000) * 0.10;
    if (income <= 1800000) return 60000 + (income - 1200000) * 0.15;
    return 150000 + (income - 1800000) * 0.30;
  }

  String _getTaxCategory(double income) {
    if (income <= 400000) return '0% (Up to ₹4,00,000)';
    if (income <= 800000) return '5% (₹4,00,001 – ₹8,00,000)';
    if (income <= 1200000) return '10% (₹8,00,001 – ₹12,00,000)';
    if (income <= 1800000) return '15% (₹12,00,001 – ₹18,00,000)';
    return '30% (Above ₹18,00,000)';
  }
}

// --- Placeholder Screens ---
class IncomeManagementScreen extends StatelessWidget {
  const IncomeManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = incomeProvider.incomes.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Income Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => IncomeAddDialog(addedBy: auth.role ?? 'admin'),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: incomeProvider.incomes.length,
                    itemBuilder: (context, index) {
                      final inc = incomeProvider.incomes[index];
                      return ListTile(
                        title: Text('Amount: ₹${inc.amount.toStringAsFixed(2)}'),
                        subtitle: Text('Date: ${dt.format(inc.date.toLocal())}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => IncomeHistoryDialog(income: inc),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => IncomeEditDialog(income: inc, editedBy: auth.role ?? 'admin'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => incomeProvider.deleteIncome(inc.id),
                            ),
                          ],
                        ),
                      );
                    },
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
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => IncomeAddDialog(addedBy: auth.role ?? 'admin'),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                  ),
                ],
              ),
            ),
    );
  }
}

class ExpenseManagementScreen extends StatelessWidget {
  const ExpenseManagementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = expenseProvider.expenses.isNotEmpty;
    final dt = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => ExpenseAddDialog(addedBy: auth.role ?? 'admin'),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                    itemBuilder: (context, index) {
                      final exp = expenseProvider.expenses[index];
                      final catName = categoryProvider.categories.firstWhere(
                        (c) => c.id == exp.categoryId,
                        orElse: () => Category(
                          id: '',
                          name: 'Deleted',
                          lastEditedBy: '',
                          lastEditedAt: DateTime.now(),
                          history: [],
                        ),
                      ).name;
                      return ListTile(
                        title: Text('Amount: ₹${exp.amount.toStringAsFixed(2)} | GST: ₹${exp.totalGst.toStringAsFixed(2)}'),
                        subtitle: Text('Category: $catName\nInvoice: ${exp.invoiceNumber}\nBank: ${exp.bankAccount}\nDate: ${dt.format(exp.date.toLocal())}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExpenseHistoryDialog(expense: exp, categoryProvider: categoryProvider),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExpenseEditDialog(expense: exp, editedBy: auth.role ?? 'admin'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => expenseProvider.deleteExpense(exp.id),
                            ),
                          ],
                        ),
                      );
                    },
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
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ExpenseAddDialog(addedBy: auth.role ?? 'admin'),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
    );
  }
}

class TaxSummaryScreen extends StatelessWidget {
  const TaxSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen('Tax Summary');
}

class BankStatementsScreen extends StatelessWidget {
  const BankStatementsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen('Bank Statements');
}

class RequestStatementScreen extends StatelessWidget {
  const RequestStatementScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen('Request Statement');
}

class CommentModalScreen extends StatelessWidget {
  const CommentModalScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen('Comment Modal');
}

// --- Documents (Passbook & Uploads) ---
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload({required String category}) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      setState(() => _uploading = true);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = file.name;
      final storagePath = 'documents/$uid/$category/$fileName';
      final ref = FirebaseStorage.instance.ref(storagePath);
      final metadata = SettableMetadata(contentType: file.extension == 'pdf' ? 'application/pdf' : null);
      if (file.bytes == null) throw Exception('No file bytes available');
      await ref.putData(file.bytes!, metadata);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('documents').add({
        'uid': uid,
        'category': category,
        'name': fileName,
        'path': storagePath,
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Documents & Passbook')),
      floatingActionButton: _uploading
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'upload_passbook',
                  onPressed: () => _pickAndUpload(category: 'passbook'),
                  icon: const Icon(Icons.book),
                  label: const Text('Upload Passbook'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'upload_doc',
                  onPressed: () => _pickAndUpload(category: 'other'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                ),
              ],
            ),
      body: uid == null
          ? const Center(child: Text('Login required'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_uploading)
                  const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('documents')
                        .where('uid', isEqualTo: uid)
                        .orderBy('uploadedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('No documents uploaded yet.'));
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final d = docs[index].data();
                          return ListTile(
                            leading: Icon(d['category'] == 'passbook' ? Icons.book : Icons.insert_drive_file),
                            title: Text(d['name'] ?? 'Unnamed'),
                            subtitle: Text('${d['category']} • ${d['path']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final path = d['path'] as String?;
                                if (path != null) {
                                  await FirebaseStorage.instance.ref(path).delete().catchError((_) {});
                                }
                                await docs[index].reference.delete();
                              },
                            ),
                            onTap: () => _openUrl(d['url'] as String?),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _openUrl(String? url) {
    if (url == null) return;
    // Flutter web can open by using `dart:html`, but to keep cross-platform simple we just show a snackbar with URL.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL: $url')));
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Page', style: const TextStyle(fontSize: 24))),
    );
  }
}
