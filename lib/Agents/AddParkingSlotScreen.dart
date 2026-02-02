import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'parking_slot.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart' as main;
import '../services/token_storage_fallback.dart';

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
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _slotNameController.text = slot.name;
      _addressController.text = slot.address;
      _priceController.text = slot.price;
      _bikesAllowedController.text = slot.bikesAllowed.toString();
      _totalSpacesController.text = slot.totalSpaces.toString();
      _selectedDays.addAll(slot.availableDays);
      
      _openingTime = _parseTime(slot.openingTime);
      _closingTime = _parseTime(slot.closingTime);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      if (timeStr.isEmpty || timeStr == "Select Time") return null;
      // Format is likely "8:00 AM" or "20:00" depending on backend
      // Using simplistic parsing wrapper or verify format.
      // Assuming "8:00 AM" format from _formatTime
      // We can use DateFormat to parse.
      final dt = DateFormat.jm().parse(timeStr); 
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      print("Error parsing time: $timeStr");
      return null;
    }
  }

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

  Future<void> _saveSlot() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await TokenStorageFallback.getToken();
      
      if (token == null) {
        throw Exception("Authentication token not found. Please login again.");
      }

      final isEdit = widget.existingSlot?.id != null;
      final url = isEdit
          ? Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots/${widget.existingSlot!.id}')
          : Uri.parse('http://${main.appConfig.baseURL}:8004/parking_slots');
      
      final Map<String, dynamic> payloadData = {
        "slot_id": "",
        "name": _slotNameController.text,
        "address": _addressController.text,
        "price": _priceController.text,
        "opening_time": _formatTime(_openingTime),
        "closing_time": _formatTime(_closingTime),
        "available_days": _selectedDays.toList(),
        "bikes_allowed": int.tryParse(_bikesAllowedController.text) ?? 0,
        "total_spaces": int.tryParse(_totalSpacesController.text) ?? 0,
        "status": "pending",
        "assigned_device_id": widget.existingSlot?.assignedDeviceId
      };

      // For PUT, the backend body is just the update object wrapped or direct?
      // Based on usual FastAPI Pydantic models:
      // POST: Body -> Payload (ParkingSlotCreate) + Authorization
      // PUT: Body -> Payload (ParkingSlotUpdate) + Authorization
      // The previous POST used {payload: {...}, authorization: {...}}
      // Let's assume PUT uses the same wrapper structure for consistency with the provided code snippet usage (though standard REST might differ, the backend snippet shows `payload: ParkingSlotUpdate, authorization: TokenRequest`)
      
      // Checking the backend snippet:
      // @app.put("/parking_slots/{slot_id}")
      // async def update_slot(slot_id: str, payload: ParkingSlotUpdate, authorization: TokenRequest):
      // It expects the body to contain fields from ParkingSlotUpdate AND authorization? 
      // Actually, FastAPI with multiple body params usually expects a JSON object where keys match the param names.
      // So { "payload": {...}, "authorization": {...} } is correct for both.

      // However, for POST:
      // @app.post("/parking_slots", response_model=ApiResponse)
      // async def create_slot(payload: ParkingSlotCreate, authorization: TokenRequest):
      // Correct.
      
      // For PUT:
      // payload: ParkingSlotUpdate (fields are optional)
      // In Dart, we send all fields we have.

      if (isEdit) {
        // Backend logic for PUT:
        // updates = {k: v for k, v in payload.dict().items() if v is not None}
        // So we can send the same payload structure.
      }
      
      // But wait! ParkingSlotCreate has "slot_id" (optional), ParkingSlotUpdate doesn't usually allow changing ID?
      // Let's remove "slot_id" from payloadData if it was there (it isn't in my map).
      
      if (isEdit) {
        payloadData.remove("slot_id");
      }

      final body = jsonEncode({
        "payload": payloadData,
        "authorization": {
          "token": token
        }
      });

      print("Sending ${isEdit ? 'PUT' : 'POST'} request to $url with body: $body");

      final response = isEdit 
          ? await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response
        // POST returns ApiResponse (data field has the slot)
        // PUT returns updated slot (data?)
        // Backend PUT returns: `return updated` (the slot dict)
        // Backend POST returns: `ApiResponse(..., data=created)`
        
        Map<String, dynamic> data;
        if (isEdit) {
           // PUT returns the dict directly according to snippet: return updated
           data = jsonDecode(response.body); 
        } else {
           // POST returns ApiResponse
           final responseData = jsonDecode(response.body);
           data = responseData['data'];
        }
        
        // Construct ParkingSlot from response data
        final slot = ParkingSlot(
          id: data['id'] ?? data['slot_id'] ?? widget.existingSlot?.id, // Handle _id from mongo mapped to id
          name: data['name'] ?? _slotNameController.text,
          address: data['address'] ?? _addressController.text,
          price: (data['price'] ?? _priceController.text).toString(),
          openingTime: data['opening_time'] ?? _formatTime(_openingTime),
          closingTime: data['closing_time'] ?? _formatTime(_closingTime),
          availableDays: List<String>.from(data['available_days'] ?? _selectedDays.toList()),
          bikesAllowed: data['bikes_allowed'] ?? int.tryParse(_bikesAllowedController.text) ?? 0,
          totalSpaces: data['total_spaces'] ?? int.tryParse(_totalSpacesController.text) ?? 0,
          assignedDeviceId: data['assigned_device_id'] ?? widget.existingSlot?.assignedDeviceId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Parking slot ${isEdit ? 'updated' : 'requested'} successfully! Pending approval.")),
        );
        Navigator.pop(context, slot);
      } else {
        String errorMessage = "Failed to ${isEdit ? 'update' : 'request'} slot";
        try {
            final errorData = jsonDecode(response.body);
            if (errorData['detail'] != null) {
                errorMessage = errorData['detail'];
            }
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Error creating/updating slot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.existingSlot != null ? "Update Parking Slot" : "Request Parking Slot", style: const TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
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
                child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.indigo)
                : ElevatedButton.icon(
                  onPressed: _saveSlot,
                  icon: const Icon(Icons.save),
                  label: Text(widget.existingSlot != null ? "Update Slot" : "Request Slot"),
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
      ),
    );
  }
}
