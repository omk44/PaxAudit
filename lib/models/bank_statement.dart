import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BankStatement {
  final String id;
  final String companyId;
  final String title;
  final String bankName;
  final String linkUrl;
  final DateTime statementStartDate;
  final DateTime statementEndDate;
  final DateTime createdAt;
  final String uploadedBy;
  final List<BankStatementHistory> history;
  final String? caComments;
  final String? adminComments;
  final BankStatementStatus status;

  BankStatement({
    required this.id,
    required this.companyId,
    required this.title,
    required this.bankName,
    required this.linkUrl,
    required this.statementStartDate,
    required this.statementEndDate,
    required this.createdAt,
    required this.uploadedBy,
    required this.history,
    this.caComments,
    this.adminComments,
    this.status = BankStatementStatus.uploaded,
  });

  factory BankStatement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BankStatement(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      title: data['title'] ?? data['fileName'] ?? '',
      bankName: data['bankName'] ?? '',
      linkUrl: data['linkUrl'] ?? data['fileUrl'] ?? '',
      statementStartDate:
          (data['statementStartDate'] as Timestamp?)?.toDate() ??
              (data['uploadedAt'] as Timestamp).toDate(),
      statementEndDate:
          (data['statementEndDate'] as Timestamp?)?.toDate() ??
              (data['uploadedAt'] as Timestamp).toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
              (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
      history: (data['history'] as List<dynamic>? ?? [])
          .map((h) => BankStatementHistory.fromMap(h))
          .toList(),
      caComments: data['caComments'],
      adminComments: data['adminComments'],
      status: BankStatementStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BankStatementStatus.uploaded,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'title': title,
      'bankName': bankName,
      'linkUrl': linkUrl,
      'statementStartDate': Timestamp.fromDate(statementStartDate),
      'statementEndDate': Timestamp.fromDate(statementEndDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'uploadedBy': uploadedBy,
      'history': history.map((h) => h.toMap()).toList(),
      'caComments': caComments,
      'adminComments': adminComments,
      'status': status.name,
    };
  }

  BankStatement copyWith({
    String? id,
    String? companyId,
    String? title,
    String? bankName,
    String? linkUrl,
    DateTime? statementStartDate,
    DateTime? statementEndDate,
    DateTime? createdAt,
    String? uploadedBy,
    List<BankStatementHistory>? history,
    String? caComments,
    String? adminComments,
    BankStatementStatus? status,
  }) {
    return BankStatement(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      bankName: bankName ?? this.bankName,
      linkUrl: linkUrl ?? this.linkUrl,
      statementStartDate: statementStartDate ?? this.statementStartDate,
      statementEndDate: statementEndDate ?? this.statementEndDate,
      createdAt: createdAt ?? this.createdAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      history: history ?? this.history,
      caComments: caComments ?? this.caComments,
      adminComments: adminComments ?? this.adminComments,
      status: status ?? this.status,
    );
  }
}

class BankStatementHistory {
  final String action;
  final String performedBy;
  final DateTime timestamp;
  final String? comments;
  final String? oldValue;
  final String? newValue;

  BankStatementHistory({
    required this.action,
    required this.performedBy,
    required this.timestamp,
    this.comments,
    this.oldValue,
    this.newValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'comments': comments,
      'oldValue': oldValue,
      'newValue': newValue,
    };
  }

  factory BankStatementHistory.fromMap(Map<String, dynamic> map) {
    return BankStatementHistory(
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      comments: map['comments'],
      oldValue: map['oldValue'],
      newValue: map['newValue'],
    );
  }
}

enum BankStatementStatus {
  uploaded,           // Admin uploaded, waiting for CA review
  underReview,        // CA is reviewing and cross-matching
  matched,           // CA completed cross-matching with transactions
  partiallyMatched,  // CA found some matches, needs more work
  needsClarification, // CA needs admin clarification
  approved,          // CA approved after complete matching
  rejected,          // CA rejected due to issues
  needsRevision,     // CA marked for revision
}

extension BankStatementStatusExtension on BankStatementStatus {
  String get displayName {
    switch (this) {
      case BankStatementStatus.uploaded:
        return 'Uploaded by Admin';
      case BankStatementStatus.underReview:
        return 'Under CA Review';
      case BankStatementStatus.matched:
        return 'Matched by CA';
      case BankStatementStatus.partiallyMatched:
        return 'Partially Matched';
      case BankStatementStatus.needsClarification:
        return 'Needs Clarification';
      case BankStatementStatus.approved:
        return 'Approved by CA';
      case BankStatementStatus.rejected:
        return 'Rejected by CA';
      case BankStatementStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  String get icon {
    switch (this) {
      case BankStatementStatus.uploaded:
        return '📤';
      case BankStatementStatus.underReview:
        return '🔍';
      case BankStatementStatus.matched:
        return '✅';
      case BankStatementStatus.partiallyMatched:
        return '⚠️';
      case BankStatementStatus.needsClarification:
        return '❓';
      case BankStatementStatus.approved:
        return '🎯';
      case BankStatementStatus.rejected:
        return '❌';
      case BankStatementStatus.needsRevision:
        return '🔄';
    }
  }

  Color get color {
    switch (this) {
      case BankStatementStatus.uploaded:
        return Colors.blue;
      case BankStatementStatus.underReview:
        return Colors.orange;
      case BankStatementStatus.matched:
        return Colors.green;
      case BankStatementStatus.partiallyMatched:
        return Colors.amber;
      case BankStatementStatus.needsClarification:
        return Colors.purple;
      case BankStatementStatus.approved:
        return Colors.green.shade700;
      case BankStatementStatus.rejected:
        return Colors.red;
      case BankStatementStatus.needsRevision:
        return Colors.purple.shade600;
    }
  }
}
