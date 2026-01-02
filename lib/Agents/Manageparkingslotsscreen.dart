import 'package:computer_engineering_project/Agents/UsersParkinghistory.dart';
import 'package:flutter/material.dart';
import 'AddParkingSlotScreen.dart';
import 'parking_slot.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';

class ManageParkingSlotsScreen extends StatefulWidget {
  const ManageParkingSlotsScreen({super.key});

  @override
  State<ManageParkingSlotsScreen> createState() => _ManageParkingSlotsScreenState();
}

class _ManageParkingSlotsScreenState extends State<ManageParkingSlotsScreen> {
  bool _isLoading = true;
  List<ParkingSlot> slots = [];

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoading = true);
    try {
      final token = await TokenStorageFallback.getToken();
      if (token == null) {
        print("No token found");
        setState(() => _isLoading = false);
        return;
      }
      
      final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['parking_slots'] != null) {
          final List<dynamic> items = data['parking_slots'];
          setState(() {
            slots = items.map((item) => ParkingSlot(
              id: item['id'] ?? item['slot_id'],
              name: item['name'] ?? '',
              address: item['address'] ?? '',
              price: item['price'] != null ? item['price'].toString() : '0',
              openingTime: item['opening_time'] ?? '',
              closingTime: item['closing_time'] ?? '',
              availableDays: List<String>.from(item['available_days'] ?? []),
              bikesAllowed: item['bikes_allowed'] ?? 0,
              totalSpaces: item['total_spaces'] ?? 0,
              assignedDeviceId: item['assigned_device_id'],
            )).toList();
          });
        }
      } else {
        print("Failed to fetch slots: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching slots: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(String id, int index) async {
      try {
        final token = await TokenStorageFallback.getToken();
        if (token == null) return;

        final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/$id');
        
        // Backend expects 'authorization' in body? 
        // @app.delete("/parking_slots/{slot_id}")
        // async def delete_slot(slot_id: str, authorization: TokenRequest):
        // Yes, expects body with authorization.
        
        final body = jsonEncode({
          "token": token // TokenRequest model has 'token' field
        });
        
        // Wait! delete requests with body are non-standard but allowed often.
        // FastApi Pydantic model `TokenRequest` has `token`.
        // The signature is `authorization: TokenRequest`.
        // So body should be `{"token": "..."}` matching keys of TokenRequest.
        // But wait, the previous endpoints used wrapped structure: `authorization: {token: ...}`
        // In `delete_slot`, the param name is `authorization`, typed `TokenRequest`.
        // In `create_slot`, params were `payload`, `authorization`.
        
        // If FastAPI is using standard Body inference:
        // For `delete_slot(..., authorization: TokenRequest)`:
        // It expects JSON body: `{ "token": "..." }` ?? 
        // OR `{ "authorization": { "token": "..." } }` ??
        
        // Usually, multiple body params => keys match params. Single body param => body matches model logic (unless embed=True).
        // create_slot has 2 params => expects JSON with keys "payload" and "authorization".
        // delete_slot has 1 body param (authorization) => usually expects body to BE the TokenRequest model fields directly? 
        // IE: `{"token": "..."}`.
        // UNLESS the backend uses `Body(..., embed=True)`.
        
        // Let's try sending `{"token": "..."}` first, as it's a single Pydantic model.
        // Actually, looking at `create_slot`, it accepts `authorization: TokenRequest`.
        // If consistency is maintained, it might be safer to try valid JSON that matches the param name if FastAPI requires it?
        // But standard FastAPI with 1 Pydantic param = Body is the model.
        
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
           setState(() {
             slots.removeAt(index);
           });
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Slot deleted successfully')),
           );
        } else {
           // Fallback: maybe it needed { "authorization": { "token": "..." } }?
           // Or Forbidden (403).
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to delete: ${response.body}')),
           );
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: $e')),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Manage Parking Slots", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(context,MaterialPageRoute(builder: (context)=> Usersparkinghistory()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSlots,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : slots.isEmpty
          ? const Center(child: Text("No parking slots available yet."))
          : ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return Card(
            margin: const EdgeInsets.all(10),
            color: Colors.indigo.shade400,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expanded widget to push the menu icon to the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 5),
                        Text("📍 ${slot.address}", style: const TextStyle(color: Colors.white)),
                        Text("💸 ${slot.price} LKR/hr", style: const TextStyle(color: Colors.white)),
                        Text("🕒 ${slot.openingTime} - ${slot.closingTime}", style: const TextStyle(color: Colors.white)),
                        Text("📅 ${slot.availableDays.join(', ')}", style: const TextStyle(color: Colors.white)),
                        Text("🅿️ Total Parking Spaces: ${slot.totalSpaces}"),
                        Text("🚲 Bikes Allowed: ${slot.bikesAllowed}"),

                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updatedSlot = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddParkingSlotScreen(existingSlot: slot),
                          ),
                        );
                        if (updatedSlot != null) {
                           _fetchSlots(); // Refresh list to get updated state
                        }

                      } else if (value == 'delete') {
                        // Confirm delete dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Slot'),
                            content: const Text('Are you sure you want to delete this parking slot?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );

                        if (confirm == true) {
                           if (slot.id != null) {
                             await _deleteSlot(slot.id!, index);
                           } else {
                             // Local only delete?
                             setState(() {
                               slots.removeAt(index);
                             });
                           }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newSlot = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddParkingSlotScreen()),
          );

          if (newSlot != null) {
            // Refresh list from server to get clean state (including auto-generated IDs)
            _fetchSlots();
          }
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
