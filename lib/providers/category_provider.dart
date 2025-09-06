import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  List<Category> get categories => List.unmodifiable(_categories);

  void addCategory(String name, String editedBy) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final category = Category(
      id: id,
      name: name,
      lastEditedBy: editedBy,
      lastEditedAt: now,
      history: [CategoryEditHistory(editedBy: editedBy, timestamp: now, name: name)],
    );
    _categories.add(category);
    notifyListeners();
  }

  void editCategory(String id, String newName, String editedBy) {
    final cat = _categories.firstWhere((c) => c.id == id);
    cat.name = newName;
    cat.lastEditedBy = editedBy;
    cat.lastEditedAt = DateTime.now();
    cat.history.add(CategoryEditHistory(editedBy: editedBy, timestamp: cat.lastEditedAt, name: newName));
    notifyListeners();
  }
}