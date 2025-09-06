// screens/placeholder_screens.dart
import 'package:flutter/material.dart';

class TaxSummaryScreen extends StatelessWidget {
  const TaxSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen('Tax Summary');
}

class BankStatementsScreen extends StatelessWidget {
  const BankStatementsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen('Bank Statements');
}

class RequestStatementScreen extends StatelessWidget {
  const RequestStatementScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen('Request Statement');
}

class CommentModalScreen extends StatelessWidget {
  const CommentModalScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen('Comment Modal');
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title Page', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
