import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryEditHistory {
  final String editedBy;
  final DateTime timestamp;
  final String name;
  final double? gstPercentage;
  
  CategoryEditHistory({
    required this.editedBy,
    required this.timestamp,
    required this.name,
    this.gstPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'editedBy': editedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'name': name,
      'gstPercentage': gstPercentage,
    };
  }

  factory CategoryEditHistory.fromMap(Map<String, dynamic> map) {
    return CategoryEditHistory(
      editedBy: map['editedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      name: map['name'] ?? '',
      gstPercentage: map['gstPercentage']?.toDouble(),
    );
  }
}

class Category {
  final String id;
  String name;
  double gstPercentage; // GST percentage for this category
  String lastEditedBy;
  DateTime lastEditedAt;
  List<CategoryEditHistory> history;
  String companyId; // To separate categories by company
  
  Category({
    required this.id,
    required this.name,
    required this.gstPercentage,
    required this.lastEditedBy,
    required this.lastEditedAt,
    required this.history,
    required this.companyId,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      gstPercentage: (data['gstPercentage'] ?? 0.0).toDouble(),
      lastEditedBy: data['lastEditedBy'] ?? '',
      lastEditedAt: (data['lastEditedAt'] as Timestamp).toDate(),
      history: (data['history'] as List<dynamic>? ?? [])
          .map((h) => CategoryEditHistory.fromMap(h as Map<String, dynamic>))
          .toList(),
      companyId: data['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gstPercentage': gstPercentage,
      'lastEditedBy': lastEditedBy,
      'lastEditedAt': Timestamp.fromDate(lastEditedAt),
      'history': history.map((h) => h.toMap()).toList(),
      'companyId': companyId,
    };
  }

  Category copyWith({
    String? name,
    double? gstPercentage,
    String? lastEditedBy,
    DateTime? lastEditedAt,
    List<CategoryEditHistory>? history,
    String? companyId,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      history: history ?? this.history,
      companyId: companyId ?? this.companyId,
    );
  }
}