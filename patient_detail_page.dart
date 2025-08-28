import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../patient/patient_statistics.dart';

class PatientDetailPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientEmail;

  const PatientDetailPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String _name = "";
  String _email = "";
  int? age;
  String diabetesType = "--";
  bool _loading = true;

  double? temperature;
  String? boxStatus;
  List<Map<String, dynamic>> glucoseHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  /// 🔹 Fetch patient details
  Future<void> _fetchPatientDetails() async {
    try {
      DatabaseEvent event = await _db
          .child('patients')
          .orderByChild('email')
          .equalTo(widget.patientEmail)
          .once();

      if (event.snapshot.value != null) {
        final data = (event.snapshot.value as Map).values.first;
        final mapData = Map<String, dynamic>.from(data);

        setState(() {
          _name = mapData['name']?.toString() ?? "";
          _email = mapData['email']?.toString() ?? "";
          diabetesType = mapData['diabetesType']?.toString() ?? "--";
          final ageVal = mapData['age'];
          if (ageVal != null) {
            age = ageVal is String ? int.tryParse(ageVal) : ageVal as int?;
          }
        });

        await _fetchThingSpeakData();
      }

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patient data: $e')),
      );
    }
  }

  /// 🔹 Fetch IoT data
  Future<void> _fetchThingSpeakData() async {
    try {
      const channelId = "2563267";
      const readApiKey = "F2CZU3YXJ00U5XVQ";
      final url =
          "https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$readApiKey&results=20";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data["feeds"] as List<dynamic>;

        List<Map<String, dynamic>> history = [];
        for (var feed in feeds) {
          history.add({
            "time": DateFormat('MMM d, h:mm a')
                .format(DateTime.parse(feed["created_at"]).toLocal()),
            "glucose": feed["field1"] != null
                ? double.tryParse(feed["field1"].toString()) ?? 0
                : 0,
          });
        }

        setState(() {
          glucoseHistory = history;
          temperature = feeds.last["field2"] != null
              ? double.tryParse(feeds.last["field2"].toString())
              : null;
          boxStatus = feeds.last["field3"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching ThingSpeak data: $e");
    }
  }

  /// 🔹 Info row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 20),
          const SizedBox(width: 8),
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  /// 🔹 Styled card
  Widget _styledCard({required Color color, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.patientName}'s Details"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Patient Details (Blue Card)
            _styledCard(
              color: Colors.blue.shade100,
              title: "Patient Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.person, "Name", _name),
                  _buildInfoRow(Icons.email, "Email", _email),
                  _buildInfoRow(Icons.cake, "Age",
                      age != null ? age.toString() : "--"),
                  _buildInfoRow(
                      Icons.local_hospital, "Diabetes Type", diabetesType),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                    label: const Text("View Statistics",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientStatisticsPage(
                            patientId:
                            widget.patientEmail.replaceAll('.', ','),
                            patientName: _name,
                            patientEmail: _email,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Insulin Pen Status (Orange Card)
            _styledCard(
              color: Colors.orange.shade100,
              title: "Insulin Pen Status",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.thermostat, "Temperature",
                      temperature != null ? "$temperature °C" : "--"),
                  _buildInfoRow(Icons.inventory, "Pen Present",
                      boxStatus ?? "--"),
                  _buildInfoRow(Icons.update, "Last Updated",
                      glucoseHistory.isNotEmpty
                          ? glucoseHistory.last["time"]
                          : "--"),
                ],
              ),
            ),

            // Reminders (Green Card)
            _styledCard(
              color: Colors.green.shade100,
              title: "Reminders",
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.alarm, color: Colors.teal),
                    title: const Text("Dosage 1"),
                    subtitle: const Text("Dosage: 2 ML\nTime: 08:04 PM"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}