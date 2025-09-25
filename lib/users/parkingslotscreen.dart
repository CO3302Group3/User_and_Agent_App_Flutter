import 'package:computer_engineering_project/users/ParkingHistoryScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class Parkingslotscreen extends StatefulWidget {
  const Parkingslotscreen({super.key});

  @override
  State<Parkingslotscreen> createState() => _ParkingslotscreenState();
}

class _ParkingslotscreenState extends State<Parkingslotscreen> {
  LatLng? _currentLocation;

  final List<LatLng> _parkingSlots = [
    LatLng(6.8400, 79.8910),
    LatLng(6.8522, 79.8862),
  ];

  GoogleMapController? _googleMapController;
  Set<Polyline> _polylines = {};

  LatLng? _selectedParkingSlot;
  LatLng? _reservedSlot;
  bool _showReserveButton = false;

  bool _isCheckedIn = false;
  DateTime? _checkInTime;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    // Get current location
    final Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = _deg2rad(end.latitude - start.latitude);
    final dLon = _deg2rad(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Future<void> _makePayment(int price) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payment Successful"),
        content: Text("Rs. $price paid. Slot booked."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleCheckInOut() {
    if (!_isCheckedIn) {
      setState(() {
        _isCheckedIn = true;
        _checkInTime = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checked In at ${_checkInTime!.toLocal()}")),
      );
    } else {
      final DateTime checkOutTime = DateTime.now();
      final Duration parkedDuration = checkOutTime.difference(_checkInTime!);
      final int minutesParked = parkedDuration.inMinutes;
      final int cost = minutesParked * 2;

      setState(() {
        _isCheckedIn = false;
        _checkInTime = null;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Check-Out Complete"),
          content: Text("Parked for $minutesParked minutes.\nTotal: Rs. $cost"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final slot = _selectedParkingSlot ?? _parkingSlots.first;
    final distanceKm = _calculateDistance(_currentLocation!, slot);
    final durationMin = (distanceKm / 40 * 60).round();
    final price = (distanceKm * 50).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Slot", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Parkinghistoryscreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 13.0),
              onMapCreated: (controller) => _googleMapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId("current_location"),
                  position: _currentLocation!,
                  infoWindow: const InfoWindow(title: "You are here"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                ..._parkingSlots.map((slot) {
                  return Marker(
                    markerId: MarkerId(slot.toString()),
                    position: slot,
                    infoWindow: const InfoWindow(title: "Parking Slot"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      _reservedSlot == slot
                          ? BitmapDescriptor.hueAzure
                          : BitmapDescriptor.hueRed,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedParkingSlot = slot;
                        _showReserveButton = true;
                      });
                    },
                  );
                }).toSet(),
              },
              polylines: _polylines,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Distance: ${distanceKm.toStringAsFixed(2)} km",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text("Duration: ~${durationMin} min"),
                        Text("Price: Rs. $price", style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _makePayment(price),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: const Text("Book Now", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _googleMapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            min(_currentLocation!.latitude, slot.latitude),
                            min(_currentLocation!.longitude, slot.longitude),
                          ),
                          northeast: LatLng(
                            max(_currentLocation!.latitude, slot.latitude),
                            max(_currentLocation!.longitude, slot.longitude),
                          ),
                        ),
                        100,
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text("Navigate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size.fromHeight(30),
                  ),
                ),
                const SizedBox(height: 10),
                if (_showReserveButton)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedParkingSlot != null) {
                        setState(() {
                          _reservedSlot = _selectedParkingSlot;
                          _polylines.clear();
                          _polylines.add(Polyline(
                            polylineId: const PolylineId("route"),
                            color: Colors.blue,
                            width: 5,
                            points: [_currentLocation!, _reservedSlot!],
                          ));
                        });
                      }
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text("Reserve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size.fromHeight(30),
                    ),
                  ),
                const SizedBox(height: 10),
                if (_reservedSlot != null)
                  ElevatedButton.icon(
                    onPressed: _handleCheckInOut,
                    icon: Icon(_isCheckedIn ? Icons.logout : Icons.login),
                    label: Text(_isCheckedIn ? "Check Out" : "Check In"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCheckedIn ? Colors.red : Colors.green,
                      minimumSize: const Size.fromHeight(30),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
