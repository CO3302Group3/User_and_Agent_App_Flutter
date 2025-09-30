import 'package:computer_engineering_project/Agents/Members.dart';
import 'package:computer_engineering_project/Agents/receivepayment.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:computer_engineering_project/Agents/Requests.dart';

class Agentdashboard extends StatelessWidget {
  const Agentdashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const int occupied = 32;
    const int available = 18;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Agent Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Requests()));
            },
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- Stat Cards ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  StatCard(
                    icon: Icons.local_parking,
                    title: "Occupied Space",
                    area: "1200 ft²",

                    color: Colors.redAccent,
                  ),
                  StatCard(
                    icon: Icons.park,
                    title: "Available Space",
                    area: "800 ft²",

                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- Center Bikes Summary ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade300,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade300.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Text(
                      "Total Bikes",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "12 / 30",
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- Pie Chart ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Slot Usage Breakdown",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: occupied.toDouble(),
                                  color: Colors.redAccent,
                                  title: '$occupied',
                                  titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                PieChartSectionData(
                                  value: available.toDouble(),
                                  color: Colors.green,
                                  title: '$available',
                                  titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            LegendItem(color: Colors.redAccent, label: "Occupied"),
                            SizedBox(height: 10),
                            LegendItem(color: Colors.green, label: "Available"),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // --- Members and Payments side by side ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: DashboardTile(
                      icon: Icons.people_alt_rounded,
                      title: "Members",
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> Members() ));
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DashboardTile(
                      icon: Icons.attach_money,
                      title: "Payments",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> Receivepayment() ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
      ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String area;

  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.area,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text("Area: $area", style: const TextStyle(fontSize: 13)),

        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const DashboardTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Changed here
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
