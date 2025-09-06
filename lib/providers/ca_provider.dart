import 'package:flutter/material.dart';
import '../models/ca.dart';

class CAProvider extends ChangeNotifier {
  final List<CA> _cas = [];
  List<CA> get cas => List.unmodifiable(_cas);

  void addCA(String username, String password) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _cas.add(CA(id: id, username: username, password: password));
    notifyListeners();
  }

  void editCA(String id, String username, String password) {
    final ca = _cas.firstWhere((c) => c.id == id);
    ca.username = username;
    ca.password = password;
    notifyListeners();
  }

  void deleteCA(String id) {
    _cas.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  CA? getCAByCredentials(String username, String password) {
    try {
      return _cas.firstWhere((c) => c.username == username && c.password == password);
    } catch (_) {
      return null;
    }
  }

  CA? getCAById(String id) {
    try {
      return _cas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}