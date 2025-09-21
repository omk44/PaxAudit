// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/ca_provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
<<<<<<< Updated upstream
=======
import 'providers/bank_statement_provider.dart';
import 'providers/notification_provider.dart';
>>>>>>> Stashed changes
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/ca_dashboard.dart';
import 'screens/management_screens.dart';
import 'screens/ca_details_screen.dart';
import 'screens/placeholder_screens.dart';
<<<<<<< Updated upstream
=======
import 'screens/admin_profile_screen.dart';
import 'screens/notification_screen.dart';
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(const PaxAuditApp());
}

class PaxAuditApp extends StatelessWidget {
  const PaxAuditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CAProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
<<<<<<< Updated upstream
=======
        ChangeNotifierProvider(create: (_) => BankStatementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
>>>>>>> Stashed changes
      ],
      child: MaterialApp(
        title: 'PaxAudit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
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
          '/notifications': (context) => const NotificationScreen(),
        },
      ),
    );
  }
}
