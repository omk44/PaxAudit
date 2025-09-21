import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_statement_provider.dart';
import '../../models/bank_statement.dart';
import '../../providers/auth_provider.dart';

class BankStatementLinkDialog extends StatefulWidget {
  final BankStatement? existing;
  const BankStatementLinkDialog({super.key, this.existing});

  @override
  State<BankStatementLinkDialog> createState() => _BankStatementLinkDialogState();
}

class _BankStatementLinkDialogState extends State<BankStatementLinkDialog> {
  final _titleController = TextEditingController();
  final _bankController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _titleController.text = ex.title;
      _bankController.text = ex.bankName;
      _linkController.text = ex.linkUrl;
      _startDate = ex.statementStartDate;
      _endDate = ex.statementEndDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Statement Link' : 'Edit Statement Link'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., April 2025 Statement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'e.g., HDFC Bank',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Drive Link URL',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.date_range),
                    label: Text(_startDate == null
                        ? 'Start Date'
                        : _formatDate(_startDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event),
                    label:
                        Text(_endDate == null ? 'End Date' : _formatDate(_endDate!)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final first = DateTime(2010);
    final last = DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final bank = _bankController.text.trim();
    final link = _linkController.text.trim();
    if (title.isEmpty || bank.isEmpty || link.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = Provider.of<BankStatementProvider>(context, listen: false);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final companyId = auth.companyId ?? auth.selectedCompany?.id;
      final user = auth.role ?? 'admin';
      if (companyId == null) throw Exception('No company selected');

      bool ok;
      if (widget.existing == null) {
        ok = await provider.createBankStatementLink(
          companyId: companyId,
          title: title,
          bankName: bank,
          linkUrl: link,
          statementStartDate: _startDate!,
          statementEndDate: _endDate!,
          uploadedBy: user,
        );
      } else {
        ok = await provider.editBankStatementLink(
          id: widget.existing!.id,
          title: title,
          bankName: bank,
          linkUrl: link,
          statementStartDate: _startDate!,
          statementEndDate: _endDate!,
          updatedBy: user,
        );
      }

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  void dispose() {
    _titleController.dispose();
    _bankController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}

class BankStatementCAReviewDialog extends StatefulWidget {
  final BankStatement bankStatement;
  const BankStatementCAReviewDialog({super.key, required this.bankStatement});

  @override
  State<BankStatementCAReviewDialog> createState() => _BankStatementCAReviewDialogState();
}

class _BankStatementCAReviewDialogState extends State<BankStatementCAReviewDialog> {
  final _commentController = TextEditingController();
  BankStatementStatus? _selectedStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Ensure the current status is valid for CA review
    final currentStatus = widget.bankStatement.status;
    final validStatuses = [
      BankStatementStatus.uploaded,
      BankStatementStatus.underReview,
      BankStatementStatus.matched,
      BankStatementStatus.partiallyMatched,
      BankStatementStatus.needsClarification,
      BankStatementStatus.approved,
      BankStatementStatus.rejected,
      BankStatementStatus.needsRevision,
    ];
    
    _selectedStatus = validStatuses.contains(currentStatus) 
        ? currentStatus 
        : BankStatementStatus.underReview;
    _commentController.text = widget.bankStatement.caComments ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CA Review - Cross Match Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statement: ${widget.bankStatement.title}'),
            Text('Bank: ${widget.bankStatement.bankName}'),
            Text('Period: ${_formatDate(widget.bankStatement.statementStartDate)} - ${_formatDate(widget.bankStatement.statementEndDate)}'),
            const SizedBox(height: 16),
            const Text('Review Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<BankStatementStatus>(
              value: _selectedStatus,
              items: [
                BankStatementStatus.uploaded,
                BankStatementStatus.underReview,
                BankStatementStatus.matched,
                BankStatementStatus.partiallyMatched,
                BankStatementStatus.needsClarification,
                BankStatementStatus.approved,
                BankStatementStatus.rejected,
                BankStatementStatus.needsRevision,
              ].map((status) {
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
            const SizedBox(height: 16),
            const Text('CA Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add your review comments about cross-matching with transactions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Review'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedStatus == null) return;
    
    setState(() => _saving = true);
    final provider = Provider.of<BankStatementProvider>(context, listen: false);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.role ?? 'ca';

      final ok = await provider.caReviewBankStatement(
        id: widget.bankStatement.id,
        status: _selectedStatus!,
        caComments: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        updatedBy: user,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CA review saved successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save review'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class BankStatementAdminFinalReviewDialog extends StatefulWidget {
  final BankStatement bankStatement;
  const BankStatementAdminFinalReviewDialog({super.key, required this.bankStatement});

  @override
  State<BankStatementAdminFinalReviewDialog> createState() => _BankStatementAdminFinalReviewDialogState();
}

class _BankStatementAdminFinalReviewDialogState extends State<BankStatementAdminFinalReviewDialog> {
  final _commentController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.bankStatement.adminComments ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Admin Final Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statement: ${widget.bankStatement.title}'),
            Text('Bank: ${widget.bankStatement.bankName}'),
            Text('CA Status: ${widget.bankStatement.status.displayName}'),
            if (widget.bankStatement.caComments != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CA Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.bankStatement.caComments!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Admin Final Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add your final admin comments...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Final Review'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = Provider.of<BankStatementProvider>(context, listen: false);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.role ?? 'admin';

      final ok = await provider.adminFinalReview(
        id: widget.bankStatement.id,
        adminComments: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        updatedBy: user,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin final review saved successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save final review'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

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
                    'History: ${bankStatement.title}',
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
      case 'admin_uploaded':
        return Colors.blue;
      case 'admin_updated':
        return Colors.blue.shade700;
      case 'ca_reviewed':
        return Colors.green;
      case 'admin_final_review':
        return Colors.purple;
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
      case 'admin_uploaded':
        return Icons.upload;
      case 'admin_updated':
        return Icons.edit;
      case 'ca_reviewed':
        return Icons.rate_review;
      case 'admin_final_review':
        return Icons.admin_panel_settings;
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
      case 'admin_uploaded':
        return 'Admin Uploaded Statement';
      case 'admin_updated':
        return 'Admin Updated Statement';
      case 'ca_reviewed':
        return 'CA Reviewed & Updated Status';
      case 'admin_final_review':
        return 'Admin Final Review';
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
                items: [
                  BankStatementStatus.uploaded,
                  BankStatementStatus.underReview,
                  BankStatementStatus.matched,
                  BankStatementStatus.partiallyMatched,
                  BankStatementStatus.needsClarification,
                  BankStatementStatus.approved,
                  BankStatementStatus.rejected,
                  BankStatementStatus.needsRevision,
                ].map((status) {
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
