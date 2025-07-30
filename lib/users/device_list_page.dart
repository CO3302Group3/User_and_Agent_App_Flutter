import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceListPage extends StatefulWidget {
  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<ScanResult> devices = [];
  bool isScanning = false;
  var subscription;

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }

  Future<void> startScanning() async {
    try {
      setState(() {
        isScanning = true;
        devices.clear();
      });

      // Check permissions and Bluetooth state
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }

      // Request permissions
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      // Check if Bluetooth is turned on
      var bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        print("Bluetooth is not turned on");
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        withServices: [],
        withRemoteIds: [],
        withNames: [],
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      // Listen for scan results
      subscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          // Update device list efficiently
          for (ScanResult result in results) {
            // Check if device already exists
            int existingIndex = devices.indexWhere((existing) => 
              existing.device.remoteId == result.device.remoteId);
            
            if (existingIndex != -1) {
              // Update existing device with new scan result
              devices[existingIndex] = result;
            } else {
              // Add new device
              devices.add(result);
            }
          }
          
          // Sort devices: potential bikes first, then by RSSI
          devices.sort((a, b) {
            // Check if devices are potential bikes
            bool aIsBike = _isPotentialBike(a);
            bool bIsBike = _isPotentialBike(b);
            
            if (aIsBike && !bIsBike) return -1;
            if (!aIsBike && bIsBike) return 1;
            
            // If both are bikes or both are not bikes, sort by RSSI
            return b.rssi.compareTo(a.rssi);
          });
        });
      });

      // Auto-stop scanning after timeout
      await Future.delayed(Duration(seconds: 30));
      stopScanning();

    } catch (e) {
      print("Error in scanning: $e");
      setState(() {
        isScanning = false;
      });
    }
  }

  void stopScanning() {
    try {
      if (FlutterBluePlus.isScanningNow) {
        FlutterBluePlus.stopScan();
      }
      if (subscription != null) {
        subscription.cancel();
      }
      setState(() {
        isScanning = false;
      });
    } catch (e) {
      print("Error stopping scan: $e");
    }
  }

  bool _isPotentialBike(ScanResult result) {
    var device = result.device;
    var advertisementData = result.advertisementData;
    
    // Get the best available name
    String deviceName = device.platformName.isNotEmpty ? device.platformName : 
                       (advertisementData.localName.isNotEmpty ? advertisementData.localName : "Unknown Device");
    
    String searchText = "${deviceName.toLowerCase()} ${advertisementData.localName.toLowerCase()}";
    
    // Check by name
    if (searchText.contains('bike') || 
        searchText.contains('spinlock') ||
        searchText.contains('lock') ||
        searchText.contains('cycle') ||
        searchText.contains('ebike') ||
        searchText.contains('scooter')) {
      return true;
    }
    
    // Check service UUIDs for common bike/fitness services
    for (var serviceUuid in advertisementData.serviceUuids) {
      String uuid = serviceUuid.toString().toLowerCase();
      if (uuid.contains('1816') || // Cycling Speed and Cadence
          uuid.contains('1818') || // Cycling Power
          uuid.contains('180f') || // Battery Service
          uuid.contains('1826')) { // Fitness Machine Service
        return true;
      }
    }
    
    return false;
  }

  Future<void> showDeviceDetails(ScanResult result) async {
    var device = result.device;
    var advertisementData = result.advertisementData;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Device Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("Platform Name", device.platformName.isEmpty ? "Not advertised" : device.platformName),
              _buildDetailRow("Local Name", advertisementData.localName.isEmpty ? "Not advertised" : advertisementData.localName),
              _buildDetailRow("Device ID", device.remoteId.toString()),
              _buildDetailRow("RSSI", "${result.rssi} dBm"),
              _buildDetailRow("Connectable", advertisementData.connectable ? "Yes" : "No"),
              _buildDetailRow("TX Power", advertisementData.txPowerLevel?.toString() ?? "Not available"),
              
              SizedBox(height: 12),
              Text("Name Visibility:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  "• Platform Name: ${device.platformName.isEmpty ? '❌ Hidden/Not set' : '✅ Visible'}\n"
                  "• Local Name: ${advertisementData.localName.isEmpty ? '❌ Hidden/Not set' : '✅ Visible'}\n"
                  "• Some devices hide their names for privacy",
                  style: TextStyle(fontSize: 12),
                ),
              ),
              
              if (advertisementData.serviceUuids.isNotEmpty) ...[
                SizedBox(height: 8),
                Text("Service UUIDs:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...advertisementData.serviceUuids.map((uuid) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 2),
                    child: Text(uuid.toString(), style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  )
                ),
              ],
              
              if (advertisementData.manufacturerData.isNotEmpty) ...[
                SizedBox(height: 8),
                Text("Manufacturer Data:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...advertisementData.manufacturerData.entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 2),
                    child: Text("0x${entry.key.toRadixString(16).toUpperCase()}: ${entry.value}", 
                               style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  )
                ),
              ],
              
              if (advertisementData.serviceData.isNotEmpty) ...[
                SizedBox(height: 8),
                Text("Service Data:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...advertisementData.serviceData.entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 2),
                    child: Text("${entry.key}: ${entry.value}", 
                               style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  )
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (advertisementData.connectable)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                connectToDevice(device);
              },
              child: Text("Connect"),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label + ":", style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text("Connecting to ${device.platformName}...")),
            ],
          ),
        ),
      );

      // Stop scanning before connecting
      stopScanning();

      // Connect to the device
      await device.connect(timeout: Duration(seconds: 15));
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Return to previous page with device info
      Navigator.pop(context, {
        'device': device,
        'connected': true,
      });

    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Connection Failed"),
          content: Text("Failed to connect to ${device.platformName}: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Widget buildDeviceCard(ScanResult result) {
    var device = result.device;
    var rssi = result.rssi;
    var advertisementData = result.advertisementData;
    
    // Try to get the best available name
    String deviceName = "Unknown Device";
    if (device.platformName.isNotEmpty) {
      deviceName = device.platformName;
    } else if (advertisementData.localName.isNotEmpty) {
      deviceName = advertisementData.localName;
    } else if (advertisementData.manufacturerData.isNotEmpty) {
      // Try to identify by manufacturer data
      var manufacturerData = advertisementData.manufacturerData;
      if (manufacturerData.containsKey(0x004C)) {
        deviceName = "Apple Device";
      } else if (manufacturerData.containsKey(0x0006)) {
        deviceName = "Microsoft Device";
      } else if (manufacturerData.containsKey(0x00E0)) {
        deviceName = "Google Device";
      } else {
        deviceName = "Device (Manufacturer: ${manufacturerData.keys.first.toRadixString(16).toUpperCase()})";
      }
    }

    // Check if this might be a bike device
    bool isPotentialBike = _isPotentialBike(result);

    // Get signal strength icon and color
    IconData signalIcon;
    Color signalColor;
    if (rssi > -50) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (rssi > -70) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.orange;
    } else if (rssi > -85) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isPotentialBike ? Colors.green.shade50 : null,
      elevation: isPotentialBike ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPotentialBike ? Colors.green.shade100 : Colors.indigo.shade100,
          child: Icon(
            isPotentialBike ? Icons.pedal_bike : Icons.bluetooth,
            color: isPotentialBike ? Colors.green.shade800 : Colors.indigo.shade800,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                deviceName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPotentialBike ? Colors.green.shade800 : null,
                ),
              ),
            ),
            if (isPotentialBike)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "BIKE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${device.remoteId.toString().substring(0, 8)}...", 
                 style: TextStyle(fontSize: 12)),
            // Show platform name if different from displayed name
            if (device.platformName.isNotEmpty && device.platformName != deviceName)
              Text("Platform: ${device.platformName}",
                   style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            // Show local name if different from displayed name
            if (advertisementData.localName.isNotEmpty && 
                advertisementData.localName != deviceName)
              Text("Local Name: ${advertisementData.localName}",
                   style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
            if (advertisementData.serviceUuids.isNotEmpty)
              Text("Services: ${advertisementData.serviceUuids.length}",
                   style: TextStyle(fontSize: 12)),
            if (advertisementData.manufacturerData.isNotEmpty)
              Text("Manufacturer: 0x${advertisementData.manufacturerData.keys.first.toRadixString(16).toUpperCase()}",
                   style: TextStyle(fontSize: 12)),
            // Show what names are actually being advertised
            Text("Names: Platform='${device.platformName.isEmpty ? 'None' : device.platformName}', Local='${advertisementData.localName.isEmpty ? 'None' : advertisementData.localName}'",
                 style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            Row(
              children: [
                Icon(
                  advertisementData.connectable ? Icons.link : Icons.link_off,
                  size: 14,
                  color: advertisementData.connectable ? Colors.green : Colors.red,
                ),
                SizedBox(width: 4),
                Text(
                  advertisementData.connectable ? "Connectable" : "Not Connectable",
                  style: TextStyle(
                    fontSize: 11,
                    color: advertisementData.connectable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (isPotentialBike)
              Text(
                "🚴 Potential bike device",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(signalIcon, color: signalColor, size: 20),
            Text("$rssi dBm", style: TextStyle(fontSize: 12)),
          ],
        ),
        onTap: advertisementData.connectable 
          ? () => connectToDevice(device)
          : null,
        onLongPress: () => showDeviceDetails(result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Device",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.stop : Icons.refresh),
            onPressed: isScanning ? stopScanning : startScanning,
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
        child: Column(
          children: [
            // Scanning status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (isScanning)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.bluetooth_searching, color: Colors.indigo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isScanning 
                            ? "Scanning for devices... (${devices.length} found)"
                            : "Found ${devices.length} device(s). Tap refresh to scan again.\nTap to connect • Long press for details\n📱 Device names depend on what each device chooses to advertise",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Device list
            Expanded(
              child: devices.isEmpty && !isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No devices found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Make sure your bike is in pairing mode\nand tap refresh to scan again",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return buildDeviceCard(devices[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
