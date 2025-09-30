import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'parking_slot.dart';

class AddParkingSlotScreen extends StatefulWidget {
  final ParkingSlot? existingSlot;
  const AddParkingSlotScreen({Key? key, this.existingSlot}) : super(key: key);

  @override
  State<AddParkingSlotScreen> createState() => _AddParkingSlotScreenState();
}

class _AddParkingSlotScreenState extends State<AddParkingSlotScreen> {
  final TextEditingController _slotNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _bikesAllowedController = TextEditingController();
  final TextEditingController _totalSpacesController = TextEditingController();

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  final Set<String> _selectedDays = {};

  final List<String> _daysOfWeek = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple.shade700),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
      ),
      labelStyle: TextStyle(
          color: Colors.deepPurple.shade800, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _selectTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Select Time";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  void _saveSlot() {
    if (_slotNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _openingTime == null ||
        _closingTime == null ||
        _selectedDays.isEmpty ||
        _bikesAllowedController.text.isEmpty ||
        _totalSpacesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final slot = ParkingSlot(
      name: _slotNameController.text,
      address: _addressController.text,
      price: _priceController.text,
      openingTime: _formatTime(_openingTime),
      closingTime: _formatTime(_closingTime),
      availableDays: _selectedDays.toList(),
      bikesAllowed: int.tryParse(_bikesAllowedController.text) ?? 0,
      totalSpaces: int.tryParse(_totalSpacesController.text) ?? 0,
    );

    Navigator.pop(context, slot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Add Parking Slot", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _slotNameController,
                decoration: _customInputDecoration("Parking Slot Name", Icons.local_parking),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: _customInputDecoration("Address", Icons.location_on),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectTime(true),
                      icon: const Icon(Icons.access_time),
                      label: Text("Opening: ${_formatTime(_openingTime)}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectTime(false),
                      icon: const Icon(Icons.access_time_filled),
                      label: Text("Closing: ${_formatTime(_closingTime)}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                "Available Days:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daysOfWeek.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day, style: const TextStyle(color: Colors.white)),
                    selected: selected,
                    selectedColor: Colors.deepPurple.shade200,
                    backgroundColor: Colors.indigo,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _totalSpacesController,
                keyboardType: TextInputType.number,
                decoration: _customInputDecoration("Parking space area", Icons.event_seat),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bikesAllowedController,
                keyboardType: TextInputType.number,
                decoration: _customInputDecoration("Bikes Allowed", Icons.directions_bike),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _customInputDecoration("Price (LKR/hour)", Icons.currency_rupee),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveSlot,
                  icon: const Icon(Icons.save),
                  label: const Text("Add Slot"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    ),
    );
  }
}
