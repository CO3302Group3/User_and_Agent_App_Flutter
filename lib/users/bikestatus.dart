import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_list_page.dart';

class Bikestatus extends StatefulWidget {
  @override
  State<Bikestatus> createState() => _BikestatusState();
}

class _BikestatusState extends State<Bikestatus> {
  bool isBluetoothConnected = false;
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  GoogleMapController? _mapController;
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(6.8416, 79.9028),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    // Disconnect from device if connected
    if (connectedDevice != null) {
      connectedDevice!.disconnect();
    }
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
                            ? "Connected to ${connectedDevice?.platformName ?? 'Device'}"
                            : "Tap to Pair with Bike",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: isScanning ? null : () async {
                        if (isBluetoothConnected && connectedDevice != null) {
                          // Disconnect from current device
                          try {
                            await connectedDevice!.disconnect();
                            setState(() {
                              isBluetoothConnected = false;
                              connectedDevice = null;
                            });
                            print("Disconnected from device");
                          } catch (e) {
                            print("Error disconnecting: $e");
                          }
                        } else {
                          // Navigate to device list page
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeviceListPage()),
                          );
                          
                          // Handle the result from device list page
                          if (result != null && result['connected'] == true) {
                            setState(() {
                              isBluetoothConnected = true;
                              connectedDevice = result['device'];
                            });
                            
                            // Discover services for the connected device
                            try {
                              List<BluetoothService> services = await result['device'].discoverServices();
                              print("Discovered ${services.length} services for ${result['device'].platformName}");
                              
                              for (BluetoothService service in services) {
                                print("Service UUID: ${service.uuid}");
                                for (BluetoothCharacteristic characteristic in service.characteristics) {
                                  print("  Characteristic UUID: ${characteristic.uuid}");
                                }
                              }
                            } catch (e) {
                              print("Error discovering services: $e");
                            }
                          }
                        }
                      },
                      child: isScanning 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isBluetoothConnected ? "Disconnect" : "Pair"),
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
                    onMapCreated: (controller) => _mapController = controller,),
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

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("Attempting to connect to ${device.platformName}");
      
      // Connect to the device
      await device.connect(timeout: Duration(seconds: 15));
      print("Connected to ${device.platformName}");
      
      // Update UI state
      setState(() {
        isBluetoothConnected = true;
        connectedDevice = device;
      });
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print("Discovered ${services.length} services");
      
      for (BluetoothService service in services) {
        print("Service UUID: ${service.uuid}");
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("  Characteristic UUID: ${characteristic.uuid}");
        }
      }
      
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        isBluetoothConnected = false;
        connectedDevice = null;
      });
    }
  }

  Future<void> connectBLE() async {
    try {
      // Check if Bluetooth is supported and enabled
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }

      // Request Bluetooth permissions
      var bluetoothStatus = await Permission.bluetooth.status;
      var locationStatus = await Permission.location.status;
      var bluetoothScanStatus = await Permission.bluetoothScan.status;
      var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      
      print("Current permissions - Bluetooth: $bluetoothStatus, Location: $locationStatus, Scan: $bluetoothScanStatus, Connect: $bluetoothConnectStatus");
      
      if (bluetoothStatus.isDenied || locationStatus.isDenied || 
          bluetoothScanStatus.isDenied || bluetoothConnectStatus.isDenied) {
        // Request permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
          Permission.locationWhenInUse, // Add this for better location access
        ].request();
        
        print("Permission statuses after request: $statuses");
        
        // Check if essential permissions were granted
        if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
            statuses[Permission.location] != PermissionStatus.granted) {
          print("Required permissions not granted for BLE scanning");
          return;
        }
      }

      // Check if Bluetooth is turned on
      var bluetoothState = await FlutterBluePlus.adapterState.first;
      print("Bluetooth adapter state: $bluetoothState");
      if (bluetoothState != BluetoothAdapterState.on) {
        print("Bluetooth is not turned on");
        return;
      }

      print("Starting BLE scan...");
      
      // Declare subscription variable
      late var subscription;
      
      // Start scanning with more aggressive settings
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 20), // Longer timeout
        withServices: [], // Scan for all devices
        withRemoteIds: [], // Empty list to scan for all devices
        withNames: [], // Empty list to scan for all device names
        continuousUpdates: true, // Get continuous updates
        continuousDivisor: 1, // Update frequency
      );
      
      // Listen for scan results with immediate processing
      subscription = FlutterBluePlus.scanResults.listen((results) async {
        if (results.isNotEmpty) {
          print("Scan results received: ${results.length} devices found");
          
          for (ScanResult result in results) {
            var device = result.device;
            var rssi = result.rssi;
            var name = device.platformName.isNotEmpty ? device.platformName : "Unknown Device";
            var advertisementData = result.advertisementData;
            
            print('Found device: $name (${device.remoteId}) RSSI: $rssi');
            print('  Local Name: ${advertisementData.localName}');
            print('  Manufacturer Data: ${advertisementData.manufacturerData}');
            print('  Service UUIDs: ${advertisementData.serviceUuids}');
            
            // More flexible device filtering - you can adjust this based on your bike's characteristics
            bool isPotentialBike = false;
            
            // Check by name (case-insensitive)
            if (name.toLowerCase().contains('bike') || 
                name.toLowerCase().contains('spinlock') ||
                name.toLowerCase().contains('lock') ||
                advertisementData.localName.toLowerCase().contains('bike') ||
                advertisementData.localName.toLowerCase().contains('spinlock')) {
              isPotentialBike = true;
            }
            
            // You can also check by service UUIDs if you know them
            // if (advertisementData.serviceUuids.contains('your-bike-service-uuid')) {
            //   isPotentialBike = true;
            // }
            
            // For testing purposes, you might want to try connecting to any device with a strong signal
            // Uncomment the line below to try connecting to any nearby device (be careful!)
            // if (rssi > -60) isPotentialBike = true;
            
            // TEMPORARY: For debugging, let's try to connect to the first device we find
            // Remove this when you know your bike's name/characteristics
            if (results.isNotEmpty && isPotentialBike == false && rssi > -70) {
              print("DEBUG: Attempting to connect to first available device for testing");
              isPotentialBike = true;
            }
            
            if (isPotentialBike) {
              print("Found potential bike device: $name");
              // Stop scanning before connecting
              await FlutterBluePlus.stopScan();
              subscription.cancel();
              // Attempt to connect to the bike device
              await connectToDevice(device);
              return; // Exit the function after attempting connection
            }
          }
        } else {
          print("Scan results received: 0 devices found - continuing scan...");
        }
      });

      // Wait for scan to complete
      await Future.delayed(Duration(seconds: 20));
      
      // Stop scanning if still running
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      subscription.cancel();
      
      print("BLE scan completed");
      
    } catch (e) {
      print("Error in connectBLE: $e");
      // Make sure to stop scanning if there's an error
      try {
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }
      } catch (stopError) {
      }
    }
  }
}
