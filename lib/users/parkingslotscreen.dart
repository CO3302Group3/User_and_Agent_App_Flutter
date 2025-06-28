import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class Parkingslotscreen extends StatefulWidget {
  const Parkingslotscreen({super.key});

  @override
  State<Parkingslotscreen> createState() => _ParkingslotscreenState();
}

class _ParkingslotscreenState extends State<Parkingslotscreen> {
  static const LatLng _boralesgamuwa = LatLng(6.8210, 79.8913);
  static const LatLng _parkingSlot = LatLng(6.8722, 79.8862);

  static const _initialCameraPosition = CameraPosition(
    target: _boralesgamuwa,
    zoom: 12.0,
  );

  late GoogleMapController _googleMapController;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _simulateRoute();
  }

  void _simulateRoute() {
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: [
          _boralesgamuwa,
          LatLng(6.8300, 79.8900),
          LatLng(6.8400, 79.8880),
          LatLng(6.8500, 79.8870),
          LatLng(6.8600, 79.8870),
          _parkingSlot,
        ],
      ),
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371;
    final dLat = _deg2rad(end.latitude - start.latitude);
    final dLon = _deg2rad(end.longitude - start.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(start.latitude)) *
            cos(_deg2rad(end.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Future<void> _makePayment(int price) async {
    // Replace with real Stripe payment logic later
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payment Successful"),
        content: Text("Rs. $price paid. Slot booked."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double distanceKm = _calculateDistance(_boralesgamuwa, _parkingSlot);
    int durationMin = (distanceKm / 40 * 60).round();
    int price = (distanceKm * 50).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Slot ",style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) => _googleMapController = controller,
              markers: {
                Marker(
                  markerId: const MarkerId("current_location"),
                  position: _boralesgamuwa,
                  infoWindow: const InfoWindow(title: "You are here"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId("parking_slot"),
                  position: _parkingSlot,
                  infoWindow: const InfoWindow(title: "Parking Slot"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              },
              polylines: _polylines,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Distance: ${distanceKm.toStringAsFixed(2)} km",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Duration: ~${durationMin} min",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "Price: Rs. $price",
                          style: const TextStyle(fontSize: 14, color: Colors.green),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _makePayment(price),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: const Text("Book Now",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _googleMapController.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            min(_boralesgamuwa.latitude, _parkingSlot.latitude),
                            min(_boralesgamuwa.longitude, _parkingSlot.longitude),
                          ),
                          northeast: LatLng(
                            max(_boralesgamuwa.latitude, _parkingSlot.latitude),
                            max(_boralesgamuwa.longitude, _parkingSlot.longitude),
                          ),
                        ),
                        100,
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text("Navigate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size.fromHeight(30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
