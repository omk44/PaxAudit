// import 'package:flutter/material.dart';
class IncomeEditHistory {
  final double amount;
  final String editedBy;
  final DateTime timestamp;
  
  IncomeEditHistory({
    required this.amount,
    required this.editedBy,
    required this.timestamp,
  });
}

class Income {
  final String id;
  double amount;
  DateTime date;
  String addedBy;
  List<IncomeEditHistory> history;
  
  Income({
    required this.id,
    required this.amount,
    required this.date,
    required this.addedBy,
    required this.history,
  });
}