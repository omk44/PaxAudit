import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/ca.dart';

class CAProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<CA> _cas = [];
  bool _isLoading = false;
  String? _error;

  List<CA> get cas => List.unmodifiable(_cas);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all CAs from Firestore
  Future<void> loadCAs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('cas').get();
      _cas.clear();
      _cas.addAll(snapshot.docs.map((doc) => CA.fromFirestore(doc)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load CAs: ${e.toString()}';
      _isLoading = false;
    notifyListeners();
  }
  }

  // Load CAs linked to a specific company
  Future<void> loadCAsForCompany(String companyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('cas')
          .where('companyIds', arrayContains: companyId)
          .get();

      _cas
        ..clear()
        ..addAll(snapshot.docs.map((doc) => CA.fromFirestore(doc)));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load CAs for company: ${e.toString()}';
      _isLoading = false;
    notifyListeners();
  }
  }

  // Add a new CA
  Future<bool> addCA({
    required String email,
    required String name,
    String? phoneNumber,
    String? licenseNumber,
    List<String>? companyIds,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final ca = CA(
        id: '', // Will be set by Firestore
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        companyIds: companyIds ?? [],
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('cas').add(ca.toFirestore());
      
      // Add to local list with the generated ID
      final createdCA = CA(
        id: docRef.id,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        companyIds: companyIds ?? [],
        createdAt: now,
        updatedAt: now,
      );
      
      _cas.add(createdCA);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add CA: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add CA with Firebase Auth user creation
  Future<bool> addCAWithAuth({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? licenseNumber,
    List<String>? companyIds,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First create the CA document
      final now = DateTime.now();
      final ca = CA(
        id: '', // Will be set by Firestore
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        companyIds: companyIds ?? [],
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('cas').add(ca.toFirestore());
      
      // Create Firebase Auth user for the CA using secondary app to avoid affecting admin session
      final secondaryApp = await Firebase.initializeApp(
        name: 'ca-provisioning-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final secondaryStore = FirebaseFirestore.instanceFor(app: secondaryApp);
      
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document with role 'ca' and link to CA
      await secondaryStore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': 'ca',
        'caId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clean up secondary app
      await secondaryAuth.signOut();
      await secondaryApp.delete();
      
      // Add to local list with the generated ID
      final createdCA = CA(
        id: docRef.id,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        companyIds: companyIds ?? [],
        createdAt: now,
        updatedAt: now,
      );
      
      _cas.add(createdCA);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add CA: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a CA
  Future<bool> updateCA(CA ca) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedCA = ca.copyWith(updatedAt: DateTime.now());
      
      await _firestore.collection('cas').doc(ca.id).update(updatedCA.toFirestore());

      // Update local list
      final index = _cas.indexWhere((c) => c.id == ca.id);
      if (index != -1) {
        _cas[index] = updatedCA;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update CA: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a CA
  Future<bool> deleteCA(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('cas').doc(id).delete();
      
    _cas.removeWhere((c) => c.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete CA: ${e.toString()}';
      _isLoading = false;
    notifyListeners();
      return false;
    }
  }

  // Get CA by email
  Future<CA?> getCAByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('cas')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return CA.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting CA by email: $e');
      return null;
    }
  }

  // Get CA by ID
  CA? getCAById(String id) {
    try {
      return _cas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add company to CA
  Future<bool> addCompanyToCA(String caId, String companyId) async {
    try {
      final ca = getCAById(caId);
      if (ca == null) return false;

      final updatedCompanyIds = [...ca.companyIds];
      if (!updatedCompanyIds.contains(companyId)) {
        updatedCompanyIds.add(companyId);
        
        await _firestore.collection('cas').doc(caId).update({
          'companyIds': updatedCompanyIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local data
        final index = _cas.indexWhere((c) => c.id == caId);
        if (index != -1) {
          _cas[index] = ca.copyWith(
            companyIds: updatedCompanyIds,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to add company to CA: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Remove company from CA
  Future<bool> removeCompanyFromCA(String caId, String companyId) async {
    try {
      final ca = getCAById(caId);
      if (ca == null) return false;

      final updatedCompanyIds = ca.companyIds.where((id) => id != companyId).toList();
      
      await _firestore.collection('cas').doc(caId).update({
        'companyIds': updatedCompanyIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      final index = _cas.indexWhere((c) => c.id == caId);
      if (index != -1) {
        _cas[index] = ca.copyWith(
          companyIds: updatedCompanyIds,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to remove company from CA: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all CAs (useful for logout)
  void clearCAs() {
    print('Clearing all CA data');
    _cas.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}