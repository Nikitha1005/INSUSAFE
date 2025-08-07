import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BLEPenScreen extends StatefulWidget {
  const BLEPenScreen({super.key});

  @override
  State<BLEPenScreen> createState() => _BLEPenScreenState();
}

class _BLEPenScreenState extends State<BLEPenScreen> {
  final List<DosageData> _dosageHistory = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  String _status = 'Disconnected';

  // Replace with your insulin pen's service and characteristic UUIDs
  final Guid SERVICE_UUID = Guid('00001809-0000-1000-8000-00805f9b34fb');
  final Guid CHARACTERISTIC_UUID = Guid('00002a1c-0000-1000-8000-00805f9b34fb');

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _status = 'Scanning...';
    });

    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name.contains('InsulinPen')) {
          _connectToDevice(result.device);
          break;
        }
      }
    });

    // Start scan
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _status = 'Connecting...';
    });

    try {
      await device.connect(autoConnect: false);
      setState(() {
        _connectedDevice = device;
        _status = 'Connected';
      });

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid == SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
              // Set up notifications
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                _handleDosageData(value);
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Connection failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _handleDosageData(List<int> value) {
    // Parse dosage data (example: first byte is dosage in units)
    double dosage = value[0].toDouble();
    DateTime now = DateTime.now();

    setState(() {
      _dosageHistory.add(DosageData(now, dosage));
    });

    // Save to Firestore
    _saveDosageToFirestore(dosage, now);
  }

  Future<void> _saveDosageToFirestore(double dosage, DateTime timestamp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('dosages').add({
      'userId': user.uid,
      'dosage': dosage,
      'timestamp': timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _status,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_connectedDevice == null)
            ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              child: Text(_isScanning ? 'Scanning...' : 'Connect to Pen'),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              title: ChartTitle(text: 'Dosage History'),
              legend: Legend(isVisible: true),
              primaryXAxis: DateTimeAxis(
                title: AxisTitle(text: 'Time'),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Dosage (units)'),
              ),
              series: <ChartSeries<DosageData, DateTime>>[
                LineSeries<DosageData, DateTime>(
                  dataSource: _dosageHistory,
                  xValueMapper: (DosageData data, _) => data.time,
                  yValueMapper: (DosageData data, _) => data.dosage,
                  name: 'Insulin Dosage',
                  markerSettings: const MarkerSettings(isVisible: true),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DosageData {
  final DateTime time;
  final double dosage;

  DosageData(this.time, this.dosage);
}
