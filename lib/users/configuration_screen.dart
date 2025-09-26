import 'package:flutter/material.dart';
import '../services/config_manager.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final TextEditingController _baseUrlController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _baseUrlController.text = ConfigManager.baseURL;
  }
  
  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  void _updateConfiguration() {
    final newBaseURL = _baseUrlController.text.trim();
    if (newBaseURL.isNotEmpty) {
      ConfigManager.updateBaseURL(newBaseURL);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base URL updated to: $newBaseURL'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _resetToDefault() {
    ConfigManager.resetToDefault();
    _baseUrlController.text = ConfigManager.baseURL;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration reset to default'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final endpoints = ConfigManager.getAllEndpoints();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'Enter server IP address (e.g., 192.168.1.100)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateConfiguration,
                  child: const Text('Update Configuration'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _resetToDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Reset to Default'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Current Endpoints',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: endpoints.length,
                itemBuilder: (context, index) {
                  final entry = endpoints.entries.elementAt(index);
                  return Card(
                    child: ListTile(
                      title: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        entry.value,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}