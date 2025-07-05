
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';

class Agentdashboard extends StatelessWidget {
  const Agentdashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      body: Container(

    decoration: const BoxDecoration(
    gradient: LinearGradient(
    colors: [
    Color(0xFF3F51B5),
    Color(0xFFC5CAE9),
    Color(0xFFE8EAF6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),

        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Lottie animation banner
            Lottie.asset('assets/animations/parkingslot.json', height: 300,width: 500),

            const SizedBox(height: 16),

            // Slot Stats Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                StatCard(title: "Total Slots", count: "50", color: Colors.blue),
                StatCard(title: "Occupied", count: "32", color: Colors.red),
                StatCard(title: "Available", count: "18", color: Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            // Pie Chart
            const Text("Slot Usage Breakdown", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 32, color: Colors.red, title: 'Occupied'),
                    PieChartSectionData(value: 18, color: Colors.green, title: 'Available'),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Arrival/Departure Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  icon: const Icon(Icons.login),
                  label: const Text("Confirm Arrival",style: TextStyle(color: Colors.white),),
                  onPressed: () {},
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  icon: const Icon(Icons.logout),
                  label: const Text("Confirm Departure"),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const StatCard({required this.title, required this.count, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}

