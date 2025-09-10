import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Calculate total expense amount
  double get totalExpense => _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  
  // Calculate total GST paid
  double get totalGst => _expenses.fold(0.0, (sum, expense) => sum + expense.gstAmount);

  // Load expenses for a specific company
  Future<void> loadExpensesForCompany(String companyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('expenses')
          .where('companyId', isEqualTo: companyId)
          .orderBy('date', descending: true)
          .get();

      _expenses.clear();
      _expenses.addAll(snapshot.docs.map((doc) => Expense.fromFirestore(doc)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load expenses: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new expense
  Future<bool> addExpense(Expense expense) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef = await _firestore.collection('expenses').add(expense.toFirestore());

      // Add to local list with the generated ID
      final createdExpense = expense.copyWith().copyWith(companyId: expense.companyId);
      // Ensure the created expense carries the Firestore-generated id
      _expenses.insert(0, Expense(
        id: docRef.id,
        categoryId: createdExpense.categoryId,
        categoryName: createdExpense.categoryName,
        amount: createdExpense.amount,
        gstPercentage: createdExpense.gstPercentage,
        gstAmount: createdExpense.gstAmount,
        invoiceNumber: createdExpense.invoiceNumber,
        description: createdExpense.description,
        date: createdExpense.date,
        addedBy: createdExpense.addedBy,
        paymentMethod: createdExpense.paymentMethod,
        history: createdExpense.history,
        companyId: createdExpense.companyId,
      )); // Insert at beginning for recent first

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an expense
  Future<bool> updateExpense(Expense expense, {required String editedBy}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Preserve original creator if present in local cache
      final existingIndex = _expenses.indexWhere((e) => e.id == expense.id);
      final preserved = existingIndex == -1
          ? expense
          : expense.copyWith(addedBy: _expenses[existingIndex].addedBy);

      // Append edit history entry before update
      final updatedHistory = List<ExpenseEditHistory>.from(preserved.history)
        ..add(ExpenseEditHistory(
          amount: preserved.amount,
          gstPercentage: preserved.gstPercentage,
          gstAmount: preserved.gstAmount,
          invoiceNumber: preserved.invoiceNumber,
          description: preserved.description,
          paymentMethod: preserved.paymentMethod,
          editedBy: editedBy,
          timestamp: DateTime.now(),
        ));

      final expenseWithHistory = preserved.copyWith(history: updatedHistory);

      await _firestore
          .collection('expenses')
          .doc(expense.id)
          .update(expenseWithHistory.toFirestore());

      // Update local list
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expenseWithHistory;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('expenses').doc(id).delete();
      
      _expenses.removeWhere((e) => e.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Edit expense (alias for updateExpense)
  Future<bool> editExpense(Expense expense, {required String editedBy}) async {
    return await updateExpense(expense, editedBy: editedBy);
  }

  // Get expense by ID
  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get total expenses amount
  double get totalAmount {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.totalAmount);
  }

  // Get total GST amount
  double get totalGstAmount {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.gstAmount);
  }

  // Get total base amount (without GST)
  double get totalBaseAmount {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expenses by category
  List<Expense> getExpensesByCategory(String categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).toList();
  }

  // Get expenses by payment method
  List<Expense> getExpensesByPaymentMethod(PaymentMethod method) {
    return _expenses.where((e) => e.paymentMethod == method).toList();
  }

  // Get expenses by date range
  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _expenses.where((e) => 
      e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      e.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all expenses (useful for logout)
  void clearExpenses() {
    _expenses.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}