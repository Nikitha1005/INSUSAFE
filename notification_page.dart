import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DoctorNotificationPage extends StatefulWidget {
  final String doctorEmail;
  const DoctorNotificationPage({super.key, required this.doctorEmail});

  @override
  State<DoctorNotificationPage> createState() => _DoctorNotificationPageState();
}

class _DoctorNotificationPageState extends State<DoctorNotificationPage> {
  final _db = FirebaseDatabase.instance;
  String? _doctorName;
  String? _doctorKey;

  @override
  void initState() {
    super.initState();
    _loadDoctorDetails();
  }

  Future<void> _loadDoctorDetails() async {
    final snap = await _db
        .ref('doctors')
        .orderByChild('email')
        .equalTo(widget.doctorEmail.toLowerCase())
        .get();

    if (snap.exists) {
      final firstChild = snap.children.first;
      _doctorName = firstChild.child('name').value?.toString() ?? 'Doctor';
      _doctorKey = firstChild.key;
      if (mounted) setState(() {});
    }
  }

  Future<void> _approve(String reqKey, Map<String, dynamic> data) async {
    if (_doctorKey == null) return;

    final patientEmail = (data['patientEmail'] as String).toLowerCase();
    final patientKey = patientEmail.replaceAll(RegExp(r'[.#$\[\]]'), '_');

    final Map<String, dynamic> updates = {};

    updates['/connections/$patientKey'] = {
      'doctorName': _doctorName ?? 'Doctor',
      'doctorEmail': widget.doctorEmail,
      'timestamp': ServerValue.timestamp,
    };

    updates['/doctors/$_doctorKey/connectedPatients/$patientKey'] = {
      'email': patientEmail,
      'name': data['patientName'] ?? 'Unknown Patient',
      'timestamp': ServerValue.timestamp,
    };

    updates['/doctors/$_doctorKey/requests/$reqKey'] = null;

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
    if (_doctorKey == null) return;
    try {
      await _db.ref('doctors/$_doctorKey/requests/$reqKey').remove();
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
    if (_doctorKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connection Requests')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connection Requests')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.ref('doctors/$_doctorKey/requests').onValue,
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

          final raw = Map<dynamic, dynamic>.from(snap.data!.snapshot.value as Map);
          final requests = raw.entries.toList();

          int parseTimestamp(dynamic value) {
            if (value == null) return 0;
            if (value is int) return value;
            if (value is String) return int.tryParse(value) ?? 0;
            return 0;
          }

          requests.sort((a, b) =>
              parseTimestamp(b.value['timestamp'])
                  .compareTo(parseTimestamp(a.value['timestamp'])));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final reqKey = requests[i].key as String;
              final data = Map<String, dynamic>.from(requests[i].value as Map);

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
