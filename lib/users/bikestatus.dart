import 'package:computer_engineering_project/main.dart';
import 'package:computer_engineering_project/users/Wifiprovisioningpage.dart';
import 'package:computer_engineering_project/services/esp32_provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'device_list_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_storage_fallback.dart';

class Bikestatus extends StatefulWidget {
  final Map<String, dynamic>? device;

  const Bikestatus({this.device, super.key});

  @override
  State<Bikestatus> createState() => _BikestatusState();
}

class _BikestatusState extends State<Bikestatus> {
  late Esp32ProvisioningService _bleService;
  bool isRideMode = false;
  GoogleMapController? _mapController;
  LatLng? _latestBikePosition;

  double batteryLevel = 0.0;
  String heartbeatStatus = "Inactive";
  String bikeMode = "lock";

  // Get device ID from the selected device
  String get deviceId => widget.device?['device_id'] ?? widget.device?['id'] ?? 'DEVICE0000001';
  String get bikeId => widget.device?['bike_id'] ?? widget.device?['device_id'] ?? widget.device?['id'] ?? 'BIKE000000';

  // Initial map position
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(6.8132, 79.9655),
    zoom: 16.0,
  );
  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case "normal":
        return Icons.home;
      case "theft attempt":
        return Icons.warning;
      case "deep sleep":
        return Icons.bedtime;
      case "tracking":
        return Icons.location_searching;
      case "ride":
        return Icons.directions_bike;
      case "lock":
      default:
        return Icons.lock;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case "normal":
        return Colors.green;
      case "theft attempt":
        return Colors.red;
      case "deep sleep":
        return Colors.grey;
      case "tracking":
        return Colors.orange;
      case "ride":
        return Colors.green;
      case "lock":
      default:
        return Colors.blue;
    }
  }

  // Helper function to map mode numbers to names
  String _getModeName(int modeNumber) {
    switch (modeNumber) {
      case -1:
        return "NUL";
      case 0:
        return "TEST";
      case 1:
        return "THEFT_ATTEMPT";
      case 2:
        return "DEEP_SLEEP";
      case 3:
        return "TRACKING";
      case 4:
        return "RIDE";
      case 5:
        return "LOCK";
      default:
        return "UNKNOWN";
    }
  }

  // Helper function to map heartbeat number to status
  String _getHeartbeatStatus(int heartbeatNumber) {
    return heartbeatNumber == 1 ? "Active" : "Inactive";
  }

  Set<Marker> _markers = {};

  void _onBluetoothStateChange() {
    if (mounted) {
      setState(() {
        // UI will rebuild with new bluetooth state
      });
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('Bikestatus: Initializing with device: ${widget.device}');
    debugPrint('Bikestatus: Using deviceId: $deviceId, bikeId: $bikeId');
  _bleService = Esp32ProvisioningService();
  _bleService.addListener(_onBluetoothStateChange);
    _fetchBikeLocation();
    _fetchBikeHealth();
  }

  @override
  void dispose() {
    // Remove listener and disconnect from device if connected
  _bleService.removeListener(_onBluetoothStateChange);
  _bleService.disconnect();
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
        actions: [
          IconButton(
              onPressed:(){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> WifiProvisioningPage(device: _bleService.connectedDevice,)));
    },
              icon: Icon(Icons.wifi, color: Colors.white,))
        ],
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
              _bleService.isConnected
                ? "Connected to ${_bleService.connectedDevice?.platformName ?? 'ESP32'}"
                              : "Tap to Pair with Bike",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _bleService.isScanning ? null : () async {
                          if (_bleService.isConnected) {
                            // Disconnect from current device
                            try {
                              await _bleService.disconnect();
                              print("Disconnected from device");
                            } catch (e) {
                              print("Error disconnecting: $e");
                            }
                          } else {
                            // Try auto-connect to bike
                            final device = await _bleService.autoConnect();
                            if (device != null) {
                              print("Auto-connected to bike: ${device.platformName}");
                            } else {
                              // Navigate to device list page as fallback
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DeviceListPage()),
                              );

                              // Handle the result from device list page
                              if (result != null && result['connected'] == true) {
                                await _bleService.connect(result['device']);
                              }
                            }
                          }
                        },
                        child: _bleService.isScanning
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(_bleService.isConnected ? "Disconnect" : "Pair"),
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
                        if (_latestBikePosition != null) {
                          controller.moveCamera(
                            CameraUpdate.newLatLngZoom(_latestBikePosition!, 16),
                          );
                        }
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
                GestureDetector(
                  onTap: () async {
                    String? selectedMode = await showModalBottomSheet<String>(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.home),
                            title: Text("Normal"),
                            onTap: () => Navigator.pop(context, "Normal"),
                          ),
                          ListTile(
                            leading: Icon(Icons.warning),
                            title: Text("Theft Attempt"),
                            onTap: () => Navigator.pop(context, "Theft Attempt"),
                          ),
                          ListTile(
                            leading: Icon(Icons.bedtime),
                            title: Text("Deep Sleep"),
                            onTap: () => Navigator.pop(context, "Deep Sleep"),
                          ),
                          ListTile(
                            leading: Icon(Icons.location_searching),
                            title: Text("Tracking"),
                            onTap: () => Navigator.pop(context, "Tracking"),
                          ),
                          ListTile(
                            leading: Icon(Icons.directions_bike),
                            title: Text("Ride"),
                            onTap: () => Navigator.pop(context, "Ride"),
                          ),
                          ListTile(
                            leading: Icon(Icons.lock),
                            title: Text("Lock"),
                            onTap: () => Navigator.pop(context, "Lock"),
                          ),
                        ],
                      ),
                    );

                    if (selectedMode != null) {
                      setState(() {
                        bikeMode = selectedMode;
                        isRideMode = (bikeMode.toLowerCase() == "ride");
                      });

                      // ✅ Call your function to send the command
                      await _sendModeCommand(selectedMode);
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _getModeColor(bikeMode).withOpacity(0.2),
                        child: Icon(
                          _getModeIcon(bikeMode),
                          color: _getModeColor(bikeMode),
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        bikeMode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: <Color>[Colors.blueAccent, Colors.lightBlue],
                            ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                        ),
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


  Future<void> _sendModeCommand(String mode) async {
    final url = Uri.parse("http://${appConfig.baseURL}/device_command/add_command");

    String? token = await TokenStorageFallback.getToken();

    final body = json.encode({
      "command_type": "CHANGE MODE",
      "parameters": {"mode": mode.replaceAll(' ', '_').toUpperCase()},
      "token": token,
      "device_id": deviceId,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        print("Mode command sent successfully: $mode");
      } else {
        print("Failed to send mode command. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending mode command: $e");
    }
  }
  /// Fetch bike location from API
  Future<void> _fetchBikeLocation() async {
    final url = Uri.parse("http://${appConfig.baseURL}/telemetry/latest/$deviceId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final telemetry = data['telemetry'];
        final latitude = _parseCoordinate(telemetry, ['lat', 'latitude', 'Latitude']);
        final longitude = _parseCoordinate(telemetry, ['long', 'lng', 'longitude', 'Longitude']);

        if (latitude != null && longitude != null) {
          final position = LatLng(latitude, longitude);
          print("Longitude: $longitude, Latitude: $latitude");

          setState(() {
            _latestBikePosition = position;
            _markers = {
              Marker(
                markerId: const MarkerId("bike"),
                position: position,
                infoWindow: const InfoWindow(title: "Bike Location"),
              ),
            };
          });

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(position, 16),
            );
          }
        } else {
          debugPrint('Telemetry missing latitude/longitude: $telemetry');
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching bike location: $e");
    }
  }

  double? _parseCoordinate(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Fetch bike health from API
  Future<void> _fetchBikeHealth() async {
    final url = Uri.parse("http://${appConfig.baseURL}/device_health/$bikeId/latest");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final health = data['health'];

        setState(() {
          batteryLevel = (health['battery'] ?? 0.0).toDouble();
          heartbeatStatus = _getHeartbeatStatus(health['heartbeat'] ?? 0);
          bikeMode = _getModeName(health['mode'] ?? 5);
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