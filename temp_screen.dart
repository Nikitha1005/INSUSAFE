import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  final List<TemperatureData> _temperatureHistory = [];
  bool _isLoading = true;
  bool _alertActive = false;
  String _penStatus = 'Unknown';

  // ThingSpeak API details
  final String _channelId = 'YOUR_CHANNEL_ID';
  final String _apiKey = 'YOUR_API_KEY';
  final int _results = 10;

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchTemperatureData();
    _setupFirebaseListeners();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _fetchTemperatureData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.thingspeak.com/channels/$_channelId/feeds.json?api_key=$_apiKey&results=$_results'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data['feeds'] as List;

        setState(() {
          _temperatureHistory.clear();
          for (var feed in feeds) {
            final temp = double.tryParse(feed['field1'] ?? '0') ?? 0;
            final penPresent = feed['field2'] == '1';
            final date = DateTime.parse(feed['created_at']);
            
            _temperatureHistory.add(TemperatureData(date, temp, penPresent));
          }
          
          // Check for alerts
          _checkForAlerts();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkForAlerts() {
    if (_temperatureHistory.isEmpty) return;

    final latest = _temperatureHistory.last;
    final tempOutOfRange = latest.temperature < 2 || latest.temperature > 8;
    final penMissing = !latest.penPresent;

    if (tempOutOfRange || penMissing) {
      _showAlertNotification(tempOutOfRange, penMissing);
      setState(() {
        _alertActive = true;
      });
    } else {
      setState(() {
        _alertActive = false;
      });
    }
  }

  Future<void> _showAlertNotification(bool tempAlert, bool penAlert) async {
    String message = '';
    if (tempAlert && penAlert) {
      message = 'Temperature out of range AND insulin pen is missing!';
    } else if (tempAlert) {
      message = 'Storage temperature is out of safe range (2-8°C)!';
    } else if (penAlert) {
      message = 'Insulin pen is not detected in storage!';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'temperature_alerts',
      'Temperature Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      'Insulin Storage Alert',
      message,
      platformChannelSpecifics,
    );
  }

  void _setupFirebaseListeners() {
    FirebaseFirestore.instance
        .collection('temperature_alerts')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final temp = data['temperature'] as double;
        final isPenPresent = data['pen_present'] as bool? ?? true;

        setState(() {
          _alertActive = true;
          _penStatus = isPenPresent ? 'Present' : 'Missing';
        });

        _showAlertNotification(temp < 2 || temp > 8, !isPenPresent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: _alertActive ? Colors.red[100] : Colors.green[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_temperatureHistory.isNotEmpty)
                    Text(
                      'Temperature: ${_temperatureHistory.last.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontSize: 16),
                    ),
                  Text(
                    'Pen Status: $_penStatus',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_alertActive)
                    const Text(
                      'ALERT ACTIVE!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SfCartesianChart(
                    title: const ChartTitle(text: 'Temperature History'),
                    legend: const Legend(isVisible: true),
                    primaryXAxis: DateTimeAxis(
                      title: const AxisTitle(text: 'Time'),
                    ),
                    primaryYAxis: NumericAxis(
                      title: const AxisTitle(text: 'Temperature (°C)'),
                      minimum: 0,
                      maximum: 10,
                    ),
                    series: <ChartSeries<TemperatureData, DateTime>>[
                      LineSeries<TemperatureData, DateTime>(
                        dataSource: _temperatureHistory,
                        xValueMapper: (TemperatureData data, _) => data.time,
                        yValueMapper: (TemperatureData data, _) => data.temperature,
                        name: 'Temperature',
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      LineSeries<TemperatureData, DateTime>(
                        dataSource: _temperatureHistory,
                        xValueMapper: (TemperatureData data, _) => data.time,
                        yValueMapper: (TemperatureData data, _) => data.penPresent ? 1 : 0,
                        name: 'Pen Present',
                        markerSettings: const MarkerSettings(isVisible: true),
                        yAxisName: 'Pen Status',
                      ),
                    ],
                  ),
          ),
          ElevatedButton(
            onPressed: _fetchTemperatureData,
            child: const Text('Refresh Data'),
          ),
        ],
      ),
    );
  }
}

class TemperatureData {
  final DateTime time;
  final double temperature;
  final bool penPresent;

  TemperatureData(this.time, this.temperature, this.penPresent);
}
