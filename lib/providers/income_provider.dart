import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income.dart';

class IncomeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCompanyId; // Track current company

  List<Income> get incomes => List.unmodifiable(_incomes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculate total income amount
  double get totalIncome =>
      _incomes.fold(0.0, (sum, income) => sum + income.amount);

  // Load incomes for a specific company
  Future<void> loadIncomesForCompany(String companyId) async {
    // Don't reload if already loaded for the same company and not currently loading
    if (_currentCompanyId == companyId && _incomes.isNotEmpty && !_isLoading) {
      print('Incomes already loaded for company: $companyId, skipping reload');
      return;
    }

    // Don't reload if already loading for the same company
    if (_currentCompanyId == companyId && _isLoading) {
      print('Already loading incomes for company: $companyId, skipping duplicate load');
      return;
    }

    try {
      print('Loading incomes for company: $companyId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('incomes')
          .where('companyId', isEqualTo: companyId)
          .orderBy('date', descending: true)
          .get();

      print(
        'Found ${snapshot.docs.length} income records for company $companyId',
      );
      
      // Only clear if switching to a different company
      if (_currentCompanyId != companyId) {
        _incomes.clear();
      }
      
      // Add incomes from Firestore, avoiding duplicates
      for (final doc in snapshot.docs) {
        final income = Income.fromFirestore(doc);
        final existingIndex = _incomes.indexWhere((i) => i.id == income.id);
        if (existingIndex == -1) {
          _incomes.add(income);
        }
      }
      _currentCompanyId = companyId;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading incomes for company $companyId: $e');
      _error = 'Failed to load incomes: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new income
  Future<bool> addIncome(Income income) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef = await _firestore
          .collection('incomes')
          .add(income.toFirestore());

      // Add to local list with the generated ID (only if not already present)
      final createdIncome = income.copyWith();
      
      // Check if income already exists to prevent duplicates
      final existingIndex = _incomes.indexWhere((i) => i.id == docRef.id);
      if (existingIndex == -1) {
        _incomes.insert(
          0,
          Income(
            id: docRef.id,
            amount: createdIncome.amount,
            description: createdIncome.description,
            category: createdIncome.category,
            date: createdIncome.date,
            addedBy: createdIncome.addedBy,
            paymentMethod: createdIncome.paymentMethod,
            transactionId: createdIncome.transactionId,
            history: createdIncome.history,
            companyId: createdIncome.companyId,
          ),
        ); // Insert at beginning for recent first
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add income: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an income
  Future<bool> updateIncome(Income income, {required String editedBy}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Preserve original creator if present in local cache
      final indexExisting = _incomes.indexWhere((i) => i.id == income.id);
      final preserved = indexExisting == -1
          ? income
          : income.copyWith(addedBy: _incomes[indexExisting].addedBy);

      // Append edit history entry before update
      final updatedHistory = List<IncomeEditHistory>.from(preserved.history)
        ..add(
          IncomeEditHistory(
            amount: preserved.amount,
            description: preserved.description,
            category: preserved.category,
            editedBy: editedBy,
            timestamp: DateTime.now(),
          ),
        );

      final incomeWithHistory = preserved.copyWith(history: updatedHistory);

      await _firestore
          .collection('incomes')
          .doc(income.id)
          .update(incomeWithHistory.toFirestore());

      // Update local list
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = incomeWithHistory;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update income: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete an income
  Future<bool> deleteIncome(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('incomes').doc(id).delete();

      _incomes.removeWhere((i) => i.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete income: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Edit income (alias for updateIncome)
  Future<bool> editIncome(String id, double amount, String editedBy) async {
    final income = _incomes.firstWhere((i) => i.id == id);
    final updatedIncome = income.copyWith(amount: amount);

    return await updateIncome(updatedIncome, editedBy: editedBy);
  }

  // Get income by ID
  Income? getIncomeById(String id) {
    try {
      return _incomes.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get total income amount
  double get totalAmount {
    return _incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  // Get incomes by category
  List<Income> getIncomesByCategory(String category) {
    return _incomes.where((i) => i.category == category).toList();
  }

  // Get incomes by date range
  List<Income> getIncomesByDateRange(DateTime startDate, DateTime endDate) {
    return _incomes
        .where(
          (i) =>
              i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              i.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all incomes (useful for logout)
  void clearIncomes() {
    print('Clearing all income data');
    _incomes.clear();
    _currentCompanyId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Clear incomes for company switch - only clear if switching to different company
  void clearIncomesForCompanySwitch() {
    print('Clearing income data for company switch');
    _incomes.clear();
    _currentCompanyId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Force reload data for current company
  Future<void> reloadCurrentCompanyData() async {
    if (_currentCompanyId != null) {
      await loadIncomesForCompany(_currentCompanyId!);
    }
  }
}
