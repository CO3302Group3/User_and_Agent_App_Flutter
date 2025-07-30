import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Bikestatus extends StatefulWidget {
  @override
  State<Bikestatus> createState() => _BikestatusState();
}

class _BikestatusState extends State<Bikestatus> {
  bool isBluetoothConnected = false;
  bool _locationEnabled = false;
  GoogleMapController? _mapController;

  // Initial map position
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(6.8416, 79.9028),
    zoom: 13.0,
  );

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchBikeLocation(); // Fetch location on startup
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bike Status",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: SafeArea(
        child: Container(
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
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Bluetooth card
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFC5CAE9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth, color: Colors.black, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBluetoothConnected
                              ? "Bluetooth Connected"
                              : "Tap to Pair with Bike",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isBluetoothConnected = true;
                          });
                        },
                        child: Text("Pair"),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Google Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: GoogleMap(
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      initialCameraPosition: _initialCameraPosition,
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Status Row
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade400,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      statusCard("Battery", "85%", Icons.battery_full, Colors.green),
                      statusCard("Heartbeat", "Active", Icons.favorite, Colors.red),
                      statusCard("Lock", "Locked", Icons.lock, Colors.blue),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Report button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle report
                    },
                    icon: Icon(Icons.report, color: Colors.white),
                    label: Text(
                      "Report Theft / Issue",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget for status cards
  Widget statusCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          title,
          style: TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Fetch bike location from API
  Future<void> _fetchBikeLocation() async {
    final url = Uri.parse("http://192.168.8.146/telemetry/latest/BIKE000000");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final telemetry = data['telemetry'];
        double latitude = telemetry['lat'] ?? 0.0;
        double longitude = telemetry['long'] ?? 0.0;


        print("$latitude,$longitude");
        // Update marker and camera position
        setState(() {
          _markers = {
            Marker(
              markerId: MarkerId("bike"),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: "Bike Location"),
            ),
          };

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 16),
          );
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching bike location: $e");
    }
  }
}
