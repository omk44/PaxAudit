import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, sbi, hdfc, icici, axis, kotak }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.sbi:
        return 'State Bank of India';
      case PaymentMethod.hdfc:
        return 'HDFC Bank';
      case PaymentMethod.icici:
        return 'ICICI Bank';
      case PaymentMethod.axis:
        return 'Axis Bank';
      case PaymentMethod.kotak:
        return 'Kotak Mahindra Bank';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.sbi:
        return '🏦';
      case PaymentMethod.hdfc:
        return '🏦';
      case PaymentMethod.icici:
        return '🏦';
      case PaymentMethod.axis:
        return '🏦';
      case PaymentMethod.kotak:
        return '🏦';
    }
  }
}

class ExpenseEditHistory {
  final double amount;
  final double gstPercentage;
  final double gstAmount;
  final String invoiceNumber;
  final String description;
  final PaymentMethod paymentMethod;
  final String editedBy;
  final DateTime timestamp;

  ExpenseEditHistory({
    required this.amount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.invoiceNumber,
    required this.description,
    required this.paymentMethod,
    required this.editedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'invoiceNumber': invoiceNumber,
      'description': description,
      'paymentMethod': paymentMethod.name,
      'editedBy': editedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ExpenseEditHistory.fromMap(Map<String, dynamic> map) {
    return ExpenseEditHistory(
      amount: (map['amount'] ?? 0.0).toDouble(),
      gstPercentage: (map['gstPercentage'] ?? 0.0).toDouble(),
      gstAmount: (map['gstAmount'] ?? 0.0).toDouble(),
      invoiceNumber: map['invoiceNumber'] ?? '',
      description: map['description'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      editedBy: map['editedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class Expense {
  final String id;
  String categoryId;
  String categoryName; // Store category name for easy display
  double amount;
  double gstPercentage; // GST percentage from category
  double gstAmount; // Calculated GST amount
  String invoiceNumber;
  String description;
  DateTime date;
  String addedBy;
  PaymentMethod paymentMethod;
  List<ExpenseEditHistory> history;
  String companyId; // To separate expenses by company
  String? transactionId;

  Expense({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.invoiceNumber,
    required this.description,
    required this.date,
    required this.addedBy,
    required this.paymentMethod,
    required this.history,
    required this.companyId,
    this.transactionId,
  });

  double get totalAmount => amount + gstAmount;

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      gstPercentage: (data['gstPercentage'] ?? 0.0).toDouble(),
      gstAmount: (data['gstAmount'] ?? 0.0).toDouble(),
      invoiceNumber: data['invoiceNumber'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      addedBy: data['addedBy'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == data['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      history: (data['history'] as List<dynamic>? ?? [])
          .map((h) => ExpenseEditHistory.fromMap(h as Map<String, dynamic>))
          .toList(),
      companyId: data['companyId'] ?? '',
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'invoiceNumber': invoiceNumber,
      'description': description,
      'date': Timestamp.fromDate(date),
      'addedBy': addedBy,
      'paymentMethod': paymentMethod.name,
      'history': history.map((h) => h.toMap()).toList(),
      'companyId': companyId,
      'transactionId': transactionId,
    };
  }

  Expense copyWith({
    String? categoryId,
    String? categoryName,
    double? amount,
    double? gstPercentage,
    double? gstAmount,
    String? invoiceNumber,
    String? description,
    DateTime? date,
    String? addedBy,
    PaymentMethod? paymentMethod,
    List<ExpenseEditHistory>? history,
    String? companyId,
    String? transactionId,
  }) {
    return Expense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      gstAmount: gstAmount ?? this.gstAmount,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      description: description ?? this.description,
      date: date ?? this.date,
      addedBy: addedBy ?? this.addedBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      history: history ?? this.history,
      companyId: companyId ?? this.companyId,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}
