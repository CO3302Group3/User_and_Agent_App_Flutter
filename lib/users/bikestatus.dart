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
  bool isRideMode = false;
  GoogleMapController? _mapController;

  double batteryLevel = 0.0;
  String heartbeatStatus = "Inactive";
  String bikeMode = "lock";

  // Initial map position
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(6.8132, 79.9655),
    zoom: 16.0,
  );

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchBikeLocation();
    _fetchBikeHealth();
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

                // Status Row (Battery, Heartbeat, Lock/Drive Icon)
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
                      // ✅ Use dynamic battery value
                      statusCard("Battery", "${batteryLevel.toStringAsFixed(1)}%", Icons.battery_full, Colors.green),

                      // ✅ Use dynamic heartbeat value
                      statusCard("Heartbeat", heartbeatStatus, Icons.favorite, Colors.red),

                      // ✅ Mode Icon & Text from API
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: (bikeMode.toLowerCase() == "ride"
                                ? Colors.green
                                : Colors.blue)
                                .withOpacity(0.2),
                            child: Icon(
                              bikeMode.toLowerCase() == "ride"
                                  ? Icons.directions_bike
                                  : Icons.lock,
                              color: bikeMode.toLowerCase() == "ride"
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bikeMode.isNotEmpty ? bikeMode.toUpperCase() : "UNKNOWN",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: bikeMode.toLowerCase() == "ride"
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Mode",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                SizedBox(height: 10),

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

                // Toggle Button for Lock Mode / Driving Mode
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRideMode = !isRideMode;
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        (isRideMode ? Colors.green : Colors.blue).withOpacity(0.2),
                        child: Icon(
                          isRideMode ? Icons.directions_bike : Icons.lock,
                          color: isRideMode ? Colors.green : Colors.blue,
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        isRideMode ? "Driving Mode" : "Lock Mode",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
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
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  /// Fetch bike health from API
  Future<void> _fetchBikeHealth() async {
    final url = Uri.parse("http://192.168.8.146/device_health/BIKE000000/latest");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final health = data['health'];

        setState(() {
          batteryLevel = (health['battery'] ?? 0.0).toDouble();
          heartbeatStatus = health['heartbeat'] ?? "Inactive";
          bikeMode = health['mode'] ?? "lock";
          isRideMode = (bikeMode.toLowerCase() == "ride");
        });
      } else {
        print("Error fetching health: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching bike health: $e");
    }
  }
}
