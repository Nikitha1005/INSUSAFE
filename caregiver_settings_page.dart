import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_page.dart';

class CaregiverSettingsPage extends StatefulWidget {
  final String caregiverId;
  final String caregiverName;
  final String caregiverEmail;
  final List<String> connectedPatients; // Multiple patients possible

  const CaregiverSettingsPage({
    super.key,
    required this.caregiverId,
    required this.caregiverName,
    required this.caregiverEmail,
    required this.connectedPatients,
  });

  @override
  State<CaregiverSettingsPage> createState() => _CaregiverSettingsPageState();
}

class _CaregiverSettingsPageState extends State<CaregiverSettingsPage> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.person, size: 40, color: Colors.teal),
                title: Text(widget.caregiverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(widget.caregiverEmail),
              ),
            ),
            const SizedBox(height: 20),

            Text("Connected Patients", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            widget.connectedPatients.isEmpty
                ? const Text("No patients connected yet.")
                : Column(
              children: widget.connectedPatients
                  .map((p) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.health_and_safety, color: Colors.blue),
                  title: Text(p),
                ),
              ))
                  .toList(),
            ),

            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
