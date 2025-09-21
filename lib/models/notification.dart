import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'expense', 'income', 'bank_statement', 'ca', etc.
  final String action; // 'created', 'updated', 'deleted', 'commented'
  final String companyId;
  final String caEmail; // Target CA email
  final String performedBy; // Who performed the action
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>?
  metadata; // Additional data like item ID, amount, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.action,
    required this.companyId,
    required this.caEmail,
    required this.performedBy,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  // Copy with method
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? action,
    String? companyId,
    String? caEmail,
    String? performedBy,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      action: action ?? this.action,
      companyId: companyId ?? this.companyId,
      caEmail: caEmail ?? this.caEmail,
      performedBy: performedBy ?? this.performedBy,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'action': action,
      'companyId': companyId,
      'caEmail': caEmail,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      action: data['action'] ?? '',
      companyId: data['companyId'] ?? '',
      caEmail: data['caEmail'] ?? '',
      performedBy: data['performedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  // Create from Firestore query document
  factory NotificationModel.fromQueryDocument(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      action: data['action'] ?? '',
      companyId: data['companyId'] ?? '',
      caEmail: data['caEmail'] ?? '',
      performedBy: data['performedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, action: $action, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
