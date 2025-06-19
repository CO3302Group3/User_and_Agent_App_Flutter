import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingSlotScreen extends StatefulWidget {
  const ParkingSlotScreen({super.key});

  @override
  State<ParkingSlotScreen> createState() => _ParkingSlotScreenState();
}

class _ParkingSlotScreenState extends State<ParkingSlotScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(6.9271, 79.8612); // Example: Colombo

  @override
  Widget build(BuildContext context) {
    return Scaffold(



    );
  }
}
