import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_page.dart';

class DoctorSettingsPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorEmail;
  final List<String> connectedPatients;

  const DoctorSettingsPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorEmail,
    required this.connectedPatients,
  });

  @override
  State<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends State<DoctorSettingsPage>
    with SingleTickerProviderStateMixin {
  bool notificationsEnabled = true;
  bool twoFactorAuth = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            children: [
              // Doctor profile card
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueAccent.shade100,
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  title: Text(widget.doctorName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(widget.doctorEmail),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            doctorName: widget.doctorName,
                            doctorEmail: widget.doctorEmail,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🔹 Account & Profile
              _buildSectionTitle("Account & Profile"),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.blue),
                      title: const Text("Change Password"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                    SwitchListTile(
                      secondary:
                      const Icon(Icons.notifications, color: Colors.deepPurple),
                      title: const Text("Enable Notifications"),
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.circle, color: Colors.green),
                      title: const Text("Available Status"),
                      value: true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Availability updated")),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🔹 Connected Patients
              _buildSectionTitle("Connected Patients"),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: widget.connectedPatients.isEmpty
                    ? const ListTile(
                  title: Text("No patients connected yet."),
                )
                    : Column(
                  children: widget.connectedPatients
                      .map((p) => ListTile(
                    leading:
                    const Icon(Icons.person, color: Colors.green),
                    title: Text(p),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.red),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text("Disconnected patient $p")),
                        );
                      },
                    ),
                  ))
                      .toList(),
                ),
              ),

              // 🔹 App Settings
              _buildSectionTitle("App Settings"),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup,
                          color: Colors.deepOrangeAccent),
                      title: const Text("Backup & Restore"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Backup/Restore clicked")),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🔹 Security & Privacy
              _buildSectionTitle("Security & Privacy"),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary:
                      const Icon(Icons.security, color: Colors.redAccent),
                      title: const Text("Two-Factor Authentication"),
                      value: twoFactorAuth,
                      onChanged: (value) {
                        setState(() {
                          twoFactorAuth = value;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.devices, color: Colors.teal),
                      title: const Text("Manage Sessions"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Manage sessions clicked")),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                      title: const Text("Privacy Controls"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Privacy settings clicked")),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🔹 Support
              _buildSectionTitle("Support & Legal"),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help, color: Colors.green),
                      title: const Text("Help & FAQs"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.support_agent,
                          color: Colors.deepPurple),
                      title: const Text("Contact Support"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.blueGrey),
                      title: const Text("About App"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.article, color: Colors.orange),
                      title: const Text("Terms & Privacy Policy"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

//
// 🔹 Edit Profile Page
//
class EditProfilePage extends StatefulWidget {
  final String doctorName;
  final String doctorEmail;

  const EditProfilePage({
    super.key,
    required this.doctorName,
    required this.doctorEmail,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctorName);
    _emailController = TextEditingController(text: widget.doctorEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}

//
// 🔹 Change Password Page
//
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _changePassword() {
    if (_newPasswordController.text == _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(labelText: "Old Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text("Update Password"),
            )
          ],
        ),
      ),
    );
  }
}
