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
      builder: (_) =>
          BankStatementAdminFinalReviewDialog(bankStatement: bankStatement),
    );
  }

  Future<void> _openPdf(String url) async {
    try {
      print('Attempting to open URL: $url');

      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No URL provided'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Clean and validate the URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Handle Google Drive URLs specifically
      if (cleanUrl.contains('drive.google.com') &&
          !cleanUrl.contains('/view')) {
        // Convert Google Drive sharing URLs to direct view URLs
        if (cleanUrl.contains('/file/d/')) {
          final fileIdMatch = RegExp(
            r'/file/d/([a-zA-Z0-9-_]+)',
          ).firstMatch(cleanUrl);
          if (fileIdMatch != null) {
            final fileId = fileIdMatch.group(1);
            cleanUrl = 'https://drive.google.com/file/d/$fileId/view';
            print('Converted Google Drive URL to: $cleanUrl');
          }
        }
      }

      print('Cleaned URL: $cleanUrl');

      final uri = Uri.tryParse(cleanUrl);
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

      // Check if the URL can be launched
      if (await canLaunchUrl(uri)) {
        // Try different launch modes
        bool launched = false;

        // First try with external application
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('Failed to launch with external application: $e');
        }

        // If external application failed, try with platformDefault
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (e) {
            print('Failed to launch with platform default: $e');
          }
        }

        // If still failed, try with inAppWebView
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
          } catch (e) {
            print('Failed to launch with inAppWebView: $e');
          }
        }

        if (!launched) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not open link. Please check if you have a browser installed.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No app available to open this link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _openPdf: $e');
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

    // Load data if not already loaded - prevent infinite loop
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final companyId = auth.companyId ?? auth.selectedCompany?.id;
      if (companyId != null &&
          bankStatementProvider.bankStatements.isEmpty &&
          !bankStatementProvider.isLoading &&
          bankStatementProvider.error == null) {
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
          // Test URL launcher button (temporary for debugging)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _openPdf('https://www.google.com'),
            tooltip: 'Test URL Launcher',
          ),
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
      body: Column(
        children: [
          // Show error if loading failed
          if (bankStatementProvider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${bankStatementProvider.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final companyId =
                          auth.companyId ?? auth.selectedCompany?.id;
                      if (companyId != null) {
                        Provider.of<BankStatementProvider>(
                          context,
                          listen: false,
                        ).loadBankStatementsForCompany(companyId);
                      }
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: hasData
                ? RefreshIndicator(
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with status icon and title
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: bankStatement.status.color
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: bankStatement.status.color,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          bankStatement.status.icon,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bankStatement.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Bank: ${bankStatement.bankName}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Date range and status
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_formatShortDate(bankStatement.statementStartDate)} - ${_formatShortDate(bankStatement.statementEndDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bankStatement.status.color
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: bankStatement.status.color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            bankStatement.status.displayName,
                                            style: TextStyle(
                                              color: bankStatement.status.color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Created info
                                Text(
                                  'Created: ${_formatDate(bankStatement.createdAt)} by ${bankStatement.uploadedBy}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),

                                // Comments if any
                                if (bankStatement.caComments != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'CA Comments:',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bankStatement.caComments!,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (bankStatement.adminComments != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Admin Comments:',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bankStatement.adminComments!,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Action buttons
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        print(
                                          'Bank statement linkUrl: ${bankStatement.linkUrl}',
                                        );
                                        _openPdf(bankStatement.linkUrl);
                                      },
                                      tooltip: 'Open Link',
                                      color: Colors.blue,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                    if (auth.role == 'admin')
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _addOrEditLink(
                                          existing: bankStatement,
                                        ),
                                        tooltip: 'Edit Link',
                                        color: Colors.green,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    if (auth.role == 'ca')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.rate_review,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _caReview(bankStatement),
                                        tooltip: 'CA Review',
                                        color: Colors.orange,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.history, size: 20),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) =>
                                            BankStatementHistoryDialog(
                                              bankStatement: bankStatement,
                                            ),
                                      ),
                                      tooltip: 'View History',
                                      color: Colors.grey,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                    if (auth.role == 'admin')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.admin_panel_settings,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _adminFinalReview(bankStatement),
                                        tooltip: 'Admin Review',
                                        color: Colors.purple,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    if (auth.role == 'admin')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteBankStatement(
                                          bankStatement.id,
                                        ),
                                        tooltip: 'Delete',
                                        color: Colors.red,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
          ),
        ],
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
