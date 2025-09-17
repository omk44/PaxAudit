// screens/placeholder_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/bank_statement_provider.dart';
import '../models/bank_statement.dart';
import '../widgets/tax_summary_widget.dart';
import '../widgets/dialogs/bank_statement_dialogs.dart';

class TaxSummaryScreen extends StatelessWidget {
  const TaxSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.receipt_long_rounded),
            SizedBox(width: 8),
            Text('Tax Summary'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [TaxSummaryWidget()],
          ),
        ),
      ),
    );
  }
}

class BankStatementsScreen extends StatefulWidget {
  const BankStatementsScreen({super.key});

  @override
  State<BankStatementsScreen> createState() => _BankStatementsScreenState();
}

class _BankStatementsScreenState extends State<BankStatementsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final companyId = auth.companyId ?? auth.selectedCompany?.id;
      if (companyId != null) {
        await Provider.of<BankStatementProvider>(
          context,
          listen: false,
        ).loadBankStatementsForCompany(companyId);
      }
    });
  }

  Future<void> _addOrEditLink({BankStatement? existing}) async {
    await showDialog(
      context: context,
      builder: (_) => BankStatementLinkDialog(existing: existing),
    );
  }

  Future<void> _caReview(BankStatement bankStatement) async {
    await showDialog(
      context: context,
      builder: (_) => BankStatementCAReviewDialog(bankStatement: bankStatement),
    );
  }

  Future<void> _adminFinalReview(BankStatement bankStatement) async {
    await showDialog(
      context: context,
      builder: (_) => BankStatementAdminFinalReviewDialog(bankStatement: bankStatement),
    );
  }

  Future<void> _openPdf(String url) async {
    try {
      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid URL format'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankStatementProvider = Provider.of<BankStatementProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hasData = bankStatementProvider.bankStatements.isNotEmpty;

    // Load data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final companyId = auth.companyId ?? auth.selectedCompany?.id;
      if (companyId != null && bankStatementProvider.bankStatements.isEmpty && !bankStatementProvider.isLoading) {
        await bankStatementProvider.loadBankStatementsForCompany(companyId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.account_balance_rounded),
            SizedBox(width: 8),
            Text('Bank Statements'),
          ],
        ),
        actions: [
          if (auth.role == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.add_link),
              onPressed: () => _addOrEditLink(),
              tooltip: 'Add Statement Link (Admin)',
            ),
          ],
        ],
      ),
      floatingActionButton: auth.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditLink(),
              icon: const Icon(Icons.add_link),
              label: const Text('Add Link'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
      body: hasData
          ? Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final companyId =
                          auth.companyId ?? auth.selectedCompany?.id;
                      if (companyId != null) {
                        await Provider.of<BankStatementProvider>(
                          context,
                          listen: false,
                        ).loadBankStatementsForCompany(companyId);
                      }
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: bankStatementProvider.bankStatements.length,
                      itemBuilder: (context, index) {
                        final bankStatement =
                            bankStatementProvider.bankStatements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: bankStatement.status.color.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: bankStatement.status.color,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  bankStatement.status.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(
                              bankStatement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Bank: ${bankStatement.bankName}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Range: ${_formatShortDate(bankStatement.statementStartDate)} - ${_formatShortDate(bankStatement.statementEndDate)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: bankStatement.status.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ${bankStatement.status.displayName}',
                                      style: TextStyle(
                                        color: bankStatement.status.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created: ${_formatDate(bankStatement.createdAt)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'By: ${bankStatement.uploadedBy}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (bankStatement.caComments != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.comment,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'CA: ${bankStatement.caComments}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (bankStatement.adminComments != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.admin_panel_settings,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Admin: ${bankStatement.adminComments}',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _openPdf(bankStatement.linkUrl),
                                  tooltip: 'Open Link',
                                  color: Colors.blue,
                                ),
                                if (auth.role == 'admin')
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _addOrEditLink(existing: bankStatement),
                                    tooltip: 'Edit Link (Admin)',
                                    color: Colors.green,
                                  ),
                                if (auth.role == 'ca')
                                  IconButton(
                                    icon: const Icon(Icons.rate_review),
                                    onPressed: () => _caReview(bankStatement),
                                    tooltip: 'CA Review',
                                    color: Colors.orange,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.history),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => BankStatementHistoryDialog(
                                      bankStatement: bankStatement,
                                    ),
                                  ),
                                  tooltip: 'View History',
                                  color: Colors.grey,
                                ),
                                if (auth.role == 'admin')
                                  IconButton(
                                    icon: const Icon(Icons.admin_panel_settings),
                                    onPressed: () => _adminFinalReview(bankStatement),
                                    tooltip: 'Admin Final Review',
                                    color: Colors.purple,
                                  ),
                                if (auth.role == 'admin')
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _deleteBankStatement(bankStatement.id),
                                    tooltip: 'Delete',
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 72),
              ],
            )
      : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Bank Statements Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add bank statement links for CA review',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addOrEditLink(),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Add First Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _deleteBankStatement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Statement'),
        content: const Text(
          'Are you sure you want to delete this bank statement? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Provider.of<BankStatementProvider>(
        context,
        listen: false,
      ).deleteBankStatement(id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank statement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete bank statement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
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
