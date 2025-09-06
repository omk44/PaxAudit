// import 'package:flutter/material.dart';
class ExpenseEditHistory {
  final double amount;
  final double cgst;
  final double sgst;
  final String invoiceNumber;
  final String editedBy;
  final DateTime timestamp;
  
  ExpenseEditHistory({
    required this.amount,
    required this.cgst,
    required this.sgst,
    required this.invoiceNumber,
    required this.editedBy,
    required this.timestamp,
  });
}

class Expense {
  final String id;
  String categoryId;
  double amount;
  double cgst;
  double sgst;
  String invoiceNumber;
  DateTime date;
  String addedBy;
  String bankAccount;
  List<ExpenseEditHistory> history;
  
  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.cgst,
    required this.sgst,
    required this.invoiceNumber,
    required this.date,
    required this.addedBy,
    required this.bankAccount,
    required this.history,
  });
  
  double get totalGst => (cgst + sgst) * amount / 100;
}