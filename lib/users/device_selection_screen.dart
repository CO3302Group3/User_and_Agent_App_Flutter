import 'package:flutter/material.dart';
import 'package:computer_engineering_project/services/auth_service.dart';
import 'dart:convert';
import 'package:computer_engineering_project/services/token_service.dart';
import 'bikestatus.dart';

class DeviceSelectionScreen extends StatefulWidget {
  @override
  _DeviceSelectionScreenState createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  List<dynamic> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    final token = await TokenService.getToken();
    if (token == null) {
      debugPrint('DeviceSelectionScreen: No authentication token found');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authentication token found')),
      );
      return;
    }

    debugPrint('DeviceSelectionScreen: Fetching devices with token: ${token.substring(0, 10)}...');
    final response = await AuthService.authenticatedGet('/device_onboarding/get_my_devices?token=$token');
    debugPrint('DeviceSelectionScreen: API Response - Status: ${response?.statusCode}, Body: ${response?.body}');
    
    if (response != null && response.statusCode == 200) {
      final apiResponse = jsonDecode(response.body);
      debugPrint('DeviceSelectionScreen: Parsed API Response: $apiResponse');
      
      // Handle the actual API response format: {message: "...", content: [...]}
      if (apiResponse['content'] != null) {
        setState(() {
          devices = apiResponse['content'];
          isLoading = false;
        });
        debugPrint('DeviceSelectionScreen: Successfully loaded ${devices.length} devices');
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint('DeviceSelectionScreen: No content field in response');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiResponse['message'] ?? 'Failed to load devices')),
        );
      }
    } else {
      debugPrint('DeviceSelectionScreen: API call failed - Status: ${response?.statusCode}');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load devices')),
      );
    }
  }

  Future<void> addNewDevice() async {
    // Show dialog to add new device
    final deviceName = await showDialog<String>(
      context: context,
      builder: (context) => AddDeviceDialog(),
    );
    if (deviceName != null && deviceName.isNotEmpty) {
      final token = await TokenService.getToken();

      debugPrint('DeviceSelectionScreen: Adding new device - Name: $deviceName');

      if (token == null) {
        debugPrint('DeviceSelectionScreen: Authentication failed - No token');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      final requestBody = {
        'user': {},
        'user_defined_name': deviceName,
        'token': token,
      };
      debugPrint('DeviceSelectionScreen: Sending POST request to /device_onboarding/add_device with body: $requestBody');

      final response = await AuthService.authenticatedPost('/device_onboarding/add_device', requestBody);
      debugPrint('DeviceSelectionScreen: Add device API Response - Status: ${response?.statusCode}, Body: ${response?.body}');
      
      if (response != null && response.statusCode == 200) {
        final apiResponse = jsonDecode(response.body);
        debugPrint('DeviceSelectionScreen: Parsed add device response: $apiResponse');
        
        // Handle the actual API response format
        if (apiResponse['message'] != null && apiResponse['message'].contains('successfully')) {
          debugPrint('DeviceSelectionScreen: Device added successfully, refreshing device list');
          fetchDevices(); // Refresh list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiResponse['message'] ?? 'Device added successfully')),
          );
        } else {
          debugPrint('DeviceSelectionScreen: Add device failed - message: ${apiResponse['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(apiResponse['message'] ?? 'Failed to add device')),
          );
        }
      } else {
        debugPrint('DeviceSelectionScreen: Add device API call failed - Status: ${response?.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add device')),
        );
      }
    } else {
      debugPrint('DeviceSelectionScreen: Device name was null or empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Device', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: addNewDevice,
          ),
        ],
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


      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No devices found'),
                      ElevatedButton(
                        onPressed: addNewDevice,
                        child: Text('Add New Device'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Container(
                        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 25), // spacing between tiles
                    decoration: BoxDecoration(
                    color: Colors.indigo.shade900.withOpacity(0.4), // light blue with transparency
                    borderRadius: BorderRadius.circular(12), // rounded corners
                    ),
                    child: ListTile(
                    title: Text(
                    device['user_preferred_name'] ?? device['name'] ?? 'Device ${index + 1}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                    device['device_id'] ?? device['id'] ?? 'Unknown ID',
                    style: TextStyle(color: Colors.white),
                    ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Bikestatus(device: device),
                          ),
                        );
                      },
                    )
                    );
                  },
                ),
      ),
    );
  }
}

class AddDeviceDialog extends StatefulWidget {
  @override
  _AddDeviceDialogState createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Device'),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(labelText: 'Device Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_nameController.text),
          child: Text('Add'),
        ),
      ],
    );
  }
}