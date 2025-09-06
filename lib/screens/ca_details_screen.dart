// screens/ca_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ca_provider.dart';

class CADetailsScreen extends StatelessWidget {
  const CADetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final caProvider = Provider.of<CAProvider>(context);
    final ca = caProvider.getCAById(auth.caId ?? '');

    if (ca == null) {
      return const Scaffold(body: Center(child: Text('CA details not found.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('CA Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${ca.id}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Username: ${ca.username}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Password: ${ca.password}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
