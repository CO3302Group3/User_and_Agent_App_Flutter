import 'package:flutter/material.dart';

class Bikestatus extends StatefulWidget {
  const Bikestatus({super.key});

  @override
  State<Bikestatus> createState() => _BikestatusState();
}

class _BikestatusState extends State<Bikestatus> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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

        child: Container(

        ),

      ),
    );
  }
}
