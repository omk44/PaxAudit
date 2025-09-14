import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BankStatement {
  final String id;
  final String companyId;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final String uploadedBy;
  final List<BankStatementHistory> history;
  final String? caComments;
  final String? adminComments;
  final BankStatementStatus status;

  BankStatement({
    required this.id,
    required this.companyId,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
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
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
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
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
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
    String? fileName,
    String? fileUrl,
    DateTime? uploadedAt,
    String? uploadedBy,
    List<BankStatementHistory>? history,
    String? caComments,
    String? adminComments,
    BankStatementStatus? status,
  }) {
    return BankStatement(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
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
  uploaded,
  underReview,
  approved,
  rejected,
  needsRevision,
}

extension BankStatementStatusExtension on BankStatementStatus {
  String get displayName {
    switch (this) {
      case BankStatementStatus.uploaded:
        return 'Uploaded';
      case BankStatementStatus.underReview:
        return 'Under Review';
      case BankStatementStatus.approved:
        return 'Approved';
      case BankStatementStatus.rejected:
        return 'Rejected';
      case BankStatementStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  String get icon {
    switch (this) {
      case BankStatementStatus.uploaded:
        return '📄';
      case BankStatementStatus.underReview:
        return '👀';
      case BankStatementStatus.approved:
        return '✅';
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
      case BankStatementStatus.approved:
        return Colors.green;
      case BankStatementStatus.rejected:
        return Colors.red;
      case BankStatementStatus.needsRevision:
        return Colors.purple;
    }
  }
}
