import 'package:flutter/material.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Updates & Notices", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: const Center(
        child: Text(
          "You're using the latest version.\nNo updates available.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
