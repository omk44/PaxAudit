import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income.dart';

class IncomeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<Income> _incomes = [];
  bool _isLoading = false;
  String? _error;

  List<Income> get incomes => List.unmodifiable(_incomes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Calculate total income amount
  double get totalIncome => _incomes.fold(0.0, (sum, income) => sum + income.amount);

  // Load incomes for a specific company
  Future<void> loadIncomesForCompany(String companyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('incomes')
          .where('companyId', isEqualTo: companyId)
          .orderBy('date', descending: true)
          .get();

      _incomes.clear();
      _incomes.addAll(snapshot.docs.map((doc) => Income.fromFirestore(doc)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
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

      final docRef = await _firestore.collection('incomes').add(income.toFirestore());
      
      // Add to local list with the generated ID
      final createdIncome = income.copyWith();
      _incomes.insert(0, createdIncome); // Insert at beginning for recent first

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
  Future<bool> updateIncome(Income income) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('incomes').doc(income.id).update(income.toFirestore());

      // Update local list
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = income;
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
    final updatedIncome = income.copyWith(
      amount: amount,
      addedBy: editedBy,
    );
    
    return await updateIncome(updatedIncome);
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
    return _incomes.where((i) => 
      i.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      i.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}