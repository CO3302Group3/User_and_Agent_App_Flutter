import 'dart:convert';

import 'package:computer_engineering_project/services/bluetooth_service.dart';
import 'package:computer_engineering_project/services/esp32_provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiProvisioningPage extends StatefulWidget {
  const WifiProvisioningPage({this.device, super.key});

  final BluetoothDevice? device;

  @override
  State<WifiProvisioningPage> createState() => _WifiProvisioningPageState();
}

class _WifiProvisioningPageState extends State<WifiProvisioningPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final Esp32ProvisioningService _provisioningService = Esp32ProvisioningService();
  final BikeBluetoothService _legacyBluetoothService = BikeBluetoothService();

  List<Esp32WifiNetwork> _networks = <Esp32WifiNetwork>[];
  Esp32WifiNetwork? _selectedNetwork;

  bool _loadingNetworks = false;
  bool _sending = false;
  bool _manualEntry = false;
  bool _obscurePassword = true;
  String? _statusMessage;

  bool get _shouldRequirePassword => !_manualEntry && (_selectedNetwork?.requiresPassword ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialiseProvisioningFlow());
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initialiseProvisioningFlow() async {
    setState(() {
      _loadingNetworks = true;
      _statusMessage = null;
    });

    final connected = await _ensureProvisioningConnection();

    if (!mounted) return;

    if (!connected) {
      setState(() {
        _loadingNetworks = false;
        _statusMessage = 'Connect to an ESP32 device to provision Wi-Fi.';
        _networks = <Esp32WifiNetwork>[];
      });
      return;
    }

    await _refreshNetworks(showLoader: false);
    if (mounted) {
      setState(() => _loadingNetworks = false);
    }
  }

  Future<bool> _ensureProvisioningConnection() async {
    if (_provisioningService.isConnected) {
      return true;
    }

    final fallbackDevice = widget.device ?? _provisioningService.connectedDevice ?? _legacyBluetoothService.connectedDevice;
    if (fallbackDevice == null) {
      return false;
    }

    return _provisioningService.ensureConnectedDevice(fallbackDevice);
  }

  Future<void> _refreshNetworks({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loadingNetworks = true;
        _statusMessage = null;
      });
    }

    final connected = await _ensureProvisioningConnection();
    if (!mounted) return;

    if (!connected) {
      setState(() {
        _loadingNetworks = false;
        _statusMessage = 'ESP32 device is not connected.';
        _networks = <Esp32WifiNetwork>[];
      });
      return;
    }

    final networks = await _provisioningService.scanForWifiNetworks();

    if (!mounted) return;

    setState(() {
      _loadingNetworks = false;
      _networks = networks;
      _statusMessage = networks.isEmpty ? 'No Wi-Fi networks detected. Try refreshing.' : null;
      _synchroniseSelection();
    });
  }

  void _synchroniseSelection() {
    if (_manualEntry) {
      return;
    }

    if (_networks.isEmpty) {
      _selectedNetwork = null;
      return;
    }

    Esp32WifiNetwork? match;
    if (_selectedNetwork != null) {
      for (final network in _networks) {
        if (network.ssid == _selectedNetwork!.ssid) {
          match = network;
          break;
        }
      }
    }

    _selectedNetwork = match ?? _networks.first;
    _ssidController.text = _selectedNetwork?.ssid ?? '';
    if (_selectedNetwork != null && !_selectedNetwork!.requiresPassword) {
      _passwordController.clear();
    }
  }

  void _selectNetwork(Esp32WifiNetwork network) {
    FocusScope.of(context).unfocus();
    setState(() {
      _manualEntry = false;
      _selectedNetwork = network;
      _ssidController.text = network.ssid;
      if (!network.requiresPassword) {
        _passwordController.clear();
      }
    });
  }

  void _toggleManualEntry() {
    FocusScope.of(context).unfocus();
    setState(() {
      _manualEntry = !_manualEntry;
      if (_manualEntry) {
        _selectedNetwork = null;
        _ssidController.clear();
        _passwordController.clear();
      } else {
        _synchroniseSelection();
      }
    });
  }

  Future<void> _sendWifiCredentials() async {
    FocusScope.of(context).unfocus();

    if (!_manualEntry && _selectedNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Wi-Fi network.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _sending = true);

    try {
      final connected = await _ensureProvisioningConnection();
      if (!connected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ESP32 device is not connected.')),
        );
        return;
      }

      var success = await _provisioningService.configureWifiNetwork(
        ssid: ssid,
        password: password,
        applyConfiguration: true,
      );

      if (!success) {
        success = await _legacyWriteCredentials(ssid, password);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Wi-Fi credentials sent to ESP32.' : 'Failed to send Wi-Fi credentials.'),
        ),
      );

      if (success) {
        setState(() {
          _statusMessage = 'Credentials sent successfully.';
        });
      }
    } catch (e) {
      debugPrint('Error sending Wi-Fi credentials: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send Wi-Fi credentials.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<bool> _legacyWriteCredentials(String ssid, String password) async {
    try {
      final device = _provisioningService.connectedDevice ?? widget.device ?? _legacyBluetoothService.connectedDevice;
      if (device == null) {
        return false;
      }

      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            final wifiData = json.encode({
              'ssid': ssid,
              'password': password,
            });

            final supportsWithResponse = characteristic.properties.write;
            await characteristic.write(
              utf8.encode(wifiData),
              withoutResponse: !supportsWithResponse,
            );
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Legacy Wi-Fi credential write failed: $e');
    }

    return false;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
  fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNetworkSection() {
    if (_manualEntry) {
      return _buildInfoCard('Enter the Wi-Fi credentials manually for hidden networks.');
    }

    if (_loadingNetworks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_networks.isEmpty) {
      return _buildInfoCard(_statusMessage ?? 'No Wi-Fi networks detected. Tap refresh to scan again.');
    }

    return Column(
      children: _networks
          .map(
            (network) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
        color: (!_manualEntry && _selectedNetwork?.ssid == network.ssid)
          ? Colors.indigo.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => _selectNetwork(network),
                  title: Text(
                    network.ssid.isNotEmpty ? network.ssid : '(Hidden SSID)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${network.securityLabel} • ${network.rssi} dBm',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Icon(Icons.wifi, color: Colors.indigo.shade100),
                  selected: !_manualEntry && _selectedNetwork?.ssid == network.ssid,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiresPassword = _shouldRequirePassword;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wi-Fi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade800,
        actions: [
          IconButton(
            onPressed: _loadingNetworks ? null : () => _refreshNetworks(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh networks',
          ),
          IconButton(
            onPressed: _toggleManualEntry,
            icon: Icon(_manualEntry ? Icons.list_alt : Icons.edit, color: Colors.white),
            tooltip: _manualEntry ? 'Use scanned networks' : 'Enter hidden network',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Available Networks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNetworkSection(),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _ssidController,
                      readOnly: !_manualEntry && _selectedNetwork != null,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Wi-Fi SSID'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'SSID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      enabled: _manualEntry || requiresPassword,
                      decoration: _inputDecoration('Wi-Fi Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (requiresPassword && (value == null || value.trim().isEmpty)) {
                          return 'Password required for this network';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendWifiCredentials,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi),
                label: Text(_sending ? 'Sending...' : 'Send to Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(_statusMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
