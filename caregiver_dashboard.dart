import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;
import 'caregiver_notification.dart';
import 'caregiver_settings_page.dart';
import '../auth/patient_detail_page.dart'; // <-- import PatientDetailPage here

class CaregiverDashboard extends StatefulWidget {
  final String email;
  final String profileName;

  const CaregiverDashboard({
    super.key,
    required this.email,
    required this.profileName,
  });

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final _dbRef = FirebaseDatabase.instance.ref();
  String? _caregiverKey;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCaregiverKey();
  }

  Future<void> _loadCaregiverKey() async {
    final snapshot = await _dbRef
        .child('caregivers')
        .orderByChild('email')
        .equalTo(widget.email.toLowerCase())
        .get();

    if (snapshot.exists) {
      final caregiverMap = Map<String, dynamic>.from(snapshot.value as Map);
      _caregiverKey = caregiverMap.keys.first;
      developer.log('Caregiver Key Loaded: $_caregiverKey',
          name: 'CaregiverDashboard');
      if (mounted) {
        setState(() {});
      }
    } else {
      developer.log('Caregiver key not found for email: ${widget.email}',
          name: 'CaregiverDashboard');
    }
  }

  void _openPatientDetails(String patientId, String patientName, String patientEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailPage(
          patientId: patientId,
          patientName: patientName,
          patientEmail: patientEmail,
        ),
      ),
    );
  }

  Widget _patientCard(Map<String, dynamic> patient) {
    return Card(
      key: ValueKey(patient['id']), // Important for smooth list updates
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _openPatientDetails(patient['id'], patient['name'], patient['email']),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_pin, size: 50, color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                patient['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedPatientsGrid() {
    if (_caregiverKey == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.child('caregivers/$_caregiverKey/connectedPatients').onValue,
      builder: (context, patientSnap) {
        developer.log(
          'Patient Stream Update: hasData=${patientSnap.hasData}, '
              'error=${patientSnap.hasError}, '
              'value=${patientSnap.data?.snapshot.value}',
          name: 'CaregiverDashboard',
        );

        if (patientSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (patientSnap.hasError) {
          return const Center(child: Text('Error loading patients'));
        }
        if (!patientSnap.hasData || patientSnap.data!.snapshot.value == null) {
          return const Center(
            child: Text(
              'No connected patients yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final patientMap = Map<String, dynamic>.from(
          patientSnap.data!.snapshot.value as Map,
        );

        final patients = patientMap.entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            'name': data['name'] ?? 'Unknown Patient',
            'email': data['email'] ?? 'No email',
            'timestamp': data['timestamp'] ?? 0,
          };
        }).toList()
          ..sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: GridView.builder(
            key: ValueKey(patients.length),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              return _patientCard(patients[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    if (_caregiverKey == null) return const SizedBox.shrink();

    return StreamBuilder<DatabaseEvent>(
      stream: _dbRef.child('caregivers/$_caregiverKey/requests').onValue,
      builder: (context, snapshot) {
        bool hasRequests =
            snapshot.hasData && snapshot.data!.snapshot.value != null;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CaregiverNotificationPage(caregiverEmail: widget.email),
                ),
              ),
            ),
            if (hasRequests)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: Colors.red, borderRadius: BorderRadius.circular(6)),
                  constraints:
                  const BoxConstraints(minWidth: 12, minHeight: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Connected Patients',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildConnectedPatientsGrid()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.profileName}'),
        actions: [_buildNotificationIcon()],
      ),
      body: _caregiverKey == null
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          const Center(child: Text('Stats Tab (Coming Soon)')),
          CaregiverSettingsPage(
            caregiverId: _caregiverKey ?? '',
            caregiverName: widget.profileName,
            caregiverEmail: widget.email,
            connectedPatients: const [],
          ),// 🔹 Replace later with actual list from DB),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
