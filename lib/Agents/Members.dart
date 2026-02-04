import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';

class Members extends StatefulWidget {
  final String slotId;
  const Members({super.key, required this.slotId});

  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  List<dynamic> _bookings = [];
  List<dynamic> _members = [];
  int _occupiedCount = 0; // Track occupancy
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    if (widget.slotId.isEmpty) return;
    try {
      final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/${widget.slotId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _bookings = data['bookings'] as List<dynamic>? ?? [];
            _members = data['members'] as List<dynamic>? ?? [];
            _occupiedCount = data['occupied'] ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching members: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateBackend({List<dynamic>? bookings, List<dynamic>? members, int? occupied}) async {
     try {
       final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/${widget.slotId}');
       final token = await TokenStorageFallback.getToken();
       if (token == null) return;
       
       final Map<String, dynamic> innerPayload = {};
       if (bookings != null) innerPayload['bookings'] = bookings;
       if (members != null) innerPayload['members'] = members;
       if (occupied != null) innerPayload['occupied'] = occupied;

       final body = jsonEncode({
          "payload": innerPayload,
          "authorization": { "token": token }
       });

       final response = await http.put(
         url,
         headers: {
           'Content-Type': 'application/json',
           // 'Authorization': 'Bearer $token' // Not needed if body auth is used, but keeping it invalidates nothing usually.
         },
         body: body,
       );

       if (response.statusCode == 200) {
         _fetchMembers(); 
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully")));
       } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
       }
     } catch(e) {
       print("Error updating: $e");
     }
  }

  void _addMember() {
    final nameCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Member"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: "Plate Number")),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Arrival: "),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: selectedTime);
                        if (t != null) setDialogState(() => selectedTime = t);
                      }, 
                      child: Text(selectedTime.format(context))
                    )
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                
                final newMember = {
                  "name": nameCtrl.text,
                  "plate_number": plateCtrl.text,
                  "phone_number": phoneCtrl.text,
                  "arrival_time": selectedTime.format(context),
                  "payment_method": "Cash", // Default or add picker
                };
                
                final updatedList = List.from(_members)..add(newMember);
                _updateBackend(members: updatedList); // Just updating members list, not affecting 'occupied' explicitly unless desired? 
                // Usually manual members don't count towards 'occupied' logic for automatic slots? 
                // Or maybe they DO. If they occupy a slot, they should.
                // But for now, let's keep it safe and only touch occupied on delete if user asked.
                Navigator.pop(context);
              }, 
              child: const Text("Add")
            )
          ],
        ),
      ),
    );
  }

  void _deleteMember(int index) {
      // Determine if index is in Bookings or Members
      bool isBooking = index < _bookings.length;
      
      showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBooking ? "Delete Booking?" : "Delete Member?"),
        content: Text(isBooking 
           ? "This will remove the booking and free the slot."
           : "This will remove the member from the list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (isBooking) {
                  final updatedBookings = List.from(_bookings)..removeAt(index);
                  // Decrement Occupancy
                  int newOccupancy = _occupiedCount - 1;
                  if (newOccupancy < 0) newOccupancy = 0;
                  
                  _updateBackend(bookings: updatedBookings, occupied: newOccupancy);
              } else {
                  final memberIndex = index - _bookings.length;
                  final updatedMembers = List.from(_members)..removeAt(memberIndex);
                  _updateBackend(members: updatedMembers);
              }
              Navigator.pop(ctx);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'card': return Colors.blueAccent;
      case 'cash': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    final displayList = [..._bookings, ..._members];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members & Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : displayList.isEmpty 
               ? const Center(child: Text("No members or bookings found."))
               : ListView.separated(
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final member = displayList[index];
                    final name = member['username'] ?? member['name'] ?? 'Unknown'; // Booking uses username
                    final plate = member['plate_number'] ?? '-';
                    final arrival = member['arrival_time'] ?? '-';
                    final phone = member['phone_number'] ?? '-';
                    final price = member['price'] ?? '-'; // Fetch Price

                    return Material(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(22),
                      elevation: 6,
                      child: InkWell(
                        onLongPress: () => _deleteMember(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.indigo.shade400,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF283593))),
                                    const SizedBox(height: 6),
                                    _infoRow(Icons.directions_car, 'Plate', plate),
                                    const SizedBox(height: 4),
                                    // Format Time: Parse and show strictly YYYY-MM-DD HH:MM or similar
                                    Builder(
                                      builder: (context) {
                                        String rawTime = (arrival != '-' && arrival != null) ? arrival : (member['date'] ?? '-');
                                        String displayTime = rawTime;
                                        try {
                                           // Attempt cleanup if it contains strict timezone info
                                            if (rawTime.contains("T")) {
                                              DateTime dt = DateTime.parse(rawTime);
                                              // Manual format: YYYY-MM-DD HH:MM
                                              displayTime = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
                                            } else if (rawTime.length > 19) {
                                               displayTime = rawTime.substring(0, 19); 
                                            }
                                        } catch(e) { /* keep raw */ }
                                        return _infoRow(Icons.access_time, 'Time', displayTime);
                                      }
                                    ),
                                    const SizedBox(height: 4),
                                    _infoRow(Icons.monetization_on, 'Price', "Rs. $price (Paid)"),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMember(index),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
