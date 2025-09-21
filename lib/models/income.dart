import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense.dart';

class IncomeEditHistory {
  final double amount;
  final String description;
  final String category;
  final String editedBy;
  final DateTime timestamp;

  IncomeEditHistory({
    required this.amount,
    required this.description,
    required this.category,
    required this.editedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'editedBy': editedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory IncomeEditHistory.fromMap(Map<String, dynamic> map) {
    return IncomeEditHistory(
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      editedBy: map['editedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class Income {
  final String id;
  double amount;
  String description;
  String category;
  DateTime date;
  String addedBy;
  List<IncomeEditHistory> history;
  String companyId; // To separate income by company
  PaymentMethod paymentMethod;
  String? transactionId;

  Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.addedBy,
    required this.history,
    required this.companyId,
    this.paymentMethod = PaymentMethod.cash,
    this.transactionId,
  });

  factory Income.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Income(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      addedBy: data['addedBy'] ?? '',
      history: (data['history'] as List<dynamic>? ?? [])
          .map((h) => IncomeEditHistory.fromMap(h as Map<String, dynamic>))
          .toList(),
      companyId: data['companyId'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'addedBy': addedBy,
      'history': history.map((h) => h.toMap()).toList(),
      'companyId': companyId,
      'paymentMethod': paymentMethod.name,
      'transactionId': transactionId,
    };
  }

  Income copyWith({
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    String? addedBy,
    List<IncomeEditHistory>? history,
    String? companyId,
    PaymentMethod? paymentMethod,
    String? transactionId,
  }) {
    return Income(
      id: id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      addedBy: addedBy ?? this.addedBy,
      history: history ?? this.history,
      companyId: companyId ?? this.companyId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}
