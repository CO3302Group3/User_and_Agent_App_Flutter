import 'package:computer_engineering_project/Agents/AgentParkingDetail.dart';
import 'package:computer_engineering_project/Agents/Requests.dart';
import 'package:computer_engineering_project/Agents/parking_slot.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async'; 
import 'package:http/http.dart' as http;
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';
import '../users/Accountsetting.dart'; 

class Agentdashboard extends StatefulWidget {
  const Agentdashboard({super.key});

  @override
  State<Agentdashboard> createState() => _AgentdashboardState();
}

class _AgentdashboardState extends State<Agentdashboard> {
  bool _isLoading = true;
  List<ParkingSlot> slots = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
    // Auto-refresh every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchSlots(silently: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSlots({bool silently = false}) async {
    if (!silently) {
       setState(() => _isLoading = true);
    }
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
              status: item['status'] ?? 'pending',
              occupied: item['occupied'] ?? 0, // Added occupancy mapping
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Agent Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsPage()));
            },
          ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : slots.isEmpty
                ? const Center(child: Text("No parking slots found."))
                : RefreshIndicator(
                    onRefresh: _fetchSlots,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.white.withOpacity(0.9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AgentParkingDetail(slot: slot),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          slot.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3F51B5),
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          slot.address,
                                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                       // Price Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "${slot.price} LKR/hr",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                        ),
                                      ),
                                      
                                      // Occupancy Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: slot.occupied >= slot.bikesAllowed 
                                              ? Colors.red.withOpacity(0.1) 
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.local_parking, 
                                              size: 16, 
                                              color: slot.occupied >= slot.bikesAllowed ? Colors.red : Colors.green
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${slot.occupied}/${slot.bikesAllowed}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: slot.occupied >= slot.bikesAllowed ? Colors.red : Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
