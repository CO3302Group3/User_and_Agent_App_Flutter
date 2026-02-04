import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';

class Requests extends StatefulWidget {
  const Requests({super.key});

  @override
  State<Requests> createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  bool isLoading = true;
  List<Map<String, dynamic>> arrivalRequests = [];
  List<Map<String, dynamic>> departureRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final token = await TokenStorageFallback.getToken();
      if (token == null) return;

      final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = data['parking_slots'] as List<dynamic>;

        final List<Map<String, dynamic>> newArrivals = [];
        final List<Map<String, dynamic>> newDepartures = [];

        for (var slot in slots) {
          final bookings = slot['bookings'] as List<dynamic>? ?? [];
          for (int i = 0; i < bookings.length; i++) {
            final b = bookings[i];
            final status = b['status'] ?? 'booked';
            
            // Enrich with slotId and index for update
            final reqData = {
              "slotId": slot['id'] ?? slot['slot_id'],
              "bookingIndex": i,
              "name": b['username'] ?? "Unknown",
              "plate_number": b['plate_number'] ?? "?",
              "price": b['price'] ?? "0",
              "bookings": bookings, // Needed for full update
              "occupied": slot['occupied'] ?? 0,
              "bikes_allowed": slot['bikes_allowed'] ?? 0
            };

            if (status == 'check_in_requested') {
              newArrivals.add(reqData);
            } else if (status == 'check_out_requested') {
              newDepartures.add(reqData);
            }
          }
        }
        
        setState(() {
          arrivalRequests = newArrivals;
          departureRequests = newDepartures;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching requests: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmRequest(Map<String, dynamic> req, bool isArrival, {String? confirmedPlate}) async {
    try {
       final token = await TokenStorageFallback.getToken();
       if (token == null) return;

       final String slotId = req['slotId'];
       final List<dynamic> bookings = List.from(req['bookings']);
       final int index = req['bookingIndex'];
       int occupied = req['occupied'];
       
       // Update Status & Time
       if (isArrival) {
         bookings[index]['status'] = 'active';
         bookings[index]['arrival_time'] = DateTime.now().toIso8601String();
         if (confirmedPlate != null) {
            bookings[index]['plate_number'] = confirmedPlate;
         }
         // Occupancy already incremented on book? Yes, user side incremented it on book. 
         // So we just confirm.
       } else {
         bookings[index]['status'] = 'completed';
         bookings[index]['departure_time'] = DateTime.now().toIso8601String();
         // Check out -> Decrement Occupancy
         occupied = occupied - 1;
         if (occupied < 0) occupied = 0;
       }

       final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/$slotId');
       final body = jsonEncode({
         "payload": {
           "bookings": bookings,
           "occupied": occupied
         },
         "authorization": { "token": token }
       });

       final response = await http.put(
         url, 
         headers: {'Content-Type': 'application/json'},
         body: body
       );

       if (response.statusCode == 200) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmed Successfully")));
         _fetchRequests(); // Refresh
       } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
       }
    } catch (e) {
      print("Error confirming: $e");
    }
  }

  void _showArrivalDialog(Map<String, dynamic> item) {
    TextEditingController plateCtrl = TextEditingController(text: item['plate_number']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Check-In: ${item['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: "Confirm Plate Number"),
              ),
              const SizedBox(height: 10),
              Text("Price: Rs. ${item['price']}"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmRequest(item, true, confirmedPlate: plateCtrl.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm Arrival"),
            ),
          ],
        );
      },
    );
  }

  void _showDepartureDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Check-Out: ${item['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Plate: ${item['plate_number']}"),
              const SizedBox(height: 10),
              Text("Price: Rs. ${item['price']}"),
              const SizedBox(height: 10),
              const Text("Departure time will be logged now."),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmRequest(item, false); // Departure
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Confirm Departure"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Requests"), backgroundColor: Colors.indigo),
      body: isLoading 
         ? const Center(child: CircularProgressIndicator())
         : ListView(
           padding: const EdgeInsets.all(16),
           children: [
             if (arrivalRequests.isEmpty && departureRequests.isEmpty)
               const Center(child: Text("No Pending Requests")),
             
             if (arrivalRequests.isNotEmpty) ...[
               const Text("Arrivals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ...arrivalRequests.map((item) => Card(
                 child: ListTile(
                   leading: const Icon(Icons.login, color: Colors.green),
                   title: Text(item['name']),
                   subtitle: Text("Plate: ${item['plate_number']} | Rs. ${item['price']}"),
                   trailing: ElevatedButton(
                     onPressed: () => _showArrivalDialog(item),
                     child: const Text("Confirm"),
                   ),
                 ),
               )),
             ],
             const SizedBox(height: 20),
             if (departureRequests.isNotEmpty) ...[
               const Text("Departures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ...departureRequests.map((item) => Card(
                 child: ListTile(
                   leading: const Icon(Icons.logout, color: Colors.red),
                   title: Text(item['name']),
                   subtitle: Text("Plate: ${item['plate_number']} | Rs. ${item['price']}"),
                   trailing: ElevatedButton(
                     onPressed: () => _showDepartureDialog(item),
                     child: const Text("Confirm"),
                   ),
                 ),
               )),
             ]
           ],
         ),
    );
  }
}
