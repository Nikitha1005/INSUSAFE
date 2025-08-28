import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class PatientStatisticsPage extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String patientEmail;

  const PatientStatisticsPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
  });

  // Generate dummy data for last 7 days glucose levels
  List<FlSpot> _generateDummyData() {
    final random = Random();
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), 80 + random.nextInt(60).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _generateDummyData();
    final avg = data.map((e) => e.y).reduce((a, b) => a + b) / data.length;
    final highest = data.map((e) => e.y).reduce(max);
    final lowest = data.map((e) => e.y).reduce(min);

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Statistics - $patientName'),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Glucose Graph
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Glucose Levels (Last 7 Days)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 6,
                          minY: 50,
                          maxY: 160,
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                                  return Text(days[value.toInt() % 7]);
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: data,
                              isCurved: true,
                              color: Colors.blueAccent,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blueAccent.withOpacity(0.3),
                              ),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Summary Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Average", avg.toStringAsFixed(1)),
                _buildStatCard("Highest", highest.toStringAsFixed(1)),
                _buildStatCard("Lowest", lowest.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 100,
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
