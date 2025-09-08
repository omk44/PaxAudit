import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/company.dart';
import '../models/ca.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _role; // 'admin' or 'ca'
  String? _companyId; // Selected company ID
  Company? _selectedCompany; // Current company for admin/CA
  CA? _caProfile; // CA profile if logged in as CA
  List<Company> _availableCompanies = []; // Companies available to current user

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get role => _role;
  String? get companyId => _companyId;
  Company? get selectedCompany => _selectedCompany;
  CA? get caProfile => _caProfile;
  List<Company> get availableCompanies => _availableCompanies;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserRole();
      } else {
        _role = null;
        _companyId = null;
        _selectedCompany = null;
        _caProfile = null;
        _availableCompanies = [];
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserRole() async {
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _role = data['role'] ?? 'admin';
          
          if (_role == 'ca') {
            // Load CA profile and available companies
            await _loadCAProfile();
          } else {
            // Load admin's company
            _companyId = data['companyId'];
            if (_companyId != null) {
              await _loadSelectedCompany(_companyId!);
            }
          }
        } else {
          // Create default admin user if doesn't exist
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': _user!.email,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });
          _role = 'admin';
        }
        notifyListeners();
      } catch (e) {
        print('Error loading user role: $e');
        _role = 'admin'; // Default to admin on error
        notifyListeners();
      }
    }
  }

  Future<void> _loadCAProfile() async {
    if (_user?.email != null) {
      try {
        final snapshot = await _firestore
            .collection('cas')
            .where('email', isEqualTo: _user!.email)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          _caProfile = CA.fromFirestore(snapshot.docs.first);
          await _loadAvailableCompanies();
        }
      } catch (e) {
        print('Error loading CA profile: $e');
      }
    }
  }

  Future<void> _loadAvailableCompanies() async {
    if (_user?.email != null) {
      try {
        final snapshot = await _firestore
            .collection('companies')
            .where('caEmails', arrayContains: _user!.email)
            .get();
        
        _availableCompanies = snapshot.docs
            .map((doc) => Company.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('Error loading available companies: $e');
        _availableCompanies = [];
      }
    }
  }

  Future<void> _loadSelectedCompany(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (doc.exists) {
        _selectedCompany = Company.fromFirestore(doc);
      }
    } catch (e) {
      print('Error loading selected company: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Check if user has the correct role
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == role) {
            _role = role;
            
            if (_role == 'ca') {
              await _loadCAProfile();
            } else {
              _companyId = data['companyId'];
              if (_companyId != null) {
                await _loadSelectedCompany(_companyId!);
              }
            }
            
            notifyListeners();
            return true;
          } else {
            await _auth.signOut();
            return false;
          }
        } else {
          // For new users, only allow admin role during signup
          if (role != 'admin') {
            await _auth.signOut();
            return false;
          }
          
          // Create new admin user
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': email,
                'role': role,
                'createdAt': FieldValue.serverTimestamp(),
              });
          _role = role;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _role = role;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _role = null;
      _companyId = null;
      _selectedCompany = null;
      _caProfile = null;
      _availableCompanies = [];
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Select company for CA or admin
  Future<bool> selectCompany(String companyId) async {
    try {
      _companyId = companyId;
      await _loadSelectedCompany(companyId);
      
      // Update user document with selected company
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'companyId': companyId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error selecting company: $e');
      return false;
    }
  }

  // Get companies for CA login
  Future<List<Company>> getAvailableCompaniesForEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .where('caEmails', arrayContains: email)
          .get();
      
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading companies for email: $e');
      return [];
    }
  }

  // Create company during admin signup
  Future<bool> createCompanyForAdmin(String companyName, String adminName) async {
    if (_user == null) return false;
    
    try {
      final now = DateTime.now();
      final companyData = {
        'name': companyName,
        'adminEmail': _user!.email!,
        'adminName': adminName,
        'caEmails': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final companyDoc = await _firestore.collection('companies').add(companyData);
      
      // Update user with company ID
      await _firestore.collection('users').doc(_user!.uid).update({
        'companyId': companyDoc.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _companyId = companyDoc.id;
      await _loadSelectedCompany(companyDoc.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating company: $e');
      return false;
    }
  }


  void logout() {
    signOut();
  }
}
