import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class Bikestatus extends StatefulWidget {
  @override
  State<Bikestatus> createState() => _BikestatusState();
}

class _BikestatusState extends State<Bikestatus> {
  bool isBluetoothConnected = false;
  bool _locationEnabled = false;
  GoogleMapController? _mapController;
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(6.8416, 79.9028),
    zoom: 13.0,
  );
  late GoogleMapController _googleMapController;

  @override
  void initState() {
    super.initState();

  }

  // add this at the top



  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  GoogleMap _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(6.9271, 79.8612),
        zoom: 14.0,
      ),
      mapType: MapType.normal,
      myLocationEnabled: _locationEnabled,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
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
                  height: MediaQuery.of(context).size.height * 0.35, // Make it responsive
                  child: GoogleMap(myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (controller) => _googleMapController = controller,),
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
              // Add bottom padding to ensure content is not cut off
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget statusCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withValues(alpha: 0.2),
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
}
