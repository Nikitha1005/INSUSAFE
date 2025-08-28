import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../auth/login_page.dart';

class PatientSettingsPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String diabetesType;
  final String age;

  const PatientSettingsPage({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.diabetesType,
    required this.age,
  }) : super(key: key);

  @override
  State<PatientSettingsPage> createState() => _PatientSettingsPageState();
}

class _PatientSettingsPageState extends State<PatientSettingsPage> {
  bool notificationsEnabled = true;

  late String currentName;
  late String currentEmail;
  late String currentType;
  late String currentAge;

  String? connectedDoctor;
  String? connectedCaregiver;

  @override
  void initState() {
    super.initState();
    currentName = widget.patientName;
    currentEmail = widget.patientEmail;
    currentType = widget.diabetesType;
    currentAge = widget.age;

    _fetchConnections();
  }

  Future<void> _fetchConnections() async {
    final dbRef = FirebaseDatabase.instance.ref("patients/${widget.patientId}/connections");
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      setState(() {
        connectedDoctor = snapshot.child("doctorName").value?.toString();
        connectedCaregiver = snapshot.child("caregiverName").value?.toString();
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Account Information
            _buildTile(
              icon: Icons.person,
              title: "Account Information",
              onTap: () async {
                final updatedData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountInfoPage(
                      patientId: widget.patientId,
                      patientName: currentName,
                      email: currentEmail,
                      diabetesType: currentType,
                      age: currentAge,
                    ),
                  ),
                );

                if (updatedData != null) {
                  setState(() {
                    currentName = updatedData['name'];
                    currentEmail = updatedData['email'];
                    currentType = updatedData['type'];
                    currentAge = updatedData['age'];
                  });
                }
              },
            ),

            // Connected Doctor & Caregiver
            _buildTile(
              icon: Icons.local_hospital,
              title: "Connected Doctor",
              trailing: Text(
                connectedDoctor ?? "Not Connected",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            _buildTile(
              icon: Icons.family_restroom,
              title: "Connected Caregiver",
              trailing: Text(
                connectedCaregiver ?? "Not Connected",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            // My InsuPen
            _buildTile(
              icon: Icons.medical_services,
              title: "My InsuPen",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InsuPenPage(),
                  ),
                );
              },
            ),

            // Security
            _buildTile(
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SecurityPage()),
                );
              },
            ),

            // About App
            _buildTile(
              icon: Icons.info,
              title: "About Application",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AboutAppPage()),
                );
              },
            ),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
              label: const Text(
                "Log Out",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------- Account Info Page ----------
class AccountInfoPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String email;
  final String diabetesType;
  final String age;

  const AccountInfoPage({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.email,
    required this.diabetesType,
    required this.age,
  }) : super(key: key);

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController typeController;
  late TextEditingController ageController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.patientName);
    emailController = TextEditingController(text: widget.email);
    typeController = TextEditingController(text: widget.diabetesType);
    ageController = TextEditingController(text: widget.age);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    typeController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final dbRef = FirebaseDatabase.instance.ref("patients/${widget.patientId}");
    await dbRef.update({
      "name": nameController.text,
      "email": emailController.text,
      "diabetesType": typeController.text,
      "age": ageController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Changes saved.")),
    );

    Navigator.pop(context, {
      'name': nameController.text,
      'email': emailController.text,
      'type': typeController.text,
      'age': ageController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Information")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: "Diabetes Type")),
            TextField(controller: ageController, decoration: const InputDecoration(labelText: "Age")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }
}

//
// ---------- InsuPen Page ----------
class InsuPenPage extends StatefulWidget {
  @override
  State<InsuPenPage> createState() => _InsuPenPageState();
}

class _InsuPenPageState extends State<InsuPenPage> {
  bool connected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My InsuPen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              connected ? "InsuPen Connected" : "No InsuPen Connected",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  connected = !connected;
                });
              },
              child: Text(connected ? "Remove InsuPen" : "Connect InsuPen"),
            )
          ],
        ),
      ),
    );
  }
}

//
// ---------- Security Page ----------
class SecurityPage extends StatefulWidget {
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final currentController = TextEditingController();
  final newController = TextEditingController();

  void _changePassword() {
    if (currentController.text.isEmpty || newController.text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password changed successfully")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: currentController, decoration: const InputDecoration(labelText: "Current Password"), obscureText: true),
            TextField(controller: newController, decoration: const InputDecoration(labelText: "New Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _changePassword, child: const Text("Change Password"))
          ],
        ),
      ),
    );
  }
}

//
// ---------- About App Page ----------
class AboutAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Application")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.medical_services, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "InsuSafe - Your Smart Insulin Management App.\nTrack, connect, and manage your insulin safely.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
