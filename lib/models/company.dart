import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  String name;
  String adminEmail;
  String adminName;
  String? description;
  String? address;
  String? city;
  String? state;
  String? pincode;
  String? phoneNumber;
  String? email;
  String? website;
  String? gstNumber;
  String? panNumber;
  String? contactPerson;
  String? contactPhone;
  String? contactEmail;
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
    this.city,
    this.state,
    this.pincode,
    this.phoneNumber,
    this.email,
    this.website,
    this.gstNumber,
    this.panNumber,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
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
      city: data['city'],
      state: data['state'],
      pincode: data['pincode'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      website: data['website'],
      gstNumber: data['gstNumber'],
      panNumber: data['panNumber'],
      contactPerson: data['contactPerson'],
      contactPhone: data['contactPhone'],
      contactEmail: data['contactEmail'],
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
      'city': city,
      'state': state,
      'pincode': pincode,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
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
    String? city,
    String? state,
    String? pincode,
    String? phoneNumber,
    String? email,
    String? website,
    String? gstNumber,
    String? panNumber,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
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
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      caEmails: caEmails ?? this.caEmails,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
