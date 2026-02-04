import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/token_storage_fallback.dart';
import 'package:intl/intl.dart';

class ParkingHistoryEntry {
  final String slotName;
  final String plateNumber;
  final String date;
  final String arrivalTime; // or DateTime
  final String departureTime;
  final String price;
  final String duration;
  final String status;

  ParkingHistoryEntry({
    required this.slotName,
    required this.plateNumber,
    required this.date,
    required this.arrivalTime,
    required this.departureTime,
    required this.price,
    required this.duration,
    required this.status,
  });
}

class Parkinghistoryscreen extends StatefulWidget {
  const Parkinghistoryscreen({super.key});

  @override
  State<Parkinghistoryscreen> createState() => _ParkinghistoryscreenState();
}

class _ParkinghistoryscreenState extends State<Parkinghistoryscreen> {
  List<ParkingHistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userInfo = await TokenStorageFallback.getUserInfo();
      final myUsername = userInfo['username'] ?? userInfo['email'];
      final myPlate = await _getLastPlate(); 

      if (myUsername == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all slots
      final url = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots");
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> slots = data['parking_slots'] ?? [];
        
        List<ParkingHistoryEntry> detectedHistory = [];
        
        // Iterate slots to find bookings
        // Note: Ideally backend provides a /my_bookings endpoint.
        for (var slot in slots) {
           final slotId = slot['id'] ?? slot['slot_id'];
           final slotName = slot['name'] ?? "Unknown Slot";
           
           // Fetch details for bookings
           final detailUrl = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots/$slotId");
           final detailResp = await http.get(detailUrl);
           if (detailResp.statusCode == 200) {
              final detailData = jsonDecode(detailResp.body);
              final List<dynamic> bookings = detailData['bookings'] ?? [];
              
              for (var booking in bookings) {
                 // Match by Username or Plate
                 final bUser = booking['username'] ?? "";
                 final bPlate = booking['plate_number'] ?? "";
                 
                 // Flexible matching
                 bool match = false;
                 if (myUsername != null && bUser == myUsername) match = true;
                 if (myPlate != null && bPlate == myPlate) match = true; // Use simple match
                 
                 if (match) {
                    // Calculate Duration
                    DateTime? start = booking['arrival_time'] != null ? DateTime.tryParse(booking['arrival_time']) : null;
                    DateTime? end = booking['departure_time'] != null ? DateTime.tryParse(booking['departure_time']) : null;
                    String durationStr = "-";
                    if (start != null && end != null) {
                       final d = end.difference(start);
                       final hrs = d.inHours;
                       final mins = d.inMinutes % 60;
                       durationStr = "${hrs}h ${mins}m";
                    } else if (start != null) {
                       // Ongoing?
                       final d = DateTime.now().difference(start);
                       final hrs = d.inHours;
                       final mins = d.inMinutes % 60;
                       durationStr = "${hrs}h ${mins}m (Active)";
                    }
                    
                    // Parse Price
                    String price = booking['price']?.toString() ?? "0";
                    if (booking['payment_status'] == 'Paid') {
                       // price is already set
                    }
                    
                    detectedHistory.add(ParkingHistoryEntry(
                      slotName: slotName,
                      plateNumber: bPlate,
                      date: booking['date'] != null ? _formatDate(booking['date']) : "-",
                      arrivalTime: booking['arrival_time'] != null ? _formatTime(booking['arrival_time']) : "-",
                      departureTime: booking['departure_time'] != null ? _formatTime(booking['departure_time']) : "-",
                      price: price,
                      duration: durationStr,
                      status: booking['status'] ?? "-",
                    ));
                 }
              }
           }
        }
        
        // Sort by date desc (if possible, but date format varies. putting latest first in list if we appended order)
        // Usually API returns chronological, so reversing might show latest.
        // detectedHistory = detectedHistory.reversed.toList();

        if (mounted) {
          setState(() {
            _history = detectedHistory.reversed.toList();
            _isLoading = false;
          });
        }
      } else {
         setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _getLastPlate() async {
     // We can try to get from SharedPreferences like in parking screen
     // But imports might be an issue if we don't add shared_preferences.
     // Assuming user mostly matches by username.
     // But for now return null or add import if we really need it.
     return null; 
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('yyyy-MM-dd').format(d);
    } catch (e) { return iso; }
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('HH:mm').format(d);
    } catch (e) { return iso; }
  }

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
            colors: [Color(0xFF3F51B5), Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
              ? const Center(child: Text("No parking history found."))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(entry.slotName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: entry.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(8)
                                   ),
                                   child: Text(entry.status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: entry.status == 'completed' ? Colors.green : Colors.orange)),
                                 )
                               ],
                             ),
                             const Divider(),
                             const SizedBox(height: 5),
                             _buildRow(Icons.directions_car, "Plate No:", entry.plateNumber),
                             _buildRow(Icons.calendar_today, "Date:", entry.date),
                             _buildRow(Icons.access_time, "Duration:", entry.duration),
                             _buildRow(Icons.monetization_on, "Price:", "Rs. ${entry.price}"),
                             const SizedBox(height: 5),
                             Text("Timing: ${entry.arrivalTime} - ${entry.departureTime}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

