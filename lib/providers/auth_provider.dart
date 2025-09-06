import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _role; // 'admin' or 'ca'
  String? _caId; // If CA, store CA id

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get role => _role;
  String? get caId => _caId;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserRole();
      } else {
        _role = null;
        _caId = null;
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
          _caId = data['caId'];
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
            _caId = data['caId'];
            notifyListeners();
            return true;
          } else {
            await _auth.signOut();
            return false;
          }
        } else {
          // Create new user with specified role
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
      _caId = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Legacy method for backward compatibility
  void login(String role, {String? caId}) {
    _role = role;
    _caId = caId;
    notifyListeners();
  }

  void logout() {
    signOut();
  }
}
