import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConnectPage extends StatefulWidget {
  final String patientEmail;
  final String patientName; // ✅ Added to send name with request

  const ConnectPage({
    super.key, // ✅ Using super parameter for key
    required this.patientEmail,
    required this.patientName,
  });

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  String _selectedRole = 'Doctor';
  bool _sendingRequest = false;
  String? _message;

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final emailToConnect = _emailController.text.trim();

    setState(() {
      _sendingRequest = true;
      _message = null;
    });

    try {
      final ref = FirebaseDatabase.instance.ref();

      final rolePath = '${_selectedRole.toLowerCase()}s'; // ✅ String interpolation

      final snapshot = await ref
          .child(rolePath)
          .orderByChild('email')
          .equalTo(emailToConnect.toLowerCase())
          .get();

      if (snapshot.exists) {
        int sentCount = 0;

        for (final child in snapshot.children) {
          final key = child.key;
          if (key != null) {
            await ref
                .child(rolePath)
                .child(key)
                .child('requests')
                .push()
                .set({
              'patientEmail': widget.patientEmail,
              'patientName': widget.patientName,
              'status': 'pending',
              'timestamp': ServerValue.timestamp,
            });
            sentCount++;
          }
        }

        setState(() {
          _message =
          'Request sent successfully to $sentCount matching $_selectedRole(s).';
          _sendingRequest = false;
          _emailController.clear();
        });
      } else {
        setState(() {
          _message = 'No $_selectedRole found with that email.';
          _sendingRequest = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error sending request: $e';
        _sendingRequest = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Doctor/Caregiver')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                      DropdownMenuItem(value: 'Caregiver', child: Text('Caregiver')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRole = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Role',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(r'^\w+@([\w-]+\.)+\w{2,4}$') // ✅ Simplified regex
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _sendingRequest
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _sendRequest,
                    child: const Text('Send Request'), // ✅ child last
                  ),
                  const SizedBox(height: 16),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.startsWith('Error') ||
                            _message!.startsWith('No')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}