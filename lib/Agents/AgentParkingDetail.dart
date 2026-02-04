import 'dart:convert';
import 'package:computer_engineering_project/Agents/Members.dart';
import 'package:computer_engineering_project/Agents/receivepayment.dart';
import 'package:computer_engineering_project/Agents/parking_slot.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:computer_engineering_project/Agents/Requests.dart';
import 'package:http/http.dart' as http;
import '../main.dart' as main;

class AgentParkingDetail extends StatefulWidget {
  final ParkingSlot slot;

  const AgentParkingDetail({super.key, required this.slot});

  @override
  State<AgentParkingDetail> createState() => _AgentParkingDetailState();
}

class _AgentParkingDetailState extends State<AgentParkingDetail> {
  late int occupied;
  int? refreshedOccupied;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    occupied = widget.slot.occupied;
    _bookings = widget.slot.bookings;
    _fetchLatestSlotDetails(); // Auto-refresh on load
  }

  Future<void> _fetchLatestSlotDetails() async {
    if (widget.slot.id == null) return;
    try {
      final url = Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/${widget.slot.id}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
           setState(() {
             refreshedOccupied = data['occupied'] ?? 0;
             occupied = refreshedOccupied!;
             if (data['bookings'] != null) {
               _bookings = List<dynamic>.from(data['bookings']);
             }
           });
        }
      }
    } catch (e) {
      print("Error fetching latest details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculations
    final int capacity = widget.slot.bikesAllowed;
    final int currentOccupied = refreshedOccupied ?? occupied;
    final int available = (capacity - currentOccupied).clamp(0, capacity);
    
    // Area Calculation: (Total Area / Bikes Allowed) * Occupied
    final double totalArea = widget.slot.totalSpaces.toDouble();
    final double areaPerBike = capacity > 0 ? totalArea / capacity : 0;
    
    final double occupiedArea = areaPerBike * currentOccupied;
    final double availableArea = totalArea - occupiedArea;
    
    // Safety for chart
    final double occupiedVal = currentOccupied.toDouble();
    final double availableVal = available.toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.slot.name, style: const TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // Address & Price Info
               Card(
                color: Colors.indigo.shade400,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                       Text("📍 ${widget.slot.address}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                       const SizedBox(height: 5),
                       Text("💸 Price: ${widget.slot.price} LKR/hr", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
               ),

              const SizedBox(height: 20),

              // --- Stat Cards ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatCard(
                    icon: Icons.local_parking,
                    title: "Occupied Area",
                    area: "${occupiedArea.toStringAsFixed(1)} ft²",
                    color: Colors.redAccent,
                  ),
                  StatCard(
                    icon: Icons.park,
                    title: "Available Area",
                    area: "${availableArea.toStringAsFixed(1)} ft²",
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
                  children: [
                    const Text(
                      "Total Capacity",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$currentOccupied / $capacity Bikes",
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "(${widget.slot.totalSpaces} car spaces)",
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                                  value: occupiedVal > 0 ? occupiedVal : 1, // Fallback to show something if 0
                                  color: occupiedVal > 0 ? Colors.redAccent : Colors.grey,
                                  title: '$currentOccupied',
                                  titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                PieChartSectionData(
                                  value: availableVal,
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
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                           // Go to Members list
                           await Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (context) => Members(slotId: widget.slot.id ?? ""))
                           );
                           // Refresh data on return
                           _fetchLatestSlotDetails();
                        },
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: const Text("View Members & Bookings", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DashboardTile(
                      icon: Icons.attach_money,
                      title: "Payments", // Updated Title
                      color: Colors.teal,
                      onTap: () {
                        // Show Booking History
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                          ),
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Booking History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  if (_bookings.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Center(child: Text("No bookings yet.")),
                                    )
                                  else
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _bookings.length,
                                        separatorBuilder: (_,__) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final booking = _bookings[_bookings.length - 1 - index]; // Show latest first
                                          final name = booking['username'] ?? 'Unknown';
                                          final price = booking['price'] ?? '0';
                                          final plate = booking['plate_number'] ?? '-';
                                          final paymentMethod = booking['payment_method'] ?? 'Online'; // Default to Online for old bookings
                                          
                                          // Format Dates
                                          final arrivalStr = booking['arrival_time'] ?? booking['date'] ?? '';
                                          final departStr = booking['departure_time'] ?? 'Active';
                                          
                                          String formatTime(String? iso) {
                                            if (iso == null || iso == 'Active' || iso.isEmpty) return "Active";
                                            try {
                                              final dt = DateTime.parse(iso).toLocal();
                                              return "${dt.hour}:${dt.minute.toString().padLeft(2,'0')} ${dt.day}/${dt.month}";
                                            } catch (e) { return iso; }
                                          }

                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 5),
                                            child: ListTile(
                                              leading: CircleAvatar(child: Text(name.substring(0,1).toUpperCase())),
                                              title: Text("$name ($plate)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("In: ${formatTime(arrivalStr)}"),
                                                  Text("Out: ${formatTime(departStr)}"),
                                                ],
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text("Rs. $price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                                  Text(paymentMethod, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ),
                                              isThreeLine: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
