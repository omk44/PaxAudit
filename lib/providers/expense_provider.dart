import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  void addExpense({
    required String categoryId,
    required double amount,
    required double cgst,
    required double sgst,
    required String invoiceNumber,
    required DateTime date,
    required String addedBy,
    required String bankAccount,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final expense = Expense(
      id: id,
      categoryId: categoryId,
      amount: amount,
      cgst: cgst,
      sgst: sgst,
      invoiceNumber: invoiceNumber,
      date: date,
      addedBy: addedBy,
      bankAccount: bankAccount,
      history: [ExpenseEditHistory(
        amount: amount,
        cgst: cgst,
        sgst: sgst,
        invoiceNumber: invoiceNumber,
        editedBy: addedBy,
        timestamp: now,
      )],
    );
    _expenses.add(expense);
    notifyListeners();
  }

  void editExpense(String id, double amount, double cgst, double sgst, String invoiceNumber, String editedBy, String bankAccount) {
    final exp = _expenses.firstWhere((e) => e.id == id);
    exp.amount = amount;
    exp.cgst = cgst;
    exp.sgst = sgst;
    exp.invoiceNumber = invoiceNumber;
    exp.bankAccount = bankAccount;
    exp.history.add(ExpenseEditHistory(
      amount: amount,
      cgst: cgst,
      sgst: sgst,
      invoiceNumber: invoiceNumber,
      editedBy: editedBy,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  double get totalGst => _expenses.fold(0, (sum, e) => sum + e.totalGst);
  double get totalExpense => _expenses.fold(0, (sum, e) => sum + e.amount);
}