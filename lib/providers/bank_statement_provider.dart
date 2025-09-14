import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/bank_statement.dart';

class BankStatementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<BankStatement> _bankStatements = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCompanyId;

  List<BankStatement> get bankStatements => List.unmodifiable(_bankStatements);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load bank statements for a specific company
  Future<void> loadBankStatementsForCompany(String companyId) async {
    // Don't reload if already loaded for the same company and not currently loading
    if (_currentCompanyId == companyId &&
        _bankStatements.isNotEmpty &&
        !_isLoading) {
      print(
        'Bank statements already loaded for company: $companyId, skipping reload',
      );
      return;
    }

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
          .orderBy('uploadedAt', descending: true)
          .get();

      print(
        'Found ${snapshot.docs.length} bank statement records for company $companyId',
      );

      // Only clear if switching to a different company
      if (_currentCompanyId != companyId) {
        _bankStatements.clear();
      }

      // Add bank statements from Firestore, avoiding duplicates
      for (final doc in snapshot.docs) {
        final bankStatement = BankStatement.fromFirestore(doc);
        final existingIndex = _bankStatements.indexWhere(
          (bs) => bs.id == bankStatement.id,
        );
        if (existingIndex == -1) {
          _bankStatements.add(bankStatement);
        }
      }
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

  // Upload a new bank statement
  Future<bool> uploadBankStatement({
    required String companyId,
    required String fileName,
    required File file,
    required String uploadedBy,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Upload file to Firebase Storage
      final ref = _storage
          .ref()
          .child('bank_statements')
          .child(companyId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create bank statement record in Firestore
      final bankStatement = BankStatement(
        id: '',
        companyId: companyId,
        fileName: fileName,
        fileUrl: downloadUrl,
        uploadedAt: DateTime.now(),
        uploadedBy: uploadedBy,
        history: [
          BankStatementHistory(
            action: 'uploaded',
            performedBy: uploadedBy,
            timestamp: DateTime.now(),
            comments: 'Bank statement uploaded',
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
      _error = 'Failed to upload bank statement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update bank statement (for CA comments, admin comments, status changes)
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

      final bankStatement = _bankStatements.firstWhere((bs) => bs.id == id);

      // Delete file from storage
      try {
        await _storage.refFromURL(bankStatement.fileUrl).delete();
      } catch (e) {
        print('Error deleting file from storage: $e');
      }

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
