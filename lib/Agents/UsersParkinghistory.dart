import 'package:flutter/material.dart';

class Usersparkinghistory extends StatelessWidget {
  final List<Map<String, dynamic>> historyData = [
    {
      'name': 'Gita Saha',
      'date': '2025-01-15',
      'duration': '2 hrs',
      'price': 'LKR 50',
    },
    {
      'name': 'Kiran Sah',
      'date': '2025-02-25',
      'duration': '1 hr',
      'price': 'LKR 30',
    },
    {
      'name': 'Madhan Roa',
      'date': '2025-03-10',
      'duration': '3.5 hrs',
      'price': 'LKR 100',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking History", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),

        child : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: historyData.length,
        itemBuilder: (context, index) {
          final item = historyData[index];
          return Card(
            color: Colors.indigo.shade500,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.date_range_sharp, color: Colors.white),
                      const SizedBox(width: 8), // Optional spacing
                      Text(
                        "Date Parked: ${item['date']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    children: [
                      const Icon(Icons.timelapse_sharp, color: Colors.white),
                      const SizedBox(width: 8), // Optional spacing
                      Text("Duration: ${item['duration']}", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee_outlined, color: Colors.white),
                      const SizedBox(width: 8), // Optional spacing
                      Text("Price: ${item['price']}", style: const TextStyle(color: Colors.white)),
                    ],
                  ),



                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white,),

                onSelected: (value) {
                  if (value == 'delete') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Deleted ${item['name']}'s record")),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

