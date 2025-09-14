import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_statement_provider.dart';
import '../../models/bank_statement.dart';

class BankStatementHistoryDialog extends StatelessWidget {
  final BankStatement bankStatement;

  const BankStatementHistoryDialog({super.key, required this.bankStatement});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'History: ${bankStatement.fileName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: bankStatement.history.length,
                itemBuilder: (context, index) {
                  final historyItem = bankStatement.history[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getActionColor(historyItem.action),
                        child: Icon(
                          _getActionIcon(historyItem.action),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        _getActionTitle(historyItem.action),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('By: ${historyItem.performedBy}'),
                          Text('Date: ${_formatDate(historyItem.timestamp)}'),
                          if (historyItem.comments != null)
                            Text('Comments: ${historyItem.comments}'),
                          if (historyItem.oldValue != null &&
                              historyItem.newValue != null)
                            Text(
                              'Changed from ${historyItem.oldValue} to ${historyItem.newValue}',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'uploaded':
        return Colors.blue;
      case 'ca_commented':
        return Colors.green;
      case 'admin_commented':
        return Colors.orange;
      case 'status_changed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'uploaded':
        return Icons.upload;
      case 'ca_commented':
        return Icons.comment;
      case 'admin_commented':
        return Icons.admin_panel_settings;
      case 'status_changed':
        return Icons.swap_horiz;
      default:
        return Icons.info;
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'uploaded':
        return 'Bank Statement Uploaded';
      case 'ca_commented':
        return 'CA Added Comments';
      case 'admin_commented':
        return 'Admin Added Comments';
      case 'status_changed':
        return 'Status Changed';
      default:
        return 'Action Performed';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class BankStatementCommentDialog extends StatefulWidget {
  final BankStatement bankStatement;
  final String userRole;

  const BankStatementCommentDialog({
    super.key,
    required this.bankStatement,
    required this.userRole,
  });

  @override
  State<BankStatementCommentDialog> createState() =>
      _BankStatementCommentDialogState();
}

class _BankStatementCommentDialogState
    extends State<BankStatementCommentDialog> {
  final _commentController = TextEditingController();
  BankStatementStatus? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.bankStatement.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.userRole == 'ca' ? 'CA' : 'Admin'} Comments'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userRole == 'ca') ...[
              const Text('CA Comments:'),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your comments about this bank statement...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.userRole == 'admin') ...[
              const Text('Admin Comments:'),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your comments about this bank statement...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Status:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<BankStatementStatus>(
                value: _selectedStatus,
                items: BankStatementStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text('${status.icon} ${status.displayName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveComments,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveComments() async {
    if (_commentController.text.trim().isEmpty &&
        _selectedStatus == widget.bankStatement.status) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await Provider.of<BankStatementProvider>(
            context,
            listen: false,
          ).updateBankStatement(
            id: widget.bankStatement.id,
            caComments: widget.userRole == 'ca'
                ? _commentController.text.trim()
                : null,
            adminComments: widget.userRole == 'admin'
                ? _commentController.text.trim()
                : null,
            status: _selectedStatus,
            updatedBy: widget.userRole,
            comments: _commentController.text.trim().isNotEmpty
                ? _commentController.text.trim()
                : null,
          );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comments saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save comments'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
