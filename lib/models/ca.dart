import 'package:cloud_firestore/cloud_firestore.dart';

class CA {
  final String id;
  String email;
  String name;
  String? phoneNumber;
  String? licenseNumber;
  List<String> companyIds; // Companies this CA has access to
  DateTime createdAt;
  DateTime updatedAt;
  
  CA({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.licenseNumber,
    required this.companyIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CA.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CA(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      licenseNumber: data['licenseNumber'],
      companyIds: List<String>.from(data['companyIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'companyIds': companyIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CA copyWith({
    String? email,
    String? name,
    String? phoneNumber,
    String? licenseNumber,
    List<String>? companyIds,
    DateTime? updatedAt,
  }) {
    return CA(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      companyIds: companyIds ?? this.companyIds,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}