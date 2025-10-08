// Example usage of the BikeBluetoothService
// This file demonstrates how to use the Bluetooth service in other parts of the app

import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class BluetoothExampleUsage extends StatefulWidget {
  const BluetoothExampleUsage({Key? key}) : super(key: key);

  @override
  State<BluetoothExampleUsage> createState() => _BluetoothExampleUsageState();
}

class _BluetoothExampleUsageState extends State<BluetoothExampleUsage> {
  late BikeBluetoothService _bluetoothService;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BikeBluetoothService();
    _bluetoothService.addListener(_onBluetoothStateChange);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_onBluetoothStateChange);
    super.dispose();
  }

  void _onBluetoothStateChange() {
    if (mounted) {
      setState(() {
        // UI will rebuild with updated bluetooth state
      });
    }
  }

  Future<void> _connectToBike() async {
    // Method 1: Auto-connect to bike (recommended)
    final device = await _bluetoothService.autoConnectToBike();
    if (device != null) {
      print("Successfully connected to bike: ${device.platformName}");
      // Handle successful connection
    } else {
      print("Failed to auto-connect to bike");
      // Handle failed connection or show device list
    }
  }

  Future<void> _scanForDevices() async {
    // Method 2: Manual scan for devices
    final devices = await _bluetoothService.scanForDevices(
      timeout: Duration(seconds: 10),
      minRssi: -80, // Filter by signal strength
    );
    
    print("Found ${devices.length} devices");
    for (final result in devices) {
      print("Device: ${result.device.platformName} - RSSI: ${result.rssi}");
    }
  }

  Future<void> _disconnectFromDevice() async {
    await _bluetoothService.disconnectDevice();
    print("Disconnected from device");
  }

  Future<void> _sendDataToDevice() async {
    // Example of sending data to a connected device
    // You need to know the service and characteristic UUIDs
    const serviceUuid = "12345678-1234-1234-1234-123456789abc";
    const characteristicUuid = "87654321-4321-4321-4321-cba987654321";
    
    final data = [0x01, 0x02, 0x03]; // Example data
    
    final success = await _bluetoothService.sendDataToDevice(
      serviceUuid,
      characteristicUuid,
      data,
    );
    
    if (success) {
      print("Data sent successfully");
    } else {
      print("Failed to send data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Service Example"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection status
            Card(
              child: ListTile(
                leading: Icon(
                  _bluetoothService.isBluetoothConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _bluetoothService.isBluetoothConnected
                      ? Colors.green
                      : Colors.grey,
                ),
                title: Text(
                  _bluetoothService.isBluetoothConnected
                      ? "Connected to ${_bluetoothService.connectedDevice?.platformName ?? 'Device'}"
                      : "Not Connected",
                ),
                subtitle: Text(
                  _bluetoothService.isScanning
                      ? "Scanning for devices..."
                      : "Ready",
                ),
              ),
            ),

            SizedBox(height: 20),

            // Action buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: _bluetoothService.isScanning
                      ? null
                      : _connectToBike,
                  child: Text("Auto-Connect to Bike"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _bluetoothService.isScanning
                      ? null
                      : _scanForDevices,
                  child: Text("Scan for Devices"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _bluetoothService.isBluetoothConnected
                      ? _disconnectFromDevice
                      : null,
                  child: Text("Disconnect"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _bluetoothService.isBluetoothConnected
                      ? _sendDataToDevice
                      : null,
                  child: Text("Send Data to Device"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}