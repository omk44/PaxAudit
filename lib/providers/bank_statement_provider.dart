import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bank_statement.dart';
import 'notification_provider.dart';

class BankStatementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<BankStatement> _bankStatements = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCompanyId;

  List<BankStatement> get bankStatements => List.unmodifiable(_bankStatements);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load bank statements for a specific company
  Future<void> loadBankStatementsForCompany(String companyId) async {
    final switchingCompany =
        _currentCompanyId != null && _currentCompanyId != companyId;

    // Don't reload if already loading for the same company
    if (_currentCompanyId == companyId && _isLoading) {
      print(
        'Already loading bank statements for company: $companyId, skipping duplicate load',
      );
      return;
    }

    try {
      print('Loading bank statements for company: $companyId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('bank_statements')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
        'Found ${snapshot.docs.length} bank statement records for company $companyId',
      );

      // Build a fresh list from snapshot, then replace local list atomically
      final List<BankStatement> fresh = [];
      for (final doc in snapshot.docs) {
        try {
          final bankStatement = BankStatement.fromFirestore(doc);
          fresh.add(bankStatement);
        } catch (e) {
          print('Error parsing bank statement document ${doc.id}: $e');
          // Skip invalid documents
        }
      }

      _bankStatements
        ..clear()
        ..addAll(fresh);
      _currentCompanyId = companyId;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading bank statements for company $companyId: $e');
      _error = 'Failed to load bank statements: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin creates a new bank statement link entry
  Future<bool> createBankStatementLink({
    required String companyId,
    required String title,
    required String bankName,
    required String linkUrl,
    required DateTime statementStartDate,
    required DateTime statementEndDate,
    required String uploadedBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create bank statement record in Firestore
      final now = DateTime.now();
      final bankStatement = BankStatement(
        id: '',
        companyId: companyId,
        title: title,
        bankName: bankName,
        linkUrl: linkUrl,
        statementStartDate: statementStartDate,
        statementEndDate: statementEndDate,
        createdAt: now,
        uploadedBy: uploadedBy,
        history: [
          BankStatementHistory(
            action: 'admin_uploaded',
            performedBy: uploadedBy,
            timestamp: now,
            comments: 'Bank statement link uploaded by admin for CA review',
          ),
        ],
      );

      final docRef = await _firestore
          .collection('bank_statements')
          .add(bankStatement.toFirestore());

      // Add to local list
      final createdBankStatement = bankStatement.copyWith(id: docRef.id);
      _bankStatements.insert(0, createdBankStatement);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create bank statement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // CA reviews and updates bank statement status
  Future<bool> caReviewBankStatement({
    required String id,
    required BankStatementStatus status,
    String? caComments,
    required String updatedBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bankStatement = _bankStatements.firstWhere((bs) => bs.id == id);
      final updatedHistory = List<BankStatementHistory>.from(
        bankStatement.history,
      );

      updatedHistory.add(
        BankStatementHistory(
          action: 'ca_reviewed',
          performedBy: updatedBy,
          timestamp: DateTime.now(),
          comments: caComments ?? 'CA reviewed and updated status',
          oldValue: bankStatement.status.name,
          newValue: status.name,
        ),
      );

      final updatedBankStatement = bankStatement.copyWith(
        caComments: caComments ?? bankStatement.caComments,
        status: status,
        history: updatedHistory,
      );

      await _firestore
          .collection('bank_statements')
          .doc(id)
          .update(updatedBankStatement.toFirestore());

      // Update local list
      final index = _bankStatements.indexWhere((bs) => bs.id == id);
      if (index != -1) {
        _bankStatements[index] = updatedBankStatement;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update bank statement review: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin adds final comments after CA review
  Future<bool> adminFinalReview({
    required String id,
    String? adminComments,
    required String updatedBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bankStatement = _bankStatements.firstWhere((bs) => bs.id == id);
      final updatedHistory = List<BankStatementHistory>.from(
        bankStatement.history,
      );

      updatedHistory.add(
        BankStatementHistory(
          action: 'admin_final_review',
          performedBy: updatedBy,
          timestamp: DateTime.now(),
          comments: adminComments ?? 'Admin final review completed',
        ),
      );

      final updatedBankStatement = bankStatement.copyWith(
        adminComments: adminComments ?? bankStatement.adminComments,
        history: updatedHistory,
      );

      await _firestore
          .collection('bank_statements')
          .doc(id)
          .update(updatedBankStatement.toFirestore());

      // Update local list
      final index = _bankStatements.indexWhere((bs) => bs.id == id);
      if (index != -1) {
        _bankStatements[index] = updatedBankStatement;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add admin final review: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> updateBankStatement({
    required String id,
    String? caComments,
    String? adminComments,
    BankStatementStatus? status,
    required String updatedBy,
    String? comments,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final bankStatement = _bankStatements.firstWhere((bs) => bs.id == id);
      final updatedHistory = List<BankStatementHistory>.from(
        bankStatement.history,
      );

      // Add history entry
      String action = 'updated';
      if (caComments != null) action = 'ca_commented';
      if (adminComments != null) action = 'admin_commented';
      if (status != null) action = 'status_changed';

      updatedHistory.add(
        BankStatementHistory(
          action: action,
          performedBy: updatedBy,
          timestamp: DateTime.now(),
          comments: comments,
          oldValue: status != null ? bankStatement.status.name : null,
          newValue: status?.name,
        ),
      );

      final updatedBankStatement = bankStatement.copyWith(
        caComments: caComments ?? bankStatement.caComments,
        adminComments: adminComments ?? bankStatement.adminComments,
        status: status ?? bankStatement.status,
        history: updatedHistory,
      );

      await _firestore
          .collection('bank_statements')
          .doc(id)
          .update(updatedBankStatement.toFirestore());

      // Update local list
      final index = _bankStatements.indexWhere((bs) => bs.id == id);
      if (index != -1) {
        _bankStatements[index] = updatedBankStatement;
      }

      // Send notification to CAs
      await _sendNotificationToCAs(
        action: action,
        companyId: bankStatement.companyId,
        performedBy: updatedBy,
        bankStatementTitle: bankStatement.title,
        bankStatementId: bankStatement.id,
        comments: comments,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update bank statement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin edits an existing bank statement link entry
  Future<bool> editBankStatementLink({
    required String id,
    required String title,
    required String bankName,
    required String linkUrl,
    required DateTime statementStartDate,
    required DateTime statementEndDate,
    required String updatedBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existing = _bankStatements.firstWhere((bs) => bs.id == id);
      final updated = existing.copyWith(
        title: title,
        bankName: bankName,
        linkUrl: linkUrl,
        statementStartDate: statementStartDate,
        statementEndDate: statementEndDate,
        history: [
          ...existing.history,
          BankStatementHistory(
            action: 'admin_updated',
            performedBy: updatedBy,
            timestamp: DateTime.now(),
            comments: 'Bank statement link updated by admin',
          ),
        ],
      );

      await _firestore
          .collection('bank_statements')
          .doc(id)
          .update(updated.toFirestore());

      final index = _bankStatements.indexWhere((bs) => bs.id == id);
      if (index != -1) _bankStatements[index] = updated;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update bank statement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete bank statement
  Future<bool> deleteBankStatement(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get bank statement details before deleting for notification
      final bankStatement = _bankStatements.firstWhere((bs) => bs.id == id);

      // Send notification to CAs before deleting
      await _sendNotificationToCAs(
        action: 'deleted',
        companyId: bankStatement.companyId,
        performedBy: 'Admin', // You might want to pass this as a parameter
        bankStatementTitle: bankStatement.title,
        bankStatementId: bankStatement.id,
      );

      // Delete from Firestore
      await _firestore.collection('bank_statements').doc(id).delete();

      // Remove from local list
      _bankStatements.removeWhere((bs) => bs.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete bank statement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to get CA emails for a company
  Future<List<String>> _getCAEmailsForCompany(String companyId) async {
    try {
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();
      if (companyDoc.exists) {
        final data = companyDoc.data() as Map<String, dynamic>;
        final caEmails = data['caEmails'] as List<dynamic>?;
        return caEmails?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      print('Error getting CA emails: $e');
      return [];
    }
  }

  // Helper method to send notifications to CAs
  Future<void> _sendNotificationToCAs({
    required String action,
    required String companyId,
    required String performedBy,
    required String bankStatementTitle,
    String? bankStatementId,
    String? comments,
  }) async {
    try {
      final caEmails = await _getCAEmailsForCompany(companyId);
      final notificationProvider = NotificationProvider();

      for (final caEmail in caEmails) {
        await notificationProvider.notifyBankStatementChange(
          action: action,
          companyId: companyId,
          caEmail: caEmail,
          performedBy: performedBy,
          bankStatementTitle: bankStatementTitle,
          bankStatementId: bankStatementId,
          comments: comments,
        );
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  // Clear all bank statements (useful for logout)
  void clearBankStatements() {
    print('Clearing all bank statement data');
    _bankStatements.clear();
    _currentCompanyId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Clear bank statements for company switch - only clear if switching to different company
  void clearBankStatementsForCompanySwitch() {
    print('Clearing bank statement data for company switch');
    _bankStatements.clear();
    _currentCompanyId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
