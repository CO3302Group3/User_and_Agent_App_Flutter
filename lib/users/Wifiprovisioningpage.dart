import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class WifiProvisioningPage extends StatefulWidget {
  final BluetoothDevice? device;

  const WifiProvisioningPage({this.device, super.key});

  @override
  State<WifiProvisioningPage> createState() => _WifiProvisioningPageState();
}

class _WifiProvisioningPageState extends State<WifiProvisioningPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _sending = false;

  Future<void> _sendWifiCredentials() async {
    if (widget.device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Device not connected")),
      );
      return;
    }

    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both SSID and password")),
      );
      return;
    }

    try {
      setState(() => _sending = true);

      // Discover services
      List<BluetoothService> services = await widget.device!.discoverServices();

      // Loop through services/characteristics to find correct UUID
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          // Replace UUID with the one used in ESP32 provisioning
          if (c.properties.write) {
            final wifiData = json.encode({
              "ssid": ssid,
              "password": password,
            });

            await c.write(utf8.encode(wifiData), withoutResponse: true);
            print("✅ Sent Wi-Fi credentials: $wifiData");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Wi-Fi credentials sent")),
            );
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No writable characteristic found")),
      );
    } catch (e) {
      print("Error sending Wi-Fi credentials: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send Wi-Fi credentials")),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wi-Fi", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: "Wi-Fi SSID",
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Wi-Fi Password",
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _sending ? null : _sendWifiCredentials,
              icon: Icon(Icons.wifi),
              label: Text("Send to Device"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            if (_sending) SizedBox(height: 20),
            if (_sending) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
