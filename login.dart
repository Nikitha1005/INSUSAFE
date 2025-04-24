import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _role = 'Patient';
  String _diabetesType = 'Type 1';
  bool _isLoginPage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('INSUSAFE', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Text(
              'INSUSAFE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 30),
            _isLoginPage ? _buildLoginForm() : _buildRegistrationForm(),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(
                _isLoginPage ? 'Switch to Register' : 'Switch to Login',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email or Number',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: _role,
          onChanged: (value) {
            setState(() {
              _role = value!;
            });
          },
          items: ['Patient', 'Doctor', 'Admin']
              .map((role) => DropdownMenuItem(
            value: role,
            child: Text(role),
          ))
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('LOGIN'),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email or Number',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Name',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: _ageController,
          decoration: InputDecoration(
            hintText: 'Age',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: _diabetesType,
          onChanged: (value) {
            setState(() {
              _diabetesType = value!;
            });
          },
          items: ['Type 1', 'Type 2', 'Gestational']
              .map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          ))
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('REGISTER'),
        ),
      ],
    );
  }

  void _toggleForm() {
    setState(() {
      _isLoginPage = !_isLoginPage;
    });
  }

  void _login() {
    // Implement login logic here
    print('Logging in...');
  }

  void _register() {
    // Implement registration logic here
    print('Registering...');
  }
}