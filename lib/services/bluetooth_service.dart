import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class BikeBluetoothService extends ChangeNotifier {
  bool _isBluetoothConnected = false;
  bool _isScanning = false;
  fbp.BluetoothDevice? _connectedDevice;
  StreamSubscription? _scanSubscription;

  // Getters
  bool get isBluetoothConnected => _isBluetoothConnected;
  bool get isScanning => _isScanning;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  // Singleton pattern
  static final BikeBluetoothService _instance = BikeBluetoothService._internal();
  factory BikeBluetoothService() => _instance;
  BikeBluetoothService._internal();

  /// Connect to a specific Bluetooth device
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      debugPrint("Attempting to connect to ${device.platformName}");

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));
      debugPrint("Connected to ${device.platformName}");

      // Update state
      _isBluetoothConnected = true;
      _connectedDevice = device;
      notifyListeners();

      // Discover services
      List<fbp.BluetoothService> services = await device.discoverServices();
      debugPrint("Discovered ${services.length} services");

      for (fbp.BluetoothService service in services) {
        debugPrint("Service UUID: ${service.uuid}");
        for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
          debugPrint("  Characteristic UUID: ${characteristic.uuid}");
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error connecting to device: $e");
      _isBluetoothConnected = false;
      _connectedDevice = null;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        debugPrint("Disconnected from ${_connectedDevice!.platformName}");
      } catch (e) {
        debugPrint("Error disconnecting: $e");
      }
    }

    _isBluetoothConnected = false;
    _connectedDevice = null;
    notifyListeners();
  }

  /// Check and request Bluetooth permissions
  Future<bool> _checkPermissions() async {
    try {
      // Request Bluetooth permissions
      var bluetoothStatus = await Permission.bluetooth.status;
      var locationStatus = await Permission.location.status;
      var bluetoothScanStatus = await Permission.bluetoothScan.status;
      var bluetoothConnectStatus = await Permission.bluetoothConnect.status;

      debugPrint("Current permissions - Bluetooth: $bluetoothStatus, Location: $locationStatus, Scan: $bluetoothScanStatus, Connect: $bluetoothConnectStatus");

      if (bluetoothStatus.isDenied || locationStatus.isDenied ||
          bluetoothScanStatus.isDenied || bluetoothConnectStatus.isDenied) {
        // Request permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
          Permission.locationWhenInUse,
        ].request();

        debugPrint("Permission statuses after request: $statuses");

        // Check if essential permissions were granted
        if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
            statuses[Permission.location] != PermissionStatus.granted) {
          debugPrint("Required permissions not granted for BLE scanning");
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error checking permissions: $e");
      return false;
    }
  }

  /// Check if Bluetooth is supported and enabled
  Future<bool> _checkBluetoothState() async {
    try {
      // Check if Bluetooth is supported
      if (await fbp.FlutterBluePlus.isSupported == false) {
        debugPrint("Bluetooth not supported by this device");
        return false;
      }

      // Check if Bluetooth is turned on
      var bluetoothState = await fbp.FlutterBluePlus.adapterState.first;
      debugPrint("Bluetooth adapter state: $bluetoothState");
      if (bluetoothState != fbp.BluetoothAdapterState.on) {
        debugPrint("Bluetooth is not turned on");
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("Error checking Bluetooth state: $e");
      return false;
    }
  }

  /// Scan for available Bluetooth devices
  Future<List<fbp.ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 20),
    List<String> deviceNameFilters = const [],
    int minRssi = -100,
  }) async {
    try {
      // Check permissions and Bluetooth state
      if (!await _checkPermissions() || !await _checkBluetoothState()) {
        return [];
      }

      _isScanning = true;
      notifyListeners();

      debugPrint("Starting BLE scan...");

      List<fbp.ScanResult> foundDevices = [];

      // Start scanning
      await fbp.FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [],
        withRemoteIds: [],
        withNames: [],
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      // Listen for scan results
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty) {
          debugPrint("Scan results received: ${results.length} devices found");
          foundDevices = results.where((result) => result.rssi > minRssi).toList();
          
          for (fbp.ScanResult result in foundDevices) {
            var device = result.device;
            var rssi = result.rssi;
            var name = device.platformName.isNotEmpty ? device.platformName : "Unknown Device";
            var advertisementData = result.advertisementData;

            debugPrint('Found device: $name (${device.remoteId}) RSSI: $rssi');
            debugPrint('  Local Name: ${advertisementData.localName}');
            debugPrint('  Service UUIDs: ${advertisementData.serviceUuids}');
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);

      // Stop scanning
      await stopScan();

      return foundDevices;

    } catch (e) {
      debugPrint("Error in scanForDevices: $e");
      await stopScan();
      return [];
    }
  }

  /// Stop the current scan
  Future<void> stopScan() async {
    try {
      if (fbp.FlutterBluePlus.isScanningNow) {
        await fbp.FlutterBluePlus.stopScan();
      }
      _scanSubscription?.cancel();
      _scanSubscription = null;
      
      _isScanning = false;
      notifyListeners();
      
      debugPrint("BLE scan stopped");
    } catch (e) {
      debugPrint("Error stopping scan: $e");
    }
  }

  /// Auto-connect to bike devices based on name patterns
  Future<fbp.BluetoothDevice?> autoConnectToBike({
    Duration scanTimeout = const Duration(seconds: 20),
    List<String> bikeNamePatterns = const ['bike', 'spinlock', 'lock'],
    int minRssi = -70,
  }) async {
    try {
      // Check permissions and Bluetooth state
      if (!await _checkPermissions() || !await _checkBluetoothState()) {
        return null;
      }

      _isScanning = true;
      notifyListeners();

      debugPrint("Starting auto-connect scan for bike devices...");

      // Start scanning
      await fbp.FlutterBluePlus.startScan(
        timeout: scanTimeout,
        withServices: [],
        withRemoteIds: [],
        withNames: [],
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      // Create a completer to return the first found bike device
      Completer<fbp.BluetoothDevice?> completer = Completer();

      // Listen for scan results
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) async {
        if (results.isNotEmpty && !completer.isCompleted) {
          for (fbp.ScanResult result in results) {
            var device = result.device;
            var rssi = result.rssi;
            var name = device.platformName.isNotEmpty ? device.platformName : "Unknown Device";
            var advertisementData = result.advertisementData;

            // Check if this device matches bike patterns
            bool isPotentialBike = false;

            // Check by device name patterns
            for (String pattern in bikeNamePatterns) {
              if (name.toLowerCase().contains(pattern.toLowerCase()) ||
                  advertisementData.localName.toLowerCase().contains(pattern.toLowerCase())) {
                isPotentialBike = true;
                break;
              }
            }

            // Check RSSI threshold
            if (isPotentialBike && rssi > minRssi) {
              debugPrint("Found potential bike device: $name with RSSI: $rssi");
              
              // Stop scanning before connecting
              await stopScan();
              
              // Attempt to connect
              bool connected = await connectToDevice(device);
              if (connected) {
                completer.complete(device);
                return;
              }
            }
          }
        }
      });

      // Wait for scan to complete or device to be found
      await Future.delayed(scanTimeout);

      if (!completer.isCompleted) {
        completer.complete(null);
      }

      await stopScan();
      return await completer.future;

    } catch (e) {
      debugPrint("Error in autoConnectToBike: $e");
      await stopScan();
      return null;
    }
  }

  /// Send data to connected device (if supported)
  Future<bool> sendDataToDevice(String serviceUuid, String characteristicUuid, List<int> data) async {
    if (_connectedDevice == null || !_isBluetoothConnected) {
      debugPrint("No device connected");
      return false;
    }

    try {
      List<fbp.BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUuid) {
              await characteristic.write(data);
              debugPrint("Data sent successfully to characteristic: $characteristicUuid");
              return true;
            }
          }
        }
      }
      
      debugPrint("Service or characteristic not found");
      return false;
    } catch (e) {
      debugPrint("Error sending data to device: $e");
      return false;
    }
  }

  /// Listen for data from connected device (if supported)
  Stream<List<int>>? listenToCharacteristic(String serviceUuid, String characteristicUuid) {
    if (_connectedDevice == null || !_isBluetoothConnected) {
      debugPrint("No device connected");
      return null;
    }

    // This would need to be implemented based on your specific service/characteristic setup
    // Return a stream of data from the characteristic
    return null; // Placeholder
  }

  /// Dispose resources
  @override
  void dispose() {
    _scanSubscription?.cancel();
    disconnectDevice();
    super.dispose();
  }
}