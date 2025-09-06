import 'package:flutter/material.dart';
import '../models/income.dart';

class IncomeProvider extends ChangeNotifier {
  final List<Income> _incomes = [];
  List<Income> get incomes => List.unmodifiable(_incomes);

  void addIncome({
    required double amount,
    required DateTime date,
    required String addedBy,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final income = Income(
      id: id,
      amount: amount,
      date: date,
      addedBy: addedBy,
      history: [IncomeEditHistory(
        amount: amount,
        editedBy: addedBy,
        timestamp: now,
      )],
    );
    _incomes.add(income);
    notifyListeners();
  }

  void editIncome(String id, double amount, String editedBy) {
    final inc = _incomes.firstWhere((i) => i.id == id);
    inc.amount = amount;
    inc.history.add(IncomeEditHistory(
      amount: amount,
      editedBy: editedBy,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void deleteIncome(String id) {
    _incomes.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  double get totalIncome => _incomes.fold(0, (sum, i) => sum + i.amount);
}