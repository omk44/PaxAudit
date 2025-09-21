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

  // Clear all categories (useful for logout)
  void clearCategories() {
    print('Clearing all category data');
    _categories.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Seed default Indian GST categories (static list) for a company
  // Does not duplicate existing category names (case-insensitive match)
  Future<void> seedDefaultIndianCategories({
    required String companyId,
    required String editedBy,
  }) async {
    final defaults = <Map<String, dynamic>>[
      // Zero rated / exempt
      {'name': 'Unprocessed Food Grains', 'gst': 0.0},
      {'name': 'Fresh Vegetables & Fruits', 'gst': 0.0},
      {'name': 'Education Services (Exempt)', 'gst': 0.0},
      {'name': 'Healthcare Services (Exempt)', 'gst': 0.0},
      // 5%
      {'name': 'Essential Medicines', 'gst': 5.0},
      {'name': 'Household Essentials (select)', 'gst': 5.0},
      // 12%
      {'name': 'Processed Foods', 'gst': 12.0},
      {'name': 'Computers & Peripherals', 'gst': 12.0},
      // 18%
      {'name': 'Professional Services', 'gst': 18.0},
      {'name': 'Software/SaaS Services', 'gst': 18.0},
      {'name': 'Electronics & Appliances', 'gst': 18.0},
      // 28%
      {'name': 'Luxury Goods', 'gst': 28.0},
      {'name': 'Automobiles (select)', 'gst': 28.0},
    ];

    // Existing names (lowercase) for quick lookup
    final existingNames = _categories
        .where((c) => c.companyId == companyId)
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    // Create missing ones
    for (final item in defaults) {
      final name = (item['name'] as String).trim();
      final key = name.toLowerCase();
      if (existingNames.contains(key)) continue;

      final category = Category(
        id: '',
        name: name,
        gstPercentage: (item['gst'] as num).toDouble(),
        lastEditedBy: editedBy,
        lastEditedAt: DateTime.now(),
        history: [
          CategoryEditHistory(
            editedBy: editedBy,
            timestamp: DateTime.now(),
            name: name,
            gstPercentage: (item['gst'] as num).toDouble(),
          ),
        ],
        companyId: companyId,
      );

      // ignore: discarded_futures
      await addCategory(category);
    }
  }
}