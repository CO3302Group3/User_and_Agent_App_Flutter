import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceListPage extends StatefulWidget {
  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<ScanResult> devices = [];
  Map<String, String> realNames = {}; // Store real names after connecting
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
        realNames.clear();
      });

      if (!await FlutterBluePlus.isSupported) {
        print("Bluetooth not supported by this device");
        return;
      }

      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      var bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        print("Bluetooth is not turned on");
        return;
      }

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        continuousUpdates: true,
      );

      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          int existingIndex = devices.indexWhere(
                  (existing) => existing.device.remoteId == result.device.remoteId);
          if (existingIndex != -1) {
            devices[existingIndex] = result;
          } else {
            devices.add(result);
            // Fetch real name asynchronously for every device safely
            Future.microtask(() => tryFetchDeviceName(result.device));
          }
        }

        setState(() {
          devices.sort((a, b) {
            bool aIsBike = _isPotentialBike(a);
            bool bIsBike = _isPotentialBike(b);

            if (aIsBike && !bIsBike) return -1;
            if (!aIsBike && bIsBike) return 1;

            return b.rssi.compareTo(a.rssi);
          });
        });
      });

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
      subscription?.cancel();
      setState(() {
        isScanning = false;
      });
    } catch (e) {
      print("Error stopping scan: $e");
    }
  }

  bool _isPotentialBike(ScanResult result) {
    var adv = result.advertisementData;
    String name = adv.localName.isNotEmpty
        ? adv.localName
        : result.device.platformName.isNotEmpty
        ? result.device.platformName
        : "";

    if (name.toLowerCase().contains('bike') ||
        name.toLowerCase().contains('spinlock') ||
        name.toLowerCase().contains('lock') ||
        name.toLowerCase().contains('cycle') ||
        name.toLowerCase().contains('ebike') ||
        name.toLowerCase().contains('scooter')) return true;

    for (var serviceUuid in adv.serviceUuids) {
      String uuid = serviceUuid.toString().toLowerCase();
      if (uuid.contains('1816') ||
          uuid.contains('1818') ||
          uuid.contains('180f') ||
          uuid.contains('1826')) return true;
    }
    return false;
  }

  String getDeviceDisplayName(ScanResult result) {
    String id = result.device.id.id;

    // Show real name if already fetched
    if (realNames.containsKey(id)) return realNames[id]!;

    var adv = result.advertisementData;
    // Use advertised local name first
    if (adv.localName.isNotEmpty) return adv.localName;
    // Use platform name next
    if (result.device.platformName.isNotEmpty) return result.device.platformName;

    // Otherwise, unknown
    return "Unknown Device";
  }


  Future<void> tryFetchDeviceName(BluetoothDevice device) async {
    String id = device.id.id;
    if (realNames.containsKey(id)) return;

    try {
      await device.connect(timeout: Duration(seconds: 3), autoConnect: false);
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase().startsWith("0000180a")) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().startsWith("00002a00")) {
              var value = await char.read();
              String name = String.fromCharCodes(value);
              setState(() {
                realNames[id] = name;
              });
              break;
            }
          }
        }
      }
      await device.disconnect();
    } catch (e) {
      print("Failed to fetch real name for $id: $e");
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      stopScanning();

      await device.connect(timeout: Duration(seconds: 10));

      // Fetch real name
      await fetchRealDeviceName(device);

      // After fetching, the ListView will update
      setState(() {});

      Navigator.pop(context, {'device': device, 'connected': true});
    } catch (e) {
      print("Connection failed: $e");
    }
  }
  Future<void> fetchRealDeviceName(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        // Device Information Service
        if (service.uuid.toString().toLowerCase().startsWith("0000180a")) {
          for (var char in service.characteristics) {
            // Device Name characteristic
            if (char.uuid.toString().toLowerCase().startsWith("00002a00")) {
              var value = await char.read();
              String name = String.fromCharCodes(value);
              realNames[device.id.id] = name;
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Error reading real device name: $e");
    }
  }



  Widget buildDeviceCard(ScanResult result) {
    var adv = result.advertisementData;
    var rssi = result.rssi;
    bool isBike = _isPotentialBike(result);

    String deviceName = getDeviceDisplayName(result);

    IconData signalIcon;
    Color signalColor;
    if (rssi > -50) {
      signalIcon = Icons.signal_cellular_4_bar;
      signalColor = Colors.green;
    } else if (rssi > -70) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.orange;
    } else {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isBike ? Colors.green.shade50 : null,
      elevation: isBike ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBike ? Colors.green.shade100 : Colors.indigo.shade100,
          child: Icon(isBike ? Icons.pedal_bike : Icons.bluetooth,
              color: isBike ? Colors.green.shade800 : Colors.indigo.shade800),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(deviceName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBike ? Colors.green.shade800 : null))),
            if (isBike)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green, borderRadius: BorderRadius.circular(10)),
                child: Text("BIKE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${result.device.id.id.substring(0, 8)}...",
                style: TextStyle(fontSize: 12)),
            Row(
              children: [
                Icon(adv.connectable ? Icons.link : Icons.link_off,
                    size: 14, color: adv.connectable ? Colors.green : Colors.red),
                SizedBox(width: 4),
                Text(adv.connectable ? "Connectable" : "Not Connectable",
                    style: TextStyle(
                        fontSize: 11,
                        color: adv.connectable ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(signalIcon, color: signalColor, size: 20),
            Text("$rssi dBm", style: TextStyle(fontSize: 12))
          ],
        ),
        onTap: adv.connectable ? () => connectToDevice(result.device) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Device",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade800,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.refresh),
              onPressed: isScanning ? stopScanning : startScanning),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
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
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Icon(Icons.bluetooth_searching, color: Colors.indigo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isScanning
                              ? "Scanning for devices... (${devices.length} found)"
                              : "Found ${devices.length} device(s). Tap refresh to scan again\nTap to connect to fetch real name",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: devices.isEmpty && !isScanning
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_disabled,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No devices found",
                        style:
                        TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    SizedBox(height: 8),
                    Text(
                        "Make sure your bike is in pairing mode\nand tap refresh to scan again",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600)),
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