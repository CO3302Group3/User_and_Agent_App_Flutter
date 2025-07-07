import 'package:computer_engineering_project/Agents/UsersParkinghistory.dart';
import 'package:flutter/material.dart';
import 'AddParkingSlotScreen.dart';
import 'parking_slot.dart';

class ManageParkingSlotsScreen extends StatefulWidget {
  const ManageParkingSlotsScreen({super.key});

  @override
  State<ManageParkingSlotsScreen> createState() => _ManageParkingSlotsScreenState();
}

class _ManageParkingSlotsScreenState extends State<ManageParkingSlotsScreen> {
  List<ParkingSlot> slots = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: slots.isEmpty
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
                        if (updatedSlot != null && updatedSlot is ParkingSlot) {
                          setState(() {
                            slots[index] = updatedSlot;
                          });
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
                          setState(() {
                            slots.removeAt(index);
                          });
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

          if (newSlot != null && newSlot is ParkingSlot) {
            setState(() => slots.add(newSlot));
          }
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
