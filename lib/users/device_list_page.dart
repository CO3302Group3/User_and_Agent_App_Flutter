import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import 'package:computer_engineering_project/services/esp32_provisioning_service.dart';

class DeviceListPage extends StatefulWidget {
  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final Esp32ProvisioningService _service = Esp32ProvisioningService();
  List<fbp.ScanResult> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceStateChange);
    startScanning();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceStateChange);
    _service.stopScan();
    super.dispose();
  }

  void _onServiceStateChange() {
    if (!mounted) return;
    setState(() {
      isScanning = _service.isScanning;
    });
  }

  Future<void> startScanning() async {
    setState(() {
      devices.clear();
    });

    final results = await _service.scanForProvisioningDevices(timeout: const Duration(seconds: 18));

    if (!mounted) return;
    setState(() {
      devices = results;
    });
  }

  void stopScanning() {
    _service.stopScan();
  }

  bool _isEsp32Device(fbp.ScanResult result) {
    final adv = result.advertisementData;
    final matchingUuid = Esp32ProvisioningService.defaultProvisioningServiceUuid;

    if (adv.serviceUuids.any((uuid) => uuid.toString().toLowerCase() == matchingUuid)) {
      return true;
    }

    final name = (adv.localName.isNotEmpty ? adv.localName : result.device.platformName).toLowerCase();
    if (name.contains('esp') || name.startsWith('prov_') || name.contains('esp32')) {
      return true;
    }

    if (adv.manufacturerData.keys.any((id) => id == 0x02e5)) {
      return true;
    }

    return false;
  }

  String getDeviceDisplayName(fbp.ScanResult result) {
    final adv = result.advertisementData;
    if (adv.localName.isNotEmpty) return adv.localName;
    if (result.device.platformName.isNotEmpty) return result.device.platformName;
    return 'ESP32 Device ${result.device.remoteId.str.substring(0, 4)}';
  }

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      stopScanning();

      final connected = await _service.connect(device);
      if (connected) {
        Navigator.pop(context, {'device': device, 'connected': true});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to ESP32 provisioning service')),
        );
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  Widget buildDeviceCard(fbp.ScanResult result) {
    var adv = result.advertisementData;
    var rssi = result.rssi;
    bool isEsp32 = _isEsp32Device(result);

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
      color: isEsp32 ? Colors.green.shade50 : null,
      elevation: isEsp32 ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEsp32 ? Colors.green.shade100 : Colors.indigo.shade100,
          child: Icon(isEsp32 ? Icons.memory : Icons.bluetooth,
              color: isEsp32 ? Colors.green.shade800 : Colors.indigo.shade800),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(deviceName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEsp32 ? Colors.green.shade800 : null))),
            if (isEsp32)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green, borderRadius: BorderRadius.circular(10)),
                child: Text("ESP32",
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
                              ? "Scanning for ESP32 provisioning devices... (${devices.length} found)"
                              : "Found ${devices.length} ESP32 device(s). Tap refresh to scan again",
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
                        "Make sure your ESP32 is advertising provisioning service\nand tap refresh to scan again",
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