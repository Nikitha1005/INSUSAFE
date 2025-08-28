import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CaregiverNotificationPage extends StatefulWidget {
  final String caregiverEmail;
  const CaregiverNotificationPage({super.key, required this.caregiverEmail});

  @override
  State<CaregiverNotificationPage> createState() =>
      _CaregiverNotificationPageState();
}

class _CaregiverNotificationPageState extends State<CaregiverNotificationPage> {
  final _db = FirebaseDatabase.instance;
  String? _caregiverName;
  String? _caregiverKey;

  @override
  void initState() {
    super.initState();
    _loadCaregiverDetails();
  }

  Future<void> _loadCaregiverDetails() async {
    final snap = await _db
        .ref('caregivers')
        .orderByChild('email')
        .equalTo(widget.caregiverEmail.toLowerCase())
        .get();

    if (snap.exists) {
      final firstChild = snap.children.first;
      _caregiverName = firstChild.child('name').value?.toString() ?? 'Caregiver';
      _caregiverKey = firstChild.key;
      if (mounted) setState(() {});
    }
  }

  Future<void> _approve(String reqKey, Map<String, dynamic> data) async {
    if (_caregiverKey == null) return;

    final patientEmail = (data['patientEmail'] as String).toLowerCase();
    final patientKey = patientEmail.replaceAll(RegExp(r'[.#$\[\]]'), '_');

    final Map<String, dynamic> updates = {};

    // Update connections (optional, but good for cross refs)
    updates['/connections/$patientKey'] = {
      'caregiverName': _caregiverName ?? 'Caregiver',
      'caregiverEmail': widget.caregiverEmail,
      'timestamp': ServerValue.timestamp,
    };

    // Add patient to caregiver's connectedPatients list
    updates['/caregivers/$_caregiverKey/connectedPatients/$patientKey'] = {
      'email': patientEmail,
      'name': data['patientName'] ?? 'Unknown Patient',
      'timestamp': ServerValue.timestamp,
    };

    // Remove the request after approval
    updates['/caregivers/$_caregiverKey/requests/$reqKey'] = null;

    try {
      await _db.ref().update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient "${data['patientName'] ?? patientEmail}" approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _discard(String reqKey) async {
    if (_caregiverKey == null) return;
    try {
      await _db.ref('caregivers/$_caregiverKey/requests/$reqKey').remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request discarded.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to discard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_caregiverKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connection Requests')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connection Requests')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.ref('caregivers/$_caregiverKey/requests').onValue,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Failed to load requests'));
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(
                child: Text('No pending requests',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          final raw = Map<dynamic, dynamic>.from(
              snap.data!.snapshot.value as Map);
          final requests = raw.entries.toList()
            ..sort((a, b) => ((b.value['timestamp'] ?? 0) as int)
                .compareTo((a.value['timestamp'] ?? 0) as int));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final reqKey = requests[i].key as String;
              final data =
              Map<String, dynamic>.from(requests[i].value as Map);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_add_alt_1),
                        ),
                        title: Text(data['patientName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: ${data['patientEmail'] ?? '-'}'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve'),
                            onPressed: () => _approve(reqKey, data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.highlight_off),
                            label: const Text('Discard'),
                            onPressed: () => _discard(reqKey),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}