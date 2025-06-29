import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingHistoryEntry {
  final LatLng slot;
  final DateTime arrivalTime;
  final DateTime departureTime;
  final int totalPrice;

  ParkingHistoryEntry({
    required this.slot,
    required this.arrivalTime,
    required this.departureTime,
    required this.totalPrice,
  });

  String get formattedDate => "${arrivalTime.day}/${arrivalTime.month}/${arrivalTime.year}";

  String get arrivalFormatted => "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";

  String get departureFormatted => "${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}";

  String get slotName => "Slot at (${slot.latitude.toStringAsFixed(4)}, ${slot.longitude.toStringAsFixed(4)})";
}

class Parkinghistoryscreen extends StatefulWidget {
  const Parkinghistoryscreen({super.key});

  @override
  State<Parkinghistoryscreen> createState() => _ParkinghistoryscreenState();
}

class _ParkinghistoryscreenState extends State<Parkinghistoryscreen> {
  final List<ParkingHistoryEntry> _dummyHistory = [
    ParkingHistoryEntry(
      slot: LatLng(6.8400, 79.8910),
      arrivalTime: DateTime(2025, 6, 20, 8, 30),
      departureTime: DateTime(2025, 6, 20, 10, 0),
      totalPrice: 180,
    ),
    ParkingHistoryEntry(
      slot: LatLng(6.8522, 79.8862),
      arrivalTime: DateTime(2025, 6, 21, 14, 0),
      departureTime: DateTime(2025, 6, 21, 15, 30),
      totalPrice: 180,
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking History", style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF3F51B5),
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

      child: _dummyHistory.isEmpty
          ? const Center(child: Text("No parking history yet."))
          : ListView.builder(
        itemCount: _dummyHistory.length,
        itemBuilder: (context, index) {
          final entry = _dummyHistory[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

            child: ListTile(
              leading: const Icon(Icons.local_parking, color: Colors.blueAccent),
              title: Text(entry.slotName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Date: ${entry.formattedDate}\nArrival: ${entry.arrivalFormatted}  Departure: ${entry.departureFormatted}",
                style: const TextStyle(height: 1.4),
              ),
              trailing: Text("Rs. ${entry.totalPrice}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              isThreeLine: true,
            ),
          );
        },
      ),
    ),
    );
  }
}

