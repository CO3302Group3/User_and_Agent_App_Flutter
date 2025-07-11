import 'package:flutter/material.dart';

class Requests extends StatefulWidget {
  const Requests({super.key});

  @override
  State<Requests> createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  final List<Map<String, String>> arrivalRequests = [
    {
      "name": "Vithurshana",
      "arrivalTime": "10:05 AM",
      "price": "100"
    },
  ];

  final List<Map<String, String>> departureRequests = [
    {
      "name": "Vithurshana",
      "departureTime": "12:45 PM",
      "price": "100"
    },
  ];

  void _showArrivalDialog(Map<String, String> item) {
    String plateNumber = '';
    String paymentType = 'Cash';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${item['name']} requested to check in"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Enter Plate Number",
                  prefixIcon: Icon(Icons.directions_bike),
                ),
                onChanged: (value) => plateNumber = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Payment Type: "),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: paymentType,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "Card", child: Text("Card")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          paymentType = value;
                        });
                        Navigator.pop(context);
                        _showArrivalDialog(item);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.currency_rupee),
                  Text("Price: LKR ${item['price']}"),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Arrival Confirmed and Saved")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showDepartureDialog(Map<String, String> item) {
    String paymentType = 'Cash';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Departure"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("Payment Type: "),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: paymentType,
                    items: const [
                      DropdownMenuItem(value: "Cash", child: Text("Cash")),
                      DropdownMenuItem(value: "Card", child: Text("Card")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          paymentType = value;
                        });
                        Navigator.pop(context);
                        _showDepartureDialog(item);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 10),
                  Text("Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                        Navigator.pop(context);
                        _showDepartureDialog(item);
                      }
                    },
                    child: const Text("Pick Date"),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.currency_rupee),
                  Text("Price: LKR ${item['price']}"),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Exit"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Departure Confirmed")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArrivalCard(Map<String, String> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${item['name']} requested to check in",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Text("Arrival Time: ${item['arrivalTime']}"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text("Price: LKR ${item['price']}"),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showArrivalDialog(item),
                icon: const Icon(Icons.login),
                label: const Text("Confirm Arrival"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDepartureCard(Map<String, String> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${item['name']} is ready to check out",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text("Departure Time: ${item['departureTime']}"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text("Price: LKR ${item['price']}"),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showDepartureDialog(item),
                icon: const Icon(Icons.logout),
                label: const Text("Confirm Departure"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...arrivalRequests.map(_buildArrivalCard),
          ...departureRequests.map(_buildDepartureCard),
        ],
      ),
    );
  }
}
