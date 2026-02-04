import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';
import 'package:intl/intl.dart';

class Usersparkinghistory extends StatefulWidget {
  const Usersparkinghistory({super.key});

  @override
  State<Usersparkinghistory> createState() => _UsersparkinghistoryState();
}

class _UsersparkinghistoryState extends State<Usersparkinghistory> {
  bool isLoading = true;
  List<Map<String, dynamic>> historyData = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final token = await TokenStorageFallback.getToken();
      if (token == null) return;

      final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = data['parking_slots'] as List<dynamic>;
        List<Map<String, dynamic>> loadedHistory = [];

        for (var slot in slots) {
           final bookings = slot['bookings'] as List<dynamic>? ?? [];
           for (int i = 0; i < bookings.length; i++) {
             final b = bookings[i];
             // Only show completed bookings in History? Or all? User said "update history screen" 
             // usually implies completed. But let's show 'completed' ones primarily or sorted by date.
             // We'll show 'completed' ones as they have duration.
             if (b['status'] == 'completed') {
                loadedHistory.add({
                  'slotId': slot['id'] ?? slot['slot_id'],
                  'bookingIndex': i,
                  'name': b['username'] ?? "Unknown",
                  'plate': b['plate_number'] ?? "?",
                  'price': b['price'] ?? "0",
                  'date': b['date'] ?? "",
                  'arrival': b['arrival_time'],
                  'departure': b['departure_time'],
                  'payment': b['payment_method'] ?? "Cash",
                  'bookings': bookings // Reference for delete
                });
             }
           }
        }
        
        // Sort by date desc
        loadedHistory.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

        setState(() {
          historyData = loadedHistory;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteHistory(int index) async {
      // To delete, we need to remove from the backend list.
      // This is expensive/tricky if lists are long, but we'll do it by slot update.
      final item = historyData[index];
      final String slotId = item['slotId'];
      final List<dynamic> bookings = List.from(item['bookings']); // Copy
      final int bookingIndex = item['bookingIndex'];

      // Remove at index? 
      // Problem: 'bookings' list in 'item' might be stale if multiple items from same slot are processed?
      // Actually, if we just remove THIS item from the bookings list...
      // But we need to match the exact object or refetch.
      // Easiest is to remove by contents or unique ID. We don't have unique Booking ID.
      // We will assume exact object reference match or index if loop order preserved.
      // Better: Remove by arrival_time + plate signature.
      
      bookings.removeWhere((b) => 
          b['plate_number'] == item['plate'] && 
          b['arrival_time'] == item['arrival']
      );

      try {
        final token = await TokenStorageFallback.getToken();
        if (token == null) return;
        
        // We likely need valid 'occupied' count too. Fetch fresh slot or assume no change for history delete.
        // Safer to just send bookings update if backend supports partial? No, standard PUT replaces.
        // We must preserve 'occupied'.
        // Quick fetch current slot state to be safe.
        final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/$slotId');
        final getResp = await http.get(url, headers: {'Content-Type': 'application/json'});
        final currentSlot = jsonDecode(getResp.body);
        int currentOccupied = currentSlot['occupied'];
        List<dynamic> currentBookings = currentSlot['bookings'] ?? [];
        
        // Remove locally from fetched list
        currentBookings.removeWhere((b) => 
           b['plate_number'] == item['plate'] && 
           b['arrival_time'] == item['arrival']
        );

         final body = jsonEncode({
           "payload": {
             "bookings": currentBookings,
             "occupied": currentOccupied
           },
           "authorization": { "token": token }
         });

         await http.put(url, headers: {'Content-Type': 'application/json'}, body: body);
         
         setState(() {
           historyData.removeAt(index);
         });
         
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted")));

      } catch(e) {
        print("Delete error: $e");
      }
  }

  String _calculateDuration(String? start, String? end) {
    if (start == null || end == null) return "-";
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final diff = e.difference(s);
      final hrs = diff.inHours;
      final mins = diff.inMinutes.remainder(60);
      return "${hrs}h ${mins}m";
    } catch (_) { return "-"; }
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'card': return Colors.blueAccent;
      case 'online': return Colors.purpleAccent;
      case 'cash': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Parking History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        centerTitle: true,
        elevation: 8,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283593), Color(0xFF7986CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : historyData.isEmpty
             ? const Center(child: Text("No History Found", style: TextStyle(color: Colors.white, fontSize: 18)))
             : ListView.builder(
          itemCount: historyData.length,
          itemBuilder: (context, index) {
            final item = historyData[index];
            final paymentMethod = item['payment'] ?? 'Unknown';
            final paymentColor = _paymentColor(paymentMethod);
            final duration = _calculateDuration(item['arrival'], item['departure']);
            
            // Format Date
            String dateFormatted = item['date'];
            try {
               final dt = DateTime.parse(item['date']);
               dateFormatted = DateFormat('yyyy-MM-dd').format(dt);
            } catch(_) {}

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: paymentColor.withOpacity(0.8), width: 2),
              ),
              elevation: 7,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: paymentColor.darken(0.4),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: paymentColor.darken(0.3)),
                          onSelected: (value) async {
                            if (value == 'delete') {
                               await _deleteHistory(index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.directions_bike, "Plate", item['plate'], paymentColor),
                    const SizedBox(height: 10),
                    _infoRow(Icons.date_range, "Date", dateFormatted, paymentColor),
                    const SizedBox(height: 10),
                    _infoRow(Icons.timelapse, "Duration", duration, paymentColor),
                    const SizedBox(height: 10),
                    _infoRow(Icons.currency_rupee, "Price", "LKR ${item['price']}", paymentColor),
                    const SizedBox(height: 12),
                    Row(
                        children: [
                          Icon(Icons.payment, color: paymentColor.darken(0.3), size: 22),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: paymentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              paymentMethod.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.darken(0.3), size: 22),
        const SizedBox(width: 10),
        Text("$label:", style: TextStyle(color: color.darken(0.4), fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: TextStyle(color: color.darken(0.6), fontSize: 16), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
