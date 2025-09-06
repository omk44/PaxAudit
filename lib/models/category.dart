// import 'package:flutter/material.dart';
class CategoryEditHistory {
  final String editedBy;
  final DateTime timestamp;
  final String name;
  
  CategoryEditHistory({
    required this.editedBy,
    required this.timestamp,
    required this.name,
  });
}

class Category {
  final String id;
  String name;
  String lastEditedBy;
  DateTime lastEditedAt;
  List<CategoryEditHistory> history;
  
  Category({
    required this.id,
    required this.name,
    required this.lastEditedBy,
    required this.lastEditedAt,
    required this.history,
  });
}