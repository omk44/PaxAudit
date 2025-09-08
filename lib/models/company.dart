import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  String name;
  String adminEmail;
  String adminName;
  String? description;
  String? address;
  String? phoneNumber;
  String? website;
  List<String> caEmails; // List of CA emails who can access this company
  DateTime createdAt;
  DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.adminEmail,
    required this.adminName,
    this.description,
    this.address,
    this.phoneNumber,
    this.website,
    required this.caEmails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      adminName: data['adminName'] ?? '',
      description: data['description'],
      address: data['address'],
      phoneNumber: data['phoneNumber'],
      website: data['website'],
      caEmails: List<String>.from(data['caEmails'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'adminEmail': adminEmail,
      'adminName': adminName,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'website': website,
      'caEmails': caEmails,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Company copyWith({
    String? name,
    String? adminEmail,
    String? adminName,
    String? description,
    String? address,
    String? phoneNumber,
    String? website,
    List<String>? caEmails,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      adminEmail: adminEmail ?? this.adminEmail,
      adminName: adminName ?? this.adminName,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      caEmails: caEmails ?? this.caEmails,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
