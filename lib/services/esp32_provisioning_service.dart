import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class Esp32WifiNetwork {
  const Esp32WifiNetwork({
    required this.ssid,
    required this.rssi,
    required this.channel,
    required this.authMode,
  });

  final String ssid;
  final int rssi;
  final int channel;
  final String authMode;

  factory Esp32WifiNetwork.fromJson(Map<String, dynamic> json) {
    final rawSsid = json['ssid'] ?? json['name'] ?? json['ap'] ?? '';
    final rawRssi = json['rssi'] ?? json['signal'] ?? json['strength'] ?? 0;
    final rawChannel = json['channel'] ?? json['ch'] ?? json['frequency'] ?? 0;
    final rawAuth = json['auth'] ?? json['auth_mode'] ?? json['security'] ?? json['type'] ?? 'unknown';

    final parsedRssi = rawRssi is num ? rawRssi.round() : int.tryParse(rawRssi.toString()) ?? 0;
    final parsedChannel = rawChannel is num ? rawChannel.round() : int.tryParse(rawChannel.toString()) ?? 0;

    return Esp32WifiNetwork(
      ssid: rawSsid.toString(),
      rssi: parsedRssi,
      channel: parsedChannel,
      authMode: rawAuth.toString(),
    );
  }

  String get securityLabel {
    final lower = authMode.toLowerCase();
    if (lower.contains('wpa3')) return 'WPA3';
    if (lower.contains('wpa2')) return 'WPA2';
    if (lower.contains('wpa')) return 'WPA';
    if (lower.contains('wep')) return 'WEP';
    if (lower.contains('open') || lower == '0' || lower == 'none') return 'Open';
    return authMode.toUpperCase();
  }

  bool get requiresPassword {
    final lower = authMode.toLowerCase();
    return !(lower.contains('open') || lower == '0' || lower == 'none');
  }
}

/// Service responsible for interacting with ESP32 provisioning firmware over BLE.
///
/// The implementation follows the ESP-IDF Wi-Fi provisioning flow described at
/// https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/provisioning/wifi_provisioning.html
/// and focuses on discovering devices exposing the default provisioning primary
/// service UUID `0000ffff-0000-1000-8000-00805f9b34fb`.
class Esp32ProvisioningService extends ChangeNotifier {
  Esp32ProvisioningService._internal();

  static final Esp32ProvisioningService _instance = Esp32ProvisioningService._internal();

  factory Esp32ProvisioningService() => _instance;

  // BLE provisioning constants
  static const String defaultProvisioningServiceUuid = '0000ffff-0000-1000-8000-00805f9b34fb';
  static const String characteristicUserDescriptionUuid = '00002901-0000-1000-8000-00805f9b34fb';

  bool _isConnected = false;
  bool _isScanning = false;
  fbp.BluetoothDevice? _connectedDevice;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;

  /// Map of provisioning endpoint name -> characteristic
  final Map<String, fbp.BluetoothCharacteristic> _endpointCharacteristics = {};
  final List<Esp32WifiNetwork> _lastScannedNetworks = [];

  /// Optional custom provisioning service UUID override (lowercase string)
  String? _customServiceUuid;

  bool get isConnected => _isConnected;

  bool get isScanning => _isScanning;

  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  List<String> get availableEndpoints => _endpointCharacteristics.keys.toList(growable: false);

  bool get hasProvisioningEndpoints => _endpointCharacteristics.isNotEmpty;

  List<Esp32WifiNetwork> get lastScannedNetworks => List<Esp32WifiNetwork>.unmodifiable(_lastScannedNetworks);

  /// Allows specifying a non-default provisioning service UUID.
  void setCustomServiceUuid(String? uuid) {
    _customServiceUuid = uuid?.toLowerCase();
  }

  /// Start scanning for ESP32 provisioning devices.
  Future<List<fbp.ScanResult>> scanForProvisioningDevices({
    Duration timeout = const Duration(seconds: 12),
    int minimumRssi = -90,
  }) async {
    if (!await _prepareBluetooth()) {
      return [];
    }

    final List<fbp.ScanResult> results = [];

    _isScanning = true;
    notifyListeners();

    await fbp.FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [],
      withRemoteIds: [],
      withNames: [],
      continuousUpdates: true,
      continuousDivisor: 1,
    );

    _scanSubscription?.cancel();
    _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((scanResults) {
      for (final result in scanResults) {
        if (!_isEsp32ProvisioningAdvert(result)) continue;
        if (result.rssi < minimumRssi) continue;

        final existingIndex = results.indexWhere(
          (existing) => existing.device.remoteId == result.device.remoteId,
        );

        if (existingIndex == -1) {
          results.add(result);
        } else {
          results[existingIndex] = result;
        }
      }

      notifyListeners();
    });

    await Future.delayed(timeout);
    await stopScan();

    return List<fbp.ScanResult>.unmodifiable(results);
  }

  /// Attempts to automatically connect to the first ESP32 provisioning device found.
  Future<fbp.BluetoothDevice?> autoConnect({
    Duration scanTimeout = const Duration(seconds: 15),
    int minimumRssi = -85,
  }) async {
    if (!await _prepareBluetooth()) {
      return null;
    }

    final completer = Completer<fbp.BluetoothDevice?>();

    _isScanning = true;
    notifyListeners();

    await fbp.FlutterBluePlus.startScan(
      timeout: scanTimeout,
      withServices: [],
      withRemoteIds: [],
      withNames: [],
      continuousUpdates: true,
      continuousDivisor: 1,
    );

    _scanSubscription?.cancel();
    _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) async {
      if (completer.isCompleted) return;

      for (final result in results) {
        if (!_isEsp32ProvisioningAdvert(result)) continue;
        if (result.rssi < minimumRssi) continue;

        await stopScan();

        final connected = await connect(result.device);
        if (connected) {
          completer.complete(result.device);
        } else {
          completer.complete(null);
        }
        return;
      }
    });

    await Future.delayed(scanTimeout);

    if (!completer.isCompleted) {
      await stopScan();
      completer.complete(null);
    }

    return completer.future;
  }

  Future<void> stopScan() async {
    try {
      if (fbp.FlutterBluePlus.isScanningNow) {
        await fbp.FlutterBluePlus.stopScan();
      }
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _isScanning = false;
    notifyListeners();
  }

  /// Connects to the provided ESP32 provisioning device and caches provisioning endpoints.
  Future<bool> connect(fbp.BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      await _cacheProvisioningEndpoints();
      return _endpointCharacteristics.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to connect to ESP32 device: $e');
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Ensures this service is connected to the provided device, reusing
  /// the existing connection when possible.
  Future<bool> ensureConnectedDevice(fbp.BluetoothDevice device) async {
    if (_isConnected && _connectedDevice?.remoteId == device.remoteId) {
      return true;
    }

    if (_isConnected && _connectedDevice != null) {
      await disconnect();
    }

    return connect(device);
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    } finally {
      _connectedDevice = null;
      _isConnected = false;
      _endpointCharacteristics.clear();
      notifyListeners();
    }
  }

  /// Retrieves provisioning endpoint names and their corresponding characteristics.
  Future<Map<String, fbp.BluetoothCharacteristic>> getProvisioningEndpoints() async {
    if (_endpointCharacteristics.isEmpty && _connectedDevice != null) {
      await _cacheProvisioningEndpoints();
    }
    return Map<String, fbp.BluetoothCharacteristic>.unmodifiable(_endpointCharacteristics);
  }

  /// Sends raw payload to a named provisioning endpoint.
  Future<bool> sendToEndpoint(String endpoint, List<int> payload, {bool withoutResponse = false}) async {
    final characteristic = _endpointCharacteristics[endpoint];
    if (characteristic == null) {
      debugPrint('Provisioning endpoint "$endpoint" not available');
      return false;
    }

    try {
      await characteristic.write(payload, withoutResponse: withoutResponse);
      return true;
    } catch (e) {
      debugPrint('Failed to write to endpoint $endpoint: $e');
      return false;
    }
  }

  /// Reads data from a named provisioning endpoint (if readable).
  Future<List<int>> readFromEndpoint(String endpoint) async {
    final characteristic = _endpointCharacteristics[endpoint];
    if (characteristic == null) {
      debugPrint('Provisioning endpoint "$endpoint" not available');
      return const [];
    }

    if (!characteristic.properties.read) {
      debugPrint('Endpoint "$endpoint" does not support read');
      return const [];
    }

    try {
      return await characteristic.read();
    } catch (e) {
      debugPrint('Failed to read from endpoint $endpoint: $e');
      return const [];
    }
  }

  /// Convenience helper for writing JSON payloads to custom endpoints.
  Future<bool> sendJsonToEndpoint(String endpoint, Map<String, dynamic> body) {
    final payload = utf8.encode(json.encode(body));
    return sendToEndpoint(endpoint, payload, withoutResponse: true);
  }

  /// Initiates a Wi-Fi scan on the connected ESP32 and returns the discovered
  /// access points. Results are also cached internally.
  Future<List<Esp32WifiNetwork>> scanForWifiNetworks({
    Duration scanDuration = const Duration(seconds: 12),
  }) async {
    if (!_isConnected) {
      debugPrint('Cannot scan Wi-Fi networks without an active ESP32 connection');
      return List<Esp32WifiNetwork>.unmodifiable(_lastScannedNetworks);
    }

    final scanEndpoint = _resolveEndpoint(const [
      'prov-scan',
      'wifi_scan',
      'wifi-scan',
      'scan_wifi',
      'scan',
    ]);

    if (scanEndpoint == null) {
      debugPrint('ESP32 provisioning scan endpoint not discovered');
      return List<Esp32WifiNetwork>.unmodifiable(_lastScannedNetworks);
    }

    final characteristic = _endpointCharacteristics[scanEndpoint];
    if (characteristic == null) {
      return List<Esp32WifiNetwork>.unmodifiable(_lastScannedNetworks);
    }

    final frames = await _sendJsonCommand(
      characteristic,
      {
        'command': 'scan',
        'cmd': 'scan',
        'scan': true,
      },
      timeout: scanDuration,
      expectStream: true,
    );

    final networks = _parseWifiScanFrames(frames);

    if (networks.isNotEmpty) {
      _lastScannedNetworks
        ..clear()
        ..addAll(networks);
      notifyListeners();
    }

    return networks;
  }

  /// Sends Wi-Fi credentials to the ESP32 provisioning firmware.
  ///
  /// Returns true when the configuration is acknowledged and, optionally,
  /// applies the credentials immediately.
  Future<bool> configureWifiNetwork({
    required String ssid,
    required String password,
    bool applyConfiguration = true,
  }) async {
    if (!_isConnected) {
      debugPrint('Cannot configure Wi-Fi without a connected ESP32');
      return false;
    }

    final configEndpoint = _resolveEndpoint(const [
      'prov-config',
      'wifi_config',
      'wifi-config',
      'config',
    ]);

    if (configEndpoint == null) {
      debugPrint('ESP32 Wi-Fi config endpoint not discovered');
      return false;
    }

    final characteristic = _endpointCharacteristics[configEndpoint];
    if (characteristic == null) {
      return false;
    }

    final Map<String, dynamic> payload = {
      'command': 'configure',
      'cmd': 'config',
      'ssid': ssid,
      if (password.isNotEmpty) 'password': password,
      if (password.isEmpty) 'open': true,
    };

    final frames = await _sendJsonCommand(
      characteristic,
      payload,
      timeout: const Duration(seconds: 8),
    );

    final ack = _stringifyFrames(frames);
    bool success = _ackIndicatesSuccess(ack, allowEmpty: true);

    if (success && applyConfiguration) {
      final applied = await applyWifiConfiguration();
      if (!applied) {
        debugPrint('Wi-Fi credentials sent but apply command was not acknowledged');
      }
    }

    if (!success && frames.isEmpty) {
      // Some firmware implementations do not send an acknowledgement.
      success = true;
    }

    return success;
  }

  /// Applies a pending Wi-Fi configuration, if the firmware exposes an
  /// endpoint that supports it. Returns true when the command succeeds or when
  /// no dedicated endpoint was found (best-effort).
  Future<bool> applyWifiConfiguration() async {
    if (!_isConnected) {
      return false;
    }

    final applyEndpoint = _resolveEndpoint(const [
      'prov-comm',
      'wifi_comm',
      'wifi-comm',
      'comm',
      'apply',
    ]);

    if (applyEndpoint == null) {
      // Consider the operation successful when no apply endpoint exists.
      return true;
    }

    final characteristic = _endpointCharacteristics[applyEndpoint];
    if (characteristic == null) {
      return true;
    }

    final frames = await _sendJsonCommand(
      characteristic,
      {
        'command': 'apply',
        'cmd': 'apply',
        'apply': true,
      },
      timeout: const Duration(seconds: 6),
    );

    final ack = _stringifyFrames(frames);
    return _ackIndicatesSuccess(ack, allowEmpty: true);
  }

  Future<bool> _prepareBluetooth() async {
    try {
      if (!await fbp.FlutterBluePlus.isSupported) {
        debugPrint('Bluetooth LE not supported on this device');
        return false;
      }

      final permissionStatuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      final hasRequiredPermissions = permissionStatuses.values.every((status) => status.isGranted);
      if (!hasRequiredPermissions) {
        debugPrint('Required Bluetooth permissions were not granted');
        return false;
      }

      final adapterState = await fbp.FlutterBluePlus.adapterState.first;
      if (adapterState != fbp.BluetoothAdapterState.on) {
        debugPrint('Bluetooth adapter is not powered on');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to prepare Bluetooth: $e');
      return false;
    }

    return true;
  }

  bool _isEsp32ProvisioningAdvert(fbp.ScanResult result) {
    final adv = result.advertisementData;
    final matchingServiceUuid = _customServiceUuid ?? defaultProvisioningServiceUuid;

    for (final uuid in adv.serviceUuids) {
      if (uuid.toString().toLowerCase() == matchingServiceUuid) {
        return true;
      }
    }

  final advertisedName = adv.advName.isNotEmpty ? adv.advName : '';
  final localName = advertisedName.isNotEmpty
    ? advertisedName
    : result.device.platformName;

    final name = localName.toLowerCase();
    if (name.contains('esp') || name.startsWith('prov_') || name.contains('esp32')) {
      return true;
    }

    // Optionally inspect manufacturer data for the Espressif company identifier (0x02E5)
    if (adv.manufacturerData.isNotEmpty) {
      final manufacturerIds = adv.manufacturerData.keys;
      if (manufacturerIds.any((id) => id == 0x02e5)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _cacheProvisioningEndpoints() async {
    _endpointCharacteristics.clear();
    final device = _connectedDevice;
    if (device == null) return;

    try {
      final services = await device.discoverServices();
      final matchingServiceUuid = (_customServiceUuid ?? defaultProvisioningServiceUuid);

      final provisioningService = services.firstWhere(
        (service) => service.uuid.toString().toLowerCase() == matchingServiceUuid,
        orElse: () => services.firstWhere(
          (service) => service.uuid.toString().toLowerCase().contains('ffff'),
          orElse: () => services.isNotEmpty ? services.first : throw StateError('No services found'),
        ),
      );

      for (final characteristic in provisioningService.characteristics) {
        String? endpointName;

        for (final descriptor in characteristic.descriptors) {
          if (descriptor.uuid.toString().toLowerCase() == characteristicUserDescriptionUuid) {
            final descriptorValue = await descriptor.read();
            endpointName = utf8.decode(descriptorValue, allowMalformed: true).trim();
            break;
          }
        }

        if (endpointName == null || endpointName.isEmpty) {
          // Fallback to characteristic UUID suffix to maintain uniqueness.
          final uuid = characteristic.uuid.toString();
          endpointName = 'char_${uuid.substring(uuid.length - 4)}';
        }

        _endpointCharacteristics[endpointName] = characteristic;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache provisioning endpoints: $e');
    }
  }

  String? _resolveEndpoint(List<String> aliases) {
    if (_endpointCharacteristics.isEmpty) return null;

    for (final entry in _endpointCharacteristics.entries) {
      final key = entry.key.toLowerCase();
      if (aliases.any((alias) => key.contains(alias.toLowerCase()))) {
        return entry.key;
      }
    }

    for (final entry in _endpointCharacteristics.entries) {
      final uuid = entry.value.uuid.toString().toLowerCase();
      if (aliases.any((alias) => uuid.contains(alias.toLowerCase()))) {
        return entry.key;
      }
    }

    return null;
  }

  Future<void> _enableNotifications(fbp.BluetoothCharacteristic characteristic) async {
    if ((characteristic.properties.notify || characteristic.properties.indicate) && !characteristic.isNotifying) {
      try {
        await characteristic.setNotifyValue(true);
      } catch (e) {
        debugPrint('Failed to enable notifications for ${characteristic.uuid}: $e');
      }
    }
  }

  Future<List<List<int>>> _sendJsonCommand(
    fbp.BluetoothCharacteristic? characteristic,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 8),
    bool expectStream = false,
  }) async {
    if (characteristic == null) {
      return const [];
    }

    await _enableNotifications(characteristic);

    final frames = <List<int>>[];
    StreamSubscription<List<int>>? subscription;
    Completer<void>? firstResponse;

    try {
      if (characteristic.properties.notify || characteristic.properties.indicate) {
        firstResponse = Completer<void>();
        subscription = characteristic.lastValueStream.listen((event) {
          if (event.isEmpty) return;
          frames.add(List<int>.from(event));
          if (!expectStream && !(firstResponse?.isCompleted ?? true)) {
            firstResponse?.complete();
          }
        });
      }

      final payload = utf8.encode(json.encode(body));
      final supportsWithResponse = characteristic.properties.write;
      await characteristic.write(payload, withoutResponse: !supportsWithResponse);

      if (subscription != null) {
        if (expectStream) {
          final stopwatch = Stopwatch()..start();
          while (stopwatch.elapsed < timeout) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (frames.isNotEmpty && stopwatch.elapsedMilliseconds > 800) {
              break;
            }
          }
        } else if (firstResponse != null) {
          try {
            await firstResponse.future.timeout(timeout);
          } catch (_) {}
        }
      } else {
        try {
          final value = await characteristic.read();
          if (value.isNotEmpty) {
            frames.add(List<int>.from(value));
          }
        } catch (e) {
          debugPrint('Provisioning read failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to send provisioning command: $e');
    } finally {
      await subscription?.cancel();
    }

    return frames;
  }

  List<Esp32WifiNetwork> _parseWifiScanFrames(List<List<int>> frames) {
    final networks = <Esp32WifiNetwork>[];

    for (final frame in frames) {
      if (frame.isEmpty) continue;
      final raw = utf8.decode(frame, allowMalformed: true).trim();
      if (raw.isEmpty) continue;

      final segments = raw
          .split(RegExp(r'[\r\n]+'))
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty);

      for (final segment in segments) {
        try {
          final decoded = json.decode(segment);
          _collectNetworks(decoded, networks);
        } catch (e) {
          debugPrint('Failed to decode Wi-Fi scan segment "$segment": $e');
        }
      }
    }

    return networks;
  }

  void _collectNetworks(dynamic decoded, List<Esp32WifiNetwork> accumulator) {
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          accumulator.add(Esp32WifiNetwork.fromJson(item));
        }
      }
      return;
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('aps') && decoded['aps'] is List) {
        for (final item in decoded['aps'] as List) {
          if (item is Map<String, dynamic>) {
            accumulator.add(Esp32WifiNetwork.fromJson(item));
          }
        }
        return;
      }

      if (decoded.containsKey('ssid') || decoded.containsKey('name')) {
        accumulator.add(Esp32WifiNetwork.fromJson(decoded));
        return;
      }
    }
  }

  String _stringifyFrames(List<List<int>> frames) {
    if (frames.isEmpty) return '';
    return frames
        .map((frame) => utf8.decode(frame, allowMalformed: true))
        .join('\n')
        .trim();
  }

  bool _ackIndicatesSuccess(String ack, {bool allowEmpty = false}) {
    if (ack.isEmpty) {
      return allowEmpty;
    }

    final normalised = ack.toLowerCase();
    return normalised.contains('success') ||
        normalised.contains('"status":"ok"') ||
        normalised.contains('status:0') ||
        normalised.contains('applied') ||
        normalised.contains('connected');
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}
