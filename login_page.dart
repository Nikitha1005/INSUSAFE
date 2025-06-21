import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../caregiver/profile_selection_screen.dart';
import '../doctor/doctor_dashboard.dart';
import '../patient/patient_dashboard.dart';
import 'caregiver_registration_page.dart';
import 'doctor_registration_page.dart';
import 'patient_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); // Kept for future use
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  String? selectedRole;
  bool showPasswordField = false;
  bool isRegisteredUser = false;
  bool isLoading = false;

  void _checkUserRegistration() async {
    final email = emailController.text.trim();

    if (email.isEmpty || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String databasePath = _getDatabasePath();
      final snapshot = await _database.ref(databasePath).orderByChild('email').equalTo(email.toLowerCase()).get();
      bool userExists = snapshot.exists;

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRegisteredUser = userExists;
        showPasswordField = false; // Password field turned off
      });

      if (!userExists) _showRegistrationPrompt();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking user: $e')));
    }
  }

  void _showRegistrationPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Not Found'),
        content: const Text('You need to register first. Would you like to register now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _navigateToRegistration();
          }, child: const Text('Register')),
        ],
      ),
    );
  }

  void _navigateToRegistration() {
    final email = emailController.text.trim();
    if (selectedRole == 'Patient') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDetailsPage(prefillEmail: email)));
    } else if (selectedRole == 'Caregiver') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CaregiverRegistrationPage(email: email)));
    } else if (selectedRole == 'Doctor') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorRegistrationPage(email: email)));
    }
  }

  void _login() async {
    final email = emailController.text.trim();

    if (email.isEmpty || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => isLoading = true);

    try {
      String databasePath = _getDatabasePath();
      final snapshot = await _database.ref(databasePath).orderByChild('email').equalTo(email.toLowerCase()).get();

      bool loginSuccess = false;
      String userName = '';

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final userKey = data.keys.first;
        final userData = data[userKey] as Map;

        // Skipping password check
        loginSuccess = true;
        userName = userData['name'] ?? '';
      }

      if (!mounted) return;

      setState(() => isLoading = false);

      if (loginSuccess) {
        if (selectedRole == 'Patient') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PatientDashboard(name: userName)));
        } else if (selectedRole == 'Caregiver') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileSelectionScreen(email: email)));
        } else if (selectedRole == 'Doctor') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DoctorDashboard(email: email)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during login: $e')));
    }
  }

  String _getDatabasePath() {
    if (selectedRole == 'Patient') return 'patients';
    if (selectedRole == 'Caregiver') return 'caregivers';
    return 'doctors';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/img.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              _buildInputField("Email or Number", emailController),
              const SizedBox(height: 12),
              _buildRoleDropdown(),
              const SizedBox(height: 24),
              if (isLoading)
                const CircularProgressIndicator()
              else if (!isRegisteredUser)
                _buildButton("CONTINUE", _checkUserRegistration)
              else
                _buildButton("LOGIN", _login),
              if (!isRegisteredUser && selectedRole != null)
                TextButton(
                  onPressed: _navigateToRegistration,
                  child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.blue)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blue.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              hint: const Text("Select Role"),
              items: ['Patient', 'Caregiver', 'Doctor'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                  showPasswordField = false;
                  isRegisteredUser = false;
                  passwordController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}