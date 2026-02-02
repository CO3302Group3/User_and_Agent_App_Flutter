import 'package:computer_engineering_project/users/ParkingHistoryScreen.dart';
import 'package:computer_engineering_project/main.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:async'; // Added for StreamSubscription
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class Parkingslotscreen extends StatefulWidget {
  const Parkingslotscreen({super.key});

  @override
  State<Parkingslotscreen> createState() => _ParkingslotscreenState();
}

class _ParkingslotscreenState extends State<Parkingslotscreen> {
  // Faculty of Engineering, University of Sri Jayewardenepura
  final LatLng _defaultLocation = const LatLng(6.823591, 79.968251); 
  LatLng? _currentLocation; // Will be set to default init below

  /// Parking slots (with LatLng and address)
  List<Map<String, dynamic>> _parkingSlots = [];

  GoogleMapController? _googleMapController;
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  // Init markers with the starting location immediately
  late Set<Marker> _markers = {};

  LatLng? _selectedParkingSlot;
  Map<String, dynamic>? _selectedSlotData; // To store price, etc.
  
  bool _showReserveButton = false;

  // 0: Idle (Book Now), 1: Booked (Travel), 2: Parked (Check Out)
  int _bookingStep = 0; 
  DateTime? _checkInTime;

  // API Key for Directions & Geocoding & Maps SDK
  // API Key for Directions & Geocoding & Maps SDK
  final String _googleApiKey = "AIzaSyBaevYWw5OSDragkEtxzwlj5R0T66BnzS0";

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    // Default start
    _currentLocation = _defaultLocation;
    _markers = {}; // No manual marker here

    _fetchCurrentLocation();
    _fetchParkingSlots();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  /// ===============================
  /// LIVE NAVIGATION (Stream)
  /// ===============================
  void _startLiveTracking() {
    print("Starting live tracking...");
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
       print("Live Location: ${position.latitude}, ${position.longitude}");
       if (mounted) {
         setState(() {
           _currentLocation = LatLng(position.latitude, position.longitude);
           
           // No manual marker update needed (handled by GoogleMap)

           // Recalculate Polyline (Truncate passed points)
           if (_routePoints.isNotEmpty) {
              int closestIndex = -1;
              double minDistance = double.infinity;

              // Find closest point on route to current location
              for (int i = 0; i < _routePoints.length; i++) {
                 double dist = Geolocator.distanceBetween(
                    _currentLocation!.latitude, _currentLocation!.longitude, 
                    _routePoints[i].latitude, _routePoints[i].longitude
                 );
                 if (dist < minDistance) {
                    minDistance = dist;
                    closestIndex = i;
                 }
              }

              // If we found a close point (within 50m), truncate route
              if (closestIndex != -1 && minDistance < 50) {
                 if (closestIndex < _routePoints.length - 1) {
                    List<LatLng> remainingPoints = _routePoints.sublist(closestIndex);
                    _polylines = {
                       Polyline(
                         polylineId: const PolylineId("route"),
                         points: remainingPoints,
                         color: Colors.blue,
                         width: 5,
                       ),
                    };
                 } else {
                    _polylines = {}; // Arrived
                 }
              }
           }
         });
         
         // Animate Camera
         _googleMapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 18,
                bearing: position.heading, 
                tilt: 45, 
              ),
            ),
         );
       }
    });
  }

  /// ===============================
  /// GET USER CURRENT LOCATION
  /// ===============================
  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
         print('Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
        print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition();
      print("Got current location: ${position.latitude}, ${position.longitude}");
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        _googleMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// ===============================
  /// GEOCODING (Address → LatLng)
  /// ===============================
  Future<LatLng?> _geocodeAddress(String address) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json"
          "?address=${Uri.encodeComponent(address)}"
          "&components=country:LK"
          "&key=$_googleApiKey",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else {
          debugPrint("Geocoding failed for $address: ${data['status']}");
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return null;
  }

  /// ===============================
  /// FETCH PARKING SLOTS FROM API
  /// ===============================
  Future<void> _fetchParkingSlots() async {
    final url = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots");

    print("Fetching parking slots from: $url");
    try {
      final response = await http.get(url);
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List slots = decoded['parking_slots'];
        print("Found ${slots.length} slots from API");

        List<Map<String, dynamic>> loadedSlots = [];

        for (var slot in slots) {
          LatLng? latLng;
          if (slot['address'] != null) {
            latLng = await _geocodeAddress(slot['address']);
          }
          
          if (latLng != null) {
            // Store all details including Price
            loadedSlots.add({
              "id": slot['id'] ?? slot['slot_id'],
              "name": slot['name'],
              "address": slot['address'],
              "price": slot['price'] ?? "0", // String or int
              "bikesAllowed": slot['bikes_allowed'],
              "latLng": latLng,
            });
            print("Loaded slot: ${slot['name']} at $latLng");
          } else {
             print("Skipping slot ${slot['name']} - No coords");
          }
        }

        if (mounted) {
          Set<Marker> newMarkers = {};
          
          for (var slot in loadedSlots) {
             final LatLng pos = slot['latLng'];
             // Generate Custom Bitmap
             BitmapDescriptor icon = await _createCustomMarkerBitmap(slot['name'], slot['address']);
             
             newMarkers.add(
               Marker(
                 markerId: MarkerId(slot['id'] ?? slot['name']),
                 position: pos,
                 icon: icon,
                 // infoWindow: InfoWindow(title: slot['name']), // Optional now
                 onTap: () {
                    setState(() {
                      _selectedParkingSlot = pos;
                      _selectedSlotData = slot;
                      _showReserveButton = true;
                      _polylines = {}; 
                      _circles = {
                        Circle(
                          circleId: CircleId("geofence_${slot['id']}"),
                          center: pos,
                          radius: 500, // 500m
                          strokeWidth: 2,
                          strokeColor: Colors.redAccent,
                          fillColor: Colors.redAccent.withOpacity(0.15),
                        ),
                      }; 
                    });
                    _googleMapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(pos, 16),
                    );
                 },
               ),
             );
          }

          setState(() {
            _parkingSlots = loadedSlots;
            _markers = newMarkers;
          });
        }
      } else {
        print("Failed to fetch slots. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API error: $e");
    }
  }

  List<LatLng> _routePoints = [];
  Timer? _simulationTimer;

  /// ===============================
  /// DIRECTIONS API (Polyline)
  /// ===============================
  Future<void> _getDirections(LatLng dest) async {
    print("Getting directions to $dest...");
    if (_currentLocation == null) return;
    
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey, 
        request: PolylineRequest(
          origin: PointLatLng(_currentLocation!.latitude, _currentLocation!.longitude), 
          destination: PointLatLng(dest.latitude, dest.longitude), 
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        
        _routePoints = polylineCoordinates; // Store for simulation

        if (mounted) {
          setState(() {
            _polylines = {
               Polyline(
                 polylineId: const PolylineId("route"),
                 points: polylineCoordinates,
                 color: Colors.blue,
                 width: 5,
               ),
            };
          });
          
          // Fit camera initially
          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(
              min(_currentLocation!.latitude, dest.latitude),
              min(_currentLocation!.longitude, dest.longitude),
            ),
            northeast: LatLng(
              max(_currentLocation!.latitude, dest.latitude),
              max(_currentLocation!.longitude, dest.longitude),
            ),
          );
          _googleMapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("No route found: ${result.status}")),
        );
      }
    } catch (e) {
      print("Error in _getDirections: $e");
    }
  }

  /// ===============================
  /// SIMULATED NAVIGATION
  /// ===============================
  void _startSimulation() {
    if (_routePoints.isEmpty) return;
    print("Starting simulation with ${_routePoints.length} points");
    
    int index = 0;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (index >= _routePoints.length) {
        timer.cancel();
        // Arrival Logic
        showDialog(
          context: context, 
          builder: (_) => AlertDialog(
            title: const Text("Arrived"),
            content: const Text("You have reached the parking slot."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          )
        );
        return;
      }

      final pos = _routePoints[index];
      index++;

      if (mounted) {
        setState(() {
          _currentLocation = pos;
          _markers.removeWhere((m) => m.markerId.value == "current_loc");
          _markers.add(
            Marker(
              markerId: const MarkerId("current_loc"),
              position: pos,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: "You"),
              rotation: 0, 
            ),
          );
          
          // Truncate the route line as we move (Navigation effect)
          if (index < _routePoints.length) {
            List<LatLng> remainingPoints = _routePoints.sublist(index);
            _polylines = {
               Polyline(
                 polylineId: const PolylineId("route"),
                 points: remainingPoints,
                 color: Colors.blue,
                 width: 5,
               ),
            };
          } else {
            _polylines = {};
          }
        });

        _googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: pos,
              zoom: 19,
              tilt: 50, // More tilted for driving view
              bearing: index < _routePoints.length 
                  ? _calculateBearing(_routePoints[index-1], _routePoints[index])
                  : 0, 
            ),
          ),
        );
      }
    });
  }

  // Helper to calculate bearing for smoother camera rotation
  double _calculateBearing(LatLng start, LatLng end) {
    // Basic bearing calculation could be added here, or just default to 0.
    // implementing a simple one:
    double lat1 = start.latitude * pi / 180;
    double lng1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lng2 = end.longitude * pi / 180;

    double dLon = lng2 - lng1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radians = atan2(y, x);
    return (radians * 180 / pi + 360) % 360;
  }

  /// ===============================
  /// DISTANCE CALCULATION
  /// ===============================
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude, 
      end.latitude, end.longitude
    ) / 1000; // in km
  }

  /// ===============================
  /// PAYMENT MOCK
  /// ===============================
  Future<void> _makePayment(String price) async {
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

  /// ===============================
  /// CHECK-IN / CHECK-OUT
  /// ===============================
  void _handleCheckInOut() {
    _simulationTimer?.cancel(); // Stop sim if checked out
    // If step 2, we are checking out
    if (_bookingStep == 2) {
      // GEOFENCING CHECK (1km)
      if (_currentLocation != null && _selectedParkingSlot != null) {
         double dist = _calculateDistance(_currentLocation!, _selectedParkingSlot!);
         if (dist > 0.5) { // 500m
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("You are too far! Please come closer to Check Out. (Distance: ${dist.toStringAsFixed(1)} km)"),
               backgroundColor: Colors.red,
             ),
           );
           return;
         }
      }

      final minutes = DateTime.now().difference(_checkInTime!).inMinutes;
      // Simple cost calc
      double pricePerHour = 0;
      if (_selectedSlotData != null) {
         pricePerHour = double.tryParse(_selectedSlotData!['price'].toString()) ?? 0;
      }
      
      final cost = (minutes / 60) * pricePerHour;

      setState(() {
        _bookingStep = 0;
        _checkInTime = null;
        _polylines = {}; // Clear route on checkout
        _routePoints = [];
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Check-Out Complete"),
          content: Text("Parked for $minutes minutes\nTotal: Rs. ${cost.toStringAsFixed(2)}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _currentLocation ?? _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Slots"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Parkinghistoryscreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              myLocationEnabled: true, 
              zoomGesturesEnabled: true,
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 15,
              ),
              onMapCreated: (controller) => _googleMapController = controller,
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
            ),
          ),
          
          if (_selectedSlotData != null && _currentLocation != null)
            _buildDetailPanel()
        ],
      ),
    );
  }



  Widget _buildDetailPanel() {
    final distKm = _calculateDistance(_currentLocation!, _selectedParkingSlot!);
    final priceStr = _selectedSlotData?['price'] ?? "0";
    final durationMin = (distKm / 30 * 60).round(); 
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black12)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(
             _selectedSlotData?['name'] ?? "Parking Slot",
             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 5),
           Text(
             _selectedSlotData?['address'] ?? "",
             style: const TextStyle(fontSize: 14, color: Colors.grey),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 5),
           Text(
             "Available: ${_selectedSlotData?['bikesAllowed'] ?? 0} Bikes",
             style: TextStyle(fontSize: 16, color: Colors.indigo.shade700, fontWeight: FontWeight.w500),
           ),
           const SizedBox(height: 10),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               Column(
                 children: [
                   const Icon(Icons.directions_car, color: Colors.grey),
                   Text("${distKm.toStringAsFixed(1)} km"),
                 ],
               ),
               Column(
                 children: [
                   const Icon(Icons.timer, color: Colors.grey),
                   Text("~$durationMin min"),
                 ],
               ),
               Column(
                 children: [
                   const Icon(Icons.monetization_on, color: Colors.grey),
                   Text("Rs. $priceStr/hr"),
                 ],
               ),
             ],
           ),
           const SizedBox(height: 15),
           
           // ACTION BUTTONS
           if (_bookingStep == 0) ...[
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blueAccent,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                 ),
                 onPressed: () {
                    // BOOK NOW -> Payment Mock
                    _makePayment(priceStr).then((_) {
                       setState(() {
                         _bookingStep = 1; // Now Booked
                         // Generate Route to this slot
                         _getDirections(_selectedParkingSlot!);
                       });
                    });
                 }, 
                 child: const Text("Book Now", style: TextStyle(fontSize: 18, color: Colors.white)),
               ),
             ),
           ] else if (_bookingStep == 1) ...[
              SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.green, // Visual cue for "Go"
                   padding: const EdgeInsets.symmetric(vertical: 12),
                 ),
                 onPressed: () {
                    // TRAVEL -> Start Simulation or Tracking
                    if (_routePoints.isEmpty) {
                      _getDirections(_selectedParkingSlot!);
                    }
                    
                    // START LIVE TRACKING (Real GPS)
                    _startLiveTracking(); 
                    
                    setState(() {
                       _bookingStep = 2; // Go to Check Out
                       _checkInTime = DateTime.now();
                    });
                 }, 
                 child: const Text("Travel", style: TextStyle(fontSize: 18, color: Colors.white)),
               ),
             ),
           ] else ...[
              SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.redAccent,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                 ),
                 onPressed: _handleCheckInOut, 
                 child: const Text("Check Out", style: TextStyle(fontSize: 18, color: Colors.white)),
               ),
             ),
           ]
        ],
      ),
    );
  }

  /// ===============================
  /// CUSTOM MARKER GENERATOR (Text + Pin)
  /// ===============================
  Future<BitmapDescriptor> _createCustomMarkerBitmap(String name, String address) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Config
    const double width = 450; // Increased width
    const double height = 250; 
    const double pinSize = 60; 
    
    // 1. Draw Text (Name)
    final TextPainter namePainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );
    namePainter.text = TextSpan(
      text: name,
      style: const TextStyle(
        fontSize: 35, // Large font for map
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
    namePainter.layout(maxWidth: width - 20);
    
    // 2. Draw Text (Address) - truncated
    final TextPainter addrPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );
    addrPainter.text = TextSpan(
      text: address,
      style: const TextStyle(
        fontSize: 22,
        color: Colors.black87,
      ),
    );
    addrPainter.layout(maxWidth: width - 20);

    // Paint Text centered nicely above the pin
    final double textTotalHeight = namePainter.height + addrPainter.height + 14;
    final double textY = height - pinSize - textTotalHeight - 20;
    
    // Background bubble for text
    final Paint bubblePaint = Paint()..color = Colors.white.withOpacity(0.95);
    final RRect bubbleRect = RRect.fromRectAndRadius(
       Rect.fromCenter(
         center: Offset(width / 2, textY + textTotalHeight / 2),
         width: max(namePainter.width, addrPainter.width) + 40,
         height: textTotalHeight + 10,
       ),
       const Radius.circular(15),
    );
    canvas.drawRRect(bubbleRect, bubblePaint);
    
    // Draw Border
    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Draw Texts
    namePainter.paint(canvas, Offset((width - namePainter.width) / 2, textY + 5));
    addrPainter.paint(canvas, Offset((width - addrPainter.width) / 2, textY + namePainter.height + 8));

    // 3. Draw Red Pin
    final double pinCenterY = height - (pinSize / 2);
    final Paint pinPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(width / 2, pinCenterY), pinSize / 2, pinPaint);
    canvas.drawCircle(Offset(width / 2, pinCenterY), pinSize / 4, Paint()..color = Colors.white);

    // Convert to Image
    final ui.Image image = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
