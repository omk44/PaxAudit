import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';

class CompanyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Company> _companies = [];
  Company? _selectedCompany;
  bool _isLoading = false;
  String? _error;

  List<Company> get companies => _companies;
  Company? get selectedCompany => _selectedCompany;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new company
  Future<bool> createCompany({
    required String name,
    required String adminEmail,
    required String adminName,
    String? description,
    String? address,
    String? phoneNumber,
    String? website,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final company = Company(
        id: '', // Will be set by Firestore
        name: name,
        adminEmail: adminEmail,
        adminName: adminName,
        description: description,
        address: address,
        phoneNumber: phoneNumber,
        website: website,
        caEmails: [],
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('companies').add(company.toFirestore());
      
      // Update the company with the generated ID
      final createdCompany = company.copyWith();
      _companies.add(Company(
        id: docRef.id,
        name: name,
        adminEmail: adminEmail,
        adminName: adminName,
        description: description,
        address: address,
        phoneNumber: phoneNumber,
        website: website,
        caEmails: [],
        createdAt: now,
        updatedAt: now,
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create company: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load all companies
  Future<void> loadCompanies() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('companies').get();
      _companies = snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load companies: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get companies accessible by a CA email
  Future<List<Company>> getCompaniesForCA(String caEmail) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .where('caEmails', arrayContains: caEmail)
          .get();
      
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading companies for CA: $e');
      return [];
    }
  }

  // Add CA to company
  Future<bool> addCAToCompany(String companyId, String caEmail) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'caEmails': FieldValue.arrayUnion([caEmail]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final companyIndex = _companies.indexWhere((c) => c.id == companyId);
      if (companyIndex != -1) {
        _companies[companyIndex] = _companies[companyIndex].copyWith(
          caEmails: [..._companies[companyIndex].caEmails, caEmail],
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Failed to add CA to company: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Remove CA from company
  Future<bool> removeCAFromCompany(String companyId, String caEmail) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'caEmails': FieldValue.arrayRemove([caEmail]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final companyIndex = _companies.indexWhere((c) => c.id == companyId);
      if (companyIndex != -1) {
        final updatedCAEmails = _companies[companyIndex].caEmails
            .where((email) => email != caEmail)
            .toList();
        _companies[companyIndex] = _companies[companyIndex].copyWith(
          caEmails: updatedCAEmails,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Failed to remove CA from company: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Select a company for current session
  void selectCompany(Company company) {
    _selectedCompany = company;
    notifyListeners();
  }

  // Clear selected company
  void clearSelectedCompany() {
    _selectedCompany = null;
    notifyListeners();
  }

  // Update company details
  Future<bool> updateCompany(Company company) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedCompany = company.copyWith(updatedAt: DateTime.now());
      
      await _firestore.collection('companies').doc(company.id).update(updatedCompany.toFirestore());

      // Update local data
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        _companies[index] = updatedCompany;
      }

      if (_selectedCompany?.id == company.id) {
        _selectedCompany = updatedCompany;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update company: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete company
  Future<bool> deleteCompany(String companyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('companies').doc(companyId).delete();
      
      _companies.removeWhere((c) => c.id == companyId);
      
      if (_selectedCompany?.id == companyId) {
        _selectedCompany = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete company: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
