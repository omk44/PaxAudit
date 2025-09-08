import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories for a specific company
  Future<void> loadCategoriesForCompany(String companyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('categories')
          .where('companyId', isEqualTo: companyId)
          .get();

      _categories.clear();
      _categories.addAll(snapshot.docs.map((doc) => Category.fromFirestore(doc)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: ${e.toString()}';
      _isLoading = false;
    notifyListeners();
    }
  }

  // Add a new category
  Future<bool> addCategory(Category category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef = await _firestore.collection('categories').add(category.toFirestore());

      // Add to local list with the generated ID
      _categories.add(Category(
        id: docRef.id,
        name: category.name,
        gstPercentage: category.gstPercentage,
        lastEditedBy: category.lastEditedBy,
        lastEditedAt: category.lastEditedAt,
        history: category.history,
        companyId: category.companyId,
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a category
  Future<bool> updateCategory(Category category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('categories').doc(category.id).update(category.toFirestore());

      // Update local list
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('categories').doc(id).delete();
      
      _categories.removeWhere((c) => c.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Edit category (alias for updateCategory)
  Future<bool> editCategory(String id, String name, String editedBy) async {
    final category = getCategoryById(id);
    if (category == null) return false;
    
    final updatedCategory = category.copyWith(
      name: name,
      lastEditedBy: editedBy,
      lastEditedAt: DateTime.now(),
    );
    
    return await updateCategory(updatedCategory);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}