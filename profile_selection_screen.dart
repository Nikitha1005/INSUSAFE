// File: lib/caregiver/profile_selection_screen.dart
import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import 'caregiver_dashboard.dart';

class ProfileSelectionScreen extends StatelessWidget {
  final String email;

  const ProfileSelectionScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    // This is mock data. In a real app, you would fetch this from your database.
    final List<Map<String, dynamic>> profiles = [
      {'name': 'ABC', 'icon': Icons.person},
      {'name': 'XYZ', 'icon': Icons.person},
      {'name': 'DEF', 'icon': Icons.person},
      {'name': 'Add', 'icon': Icons.add},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
            );
          },
        ),
        title:
        Text('Caregiver: $email', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          itemCount: profiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
          ),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final isAddButton = profile['name'] == 'Add';

            return GestureDetector(
              onTap: () {
                if (isAddButton) {
                  // TODO: Implement logic to add a new patient profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add new profile clicked')),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CaregiverDashboard(
                        email: email,
                        profileName: profile['name'],
                      ),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Icon(
                      profile['icon'],
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}