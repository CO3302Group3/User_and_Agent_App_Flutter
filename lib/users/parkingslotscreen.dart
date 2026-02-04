import 'package:computer_engineering_project/users/ParkingHistoryScreen.dart';
import 'package:computer_engineering_project/services/token_storage_fallback.dart';

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
import 'ParkingHistoryScreen.dart';
import 'Accountsetting.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Parkingslotscreen extends StatefulWidget {
  const Parkingslotscreen({super.key});

  @override
  State<Parkingslotscreen> createState() => _ParkingslotscreenState();
}

class _ParkingslotscreenState extends State<Parkingslotscreen> {
  // ... (existing vars) ...
  final LatLng _defaultLocation = const LatLng(6.823591, 79.968251); 
  LatLng? _currentLocation; 
  List<Map<String, dynamic>> _parkingSlots = [];
  GoogleMapController? _googleMapController;
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  late Set<Marker> _markers = {};
  LatLng? _selectedParkingSlot;
  Map<String, dynamic>? _selectedSlotData; 
  bool _showReserveButton = false;
  int _bookingStep = 0; 
  DateTime? _checkInTime;
  final String _googleApiKey = "AIzaSyBaevYWw5OSDragkEtxzwlj5R0T66BnzS0";
  Timer? _statusTimer;
  String? _currentPlateNumber; 
  bool _hasStartedNavigation = false;
  StreamSubscription<Position>? _positionStream;

  // Bike Tracking
  String? _bikeDeviceId;
  LatLng? _bikeLocation;


  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation().then((_) {
       _startLiveTracking();
    });
    _fetchParkingSlots().then((_) {
       _restoreState();
    });
    
    // Fetch user's bike to track
    _fetchMyBike().then((_) {
       if (_bikeDeviceId != null) {
          _fetchBikeLocation();
       }
    });
  }
  
  Future<void> _fetchMyBike() async {
     try {
       final token = await TokenStorageFallback.getToken();
       if (token == null) return;
       final url = Uri.parse("http://${appConfig.baseURL}/device_onboarding/get_my_devices?token=$token");
       final response = await http.get(url);
       if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['content'] as List<dynamic>?;
          if (content != null && content.isNotEmpty) {
             // Pick the first device for now
             final device = content[0];
             setState(() {
                _bikeDeviceId = device['device_id'] ?? device['id'];
             });
             print("Tracking Bike ID: $_bikeDeviceId");
          }
       }
     } catch(e) {
        print("Error fetching bike: $e");
     }
  }

  Future<void> _fetchBikeLocation() async {
    if (_bikeDeviceId == null) return;
    try {
        final url = Uri.parse("http://${appConfig.baseURL}/telemetry/latest/$_bikeDeviceId");
        final response = await http.get(url);
        if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           final telemetry = data['telemetry'];
           final lat = _parseCoordinate(telemetry, ['lat', 'latitude', 'Latitude']);
           final lng = _parseCoordinate(telemetry, ['long', 'lng', 'longitude', 'Longitude']);
           
           if (lat != null && lng != null) {
              setState(() {
                 _bikeLocation = LatLng(lat, lng);
                 // We need to update markers. For simplicity, we can just trigger a rebuild 
                 // and let the build method or marker construction handle it.
                 // But _markers is a Set<Marker>. We should add/update the bike marker.
                 _updateBikeMarker();
              });
           }
        }
    } catch(e) {
       print("Error fetching bike location: $e");
    }
  }

  double? _parseCoordinate(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      if (source.containsKey(key)) {
        final val = source[key];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val);
      }
    }
    return null;
  }
  
  void _updateBikeMarker() async {
     if (_bikeLocation == null) return;
     
     final bikeMarker = Marker(
        markerId: const MarkerId("user_bike"),
        position: _bikeLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Azure for Bike
        infoWindow: const InfoWindow(title: "My Bike"),
        zIndex: 10,
     );
     
     setState(() {
         // distinct from slot markers? 
         // Strategy: _markers set contains Slot Markers + Bike Marker.
         // We need to ensure we don't wipe slot markers.
         _markers.removeWhere((m) => m.markerId.value == "user_bike");
         _markers.add(bikeMarker);
     });
     
     // Move Camera to Bike Location
     if (_googleMapController != null) {
        _googleMapController!.animateCamera(CameraUpdate.newLatLng(_bikeLocation!));
     }
  }

  void _startStatusPolling() {
      _statusTimer?.cancel();
      _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
          // Poll Bike Location
          if (_bikeDeviceId != null) _fetchBikeLocation();

          if (_selectedSlotData == null || _currentLocation == null) return; // Allow bike polling even if no slot selected? Yes.
          if (_selectedSlotData == null) return;
          
          // Poll Backend for Slot
           final slotId = _selectedSlotData!['id'] ?? _selectedSlotData!['slot_id'];
           try {
             final url = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots/$slotId");
             final response = await http.get(url, headers: {'Content-Type': 'application/json'});
             if (response.statusCode == 200) {
                 final data = jsonDecode(response.body);
                 final bookings = data['bookings'] as List<dynamic>? ?? [];
                 // Find my booking
                 final myBooking = bookings.lastWhere((b) => b['plate_number'] == _currentPlateNumber, orElse: () => null);
                 if (myBooking != null) {
                     final status = myBooking['status'];
                     if (status == 'active' && _bookingStep == 1) {
                        setState(() => _bookingStep = 2); // Agent Confirmed Check-In
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agent Confirmed Arrival!")));
                     } else if (status == 'completed' && _bookingStep == 2) {
                        setState(() => _bookingStep = 0); // Done
                        _statusTimer?.cancel();
                         showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Trip Completed"),
                              content: const Text("Checkout Confirmed. Thank you!"),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                            ),
                          );
                     }
                 }
             }
           } catch (e) { print(e); }
      });
  }



  Future<void> _restoreState() async {
    print("Attempting to restore state...");
    final prefs = await SharedPreferences.getInstance();
    final String? savedPlate = prefs.getString('last_plate_number');
    
    if (savedPlate != null) {
      print("Found saved plate: $savedPlate");
      setState(() {
        _currentPlateNumber = savedPlate;
      });

      // Find active booking
      for (var slot in _parkingSlots) {
         // We need to fetch details for each slot? 
         // _fetchParkingSlots already stored basic info. But 'bookings' might not be in the list view data if it's heavy?
         // In _fetchParkingSlots (Step 904), we verified it gets 'parking_slots' from backend.
         // Usually lists don't have full nested deep data?
         // Assuming we can check the slot details by ID if needed, 
         // or if the list API returns 'occupied' but not full bookings list.
         // Let's assume we need to fetch specific slot if we suspect.
         
         // optimization: Fetch only if we find a match, but we don't know which slot.
         // Let's fetch the slot details for each? No, too heavy.
         // Let's assume the 'parking_slots' endpoint returns 'bookings' list?
         // In Step 277 (View File), we saw `final List slots = decoded['parking_slots'];`
         // We didn't see if `bookings` is inside.
         // Plan B: Iterate slots and fetch details for each? Or searching is better?
      }
      
      // Better approach: Since we don't want to fetch 100 slots details.
      // We will iterate _parkingSlots (loadedSlots) which contains ID.
      // We will try to find a booking in the LOCAL loaded data if available.
      // If the LIST API includes bookings, we are good.
      // If not, we might fail to restore without iterating API calls.
      // Let's assuming list API DOES NOT return full bookings.
      // However, we can iterate and check if 'occupied' > 0, then check those.
      // Or just check them all (usually distinct number of slots is small).
      
      for (var slot in _parkingSlots) {
          final slotId = slot['id'];
          // Ideally we call API for this slot
          try {
             final url = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots/$slotId");
             final response = await http.get(url);
             if (response.statusCode == 200) {
                 final data = jsonDecode(response.body);
                 final bookings = data['bookings'] as List<dynamic>? ?? [];
                 
                 final myBooking = bookings.lastWhere((b) => b['plate_number'] == savedPlate, orElse: () => null);
                 if (myBooking != null) {
                     final status = myBooking['status'];
                     // Check if active
                     if (['booked', 'check_in_requested', 'active', 'check_out_requested'].contains(status)) {
                         print("Restoring booking in slot $slotId with status $status");
                         setState(() {
                             _selectedSlotData = slot;
                             _selectedParkingSlot = slot['latLng'];
                             _showReserveButton = true;
                             
                             if (status == 'booked' || status == 'check_in_requested') {
                                 _bookingStep = 1;
                             } else if (status == 'active' || status == 'check_out_requested') {
                                 _bookingStep = 2;
                                 if (myBooking['arrival_time'] != null) {
                                     _checkInTime = DateTime.parse(myBooking['arrival_time']);
                                 } else {
                                     _checkInTime = DateTime.now(); // Fallback
                                 }
                             }
                         });
                         _startStatusPolling();
                         return; // Stop looking
                     }
                 }
             }
          } catch (e) { print("Error restoring slot $slotId: $e"); }
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _googleMapController?.dispose();
    _statusTimer?.cancel();
    _simulationTimer?.cancel(); // Ensure cleanup
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
          
         // GPS Camera Animation DISABLED as per user request
         // Only bike location will drive camera updates.
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
        
        // REMOVED: Camera animation to User GPS. 
        // User wants only Bike location to drive camera.
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
          if (slot['address'] != null && slot['address'].isNotEmpty) {
            latLng = await _geocodeAddress(slot['address']);
          }
          
          // Fallback if Geocoding failed (for Testing purposes)
          if (latLng == null) {
             print("Geocoding failed for ${slot['name']}. Using Random Offset.");
             // Random offset around default location (~500m radius)
             final rng = Random();
             final double lat = _defaultLocation.latitude + (rng.nextDouble() - 0.5) * 0.01;
             final double lng = _defaultLocation.longitude + (rng.nextDouble() - 0.5) * 0.01;
             latLng = LatLng(lat, lng);
          }


          if (latLng != null) {
            // Store all details including Price
            loadedSlots.add({
              "id": slot['id'] ?? slot['slot_id'],
              "name": slot['name'],
              "address": slot['address'],
              "price": slot['price'] ?? "0", // String or int
              "bikesAllowed": slot['bikes_allowed'],
              "occupied": slot['occupied'] ?? 0, 
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
                 infoWindow: InfoWindow(
                   title: slot['name'],
                   snippet: "Rs. ${slot['price']}/hr - ${slot['bikesAllowed'] - slot['occupied']} Free",
                   onTap: () {
                     _onMarkerTapped(slot);
                   }
                 ),
                 onTap: () {
                   _onMarkerTapped(slot);
                 }
               ),
             );
          }
          
          // PRESERVE BIKE MARKER
          // PRESERVE BIKE MARKER - Robust check using ID
          try {
             final bikeMarker = _markers.firstWhere((m) => m.markerId.value == "user_bike");
             newMarkers.add(bikeMarker);
          } catch (e) {
             // Not found, that's okay
          }
          // REMOVED current_loc marker preservation as per user request to hide GPS location
          // Only Bike marker is preserved.

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

  void _onMarkerTapped(Map<String, dynamic> slot) {
      final LatLng pos = slot['latLng'];
      setState(() {
        _selectedParkingSlot = pos;
        _selectedSlotData = slot;
        _showReserveButton = true;
        _polylines = {}; 
        _circles = {
          Circle(
            circleId: CircleId("geofence_${slot['id']}"),
            center: pos,
            radius: 50, // Reduced to 50m as per request (was 500m)
            strokeWidth: 2,
            strokeColor: Colors.redAccent,
            fillColor: Colors.redAccent.withOpacity(0.15),
          ),
        }; 
      });
      // User requested NOT to move camera to slot? "dont take the marker after choocing the parkslot naviagtion happens to the bike location"
      // But maybe we should still show the slot initially?
      // If I don't animate, user might not verify the slot.
      // But let's respect "navigation happens to the bike location".
      // If I select a slot, maybe I shouldn't move camera if I already have a bike location?
      // Let's animate only if bike location is NOT set, or just stick to slot.
      // Actually, if user TAPS a marker, they usually want to see it.
      // But if they just want to select it for navigation...
      // I'll keep the camera animation for now as it's standard UX, unless explicitly forbidden.
      // User said: "mark the bike location in blue permanently dont take the marker after choocing the parkslot naviagtion happens to the bike location and park not gps location"
      // This implies: Don't lose the bike marker.
      // "Naviagtion happens to the bike location" -> origin is bike.
      // "And park not gps location" -> maybe destination? No, park at slot.
      
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(pos, 16),
      );
  }

  List<LatLng> _routePoints = [];
  Timer? _simulationTimer;

  /// ===============================
  /// DIRECTIONS API (Polyline)
  /// ===============================
  Future<void> _getDirections(LatLng dest) async {
    print("Getting directions to $dest...");
    // Prioritize Bike Location, then Current GPS
    final startPos = _bikeLocation ?? _currentLocation;
    
    if (startPos == null) {
       print("No start location available for directions.");
       return;
    }
    
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey, 
        request: PolylineRequest(
          origin: PointLatLng(startPos.latitude, startPos.longitude), 
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
              min(startPos.latitude, dest.latitude),
              min(startPos.longitude, dest.longitude),
            ),
            northeast: LatLng(
              max(startPos.latitude, dest.latitude),
              max(startPos.longitude, dest.longitude),
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
  /// ===============================
  /// PAYMENT & BOOKING
  /// ===============================
  Future<void> _makePayment(String price) async {
    // 1. Ask for Plate Number
    String? plateNumber = await _showPlateNumberDialog();
    if (plateNumber == null || plateNumber.isEmpty) return; // User cancelled

    // 2. Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 3. Attempt to update backend
    final result = await _updateSlotOccupancy(increment: true, plateNumber: plateNumber);
    final success = result['success'] == true;

    // 4. Close processing dialog
    Navigator.pop(context);

    if (success) {
      // Save Plate for Checkout
      setState(() {
        _currentPlateNumber = plateNumber;
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_plate_number', plateNumber);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Payment Successful"),
          content: Text("Rs. $price paid. Slot booked.\nPlate: $plateNumber\nOccupancy updated."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
       final errorMsg = result['error'] ?? "Unknown error";
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking Failed: $errorMsg"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<String?> _showPlateNumberDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Bike Plate Number"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g., AB-1234"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _updateSlotOccupancy({required bool increment, String? plateNumber}) async {
    // ... validation ...
    
    // (Keep lines 533-550 same, skipping validation boilerplate for brevity in replace if possible, but safer to include block)
    if (_selectedSlotData == null) return {'success': false, 'error': "No slot selected"};
    final slotIdsToCheck = [_selectedSlotData!['id'], _selectedSlotData!['slot_id']];
    String? slotId;
    for (var id in slotIdsToCheck) {
      if (id != null) {
        slotId = id.toString();
        break;
      }
    }
    if (slotId == null) return {'success': false, 'error': "No Slot ID found"};
    final url = Uri.parse("http://${appConfig.baseURL}:8004/parking_slots/$slotId");

    try {
      final getResponse = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (getResponse.statusCode != 200) return {'success': false, 'error': "Fetch failed"};
      
      final currentData = json.decode(getResponse.body);
      int currentOccupied = currentData['occupied'] ?? 0;
      int bikesAllowed = currentData['bikes_allowed'] ?? 0;
      List<dynamic> currentBookings = currentData['bookings'] ?? [];

      int newOccupied = increment ? currentOccupied + 1 : currentOccupied - 1;
      if (newOccupied < 0) newOccupied = 0;
      if (increment && newOccupied > bikesAllowed) {
         // Optionally block? But keeping soft limit for now
      }

      // HANDLE BOOKINGS LIST UPDATE
      if (increment) {
         // BOOKING -> Status: booked
         final userInfo = await TokenStorageFallback.getUserInfo();
         final username = userInfo['username'] ?? userInfo['email'] ?? "Unknown User";
         final String price = _selectedSlotData?['price']?.toString() ?? "0";
         
         final newBooking = {
           "username": username,
           "price": price,
           "plate_number": plateNumber ?? "Unknown",
           "date": DateTime.now().toIso8601String(),
           "arrival_time": null, // Will be set on Check-In Confirm
           "departure_time": null,
           "payment_status": "Paid",
           "payment_method": "Online",
           "status": "booked" // Initial Status
         };
         currentBookings.add(newBooking);
      } else {
         // STATUS UPDATE (Check-in Request / Check-out Request)
         String? plateToFind = _currentPlateNumber; 
         bool found = false;
         
         if (plateToFind != null) {
           for (int i = currentBookings.length - 1; i >= 0; i--) {
             if (currentBookings[i]['plate_number'] == plateToFind) {
               final currentStatus = currentBookings[i]['status'] ?? 'booked';
               
               // Logic: 
               // If booked -> Request Check In
               // If active -> Request Check Out
               
               if (currentStatus == 'booked' || currentStatus == 'check_in_requested') {
                   currentBookings[i]['status'] = 'check_in_requested';
                   // User is waiting for Agent to confirm Arrival
                   found = true;
               } else if (currentStatus == 'active' || currentStatus == 'check_out_requested') {
                   currentBookings[i]['status'] = 'check_out_requested';
                   // User is waiting for Agent to confirm Departure
                   found = true; 
               }
               break;
             }
           }
         }
      }

      final Map<String, dynamic> updatePayload = {
        "bookings": currentBookings
      };
      // Only update 'occupied' if it's a new booking (increment=true) 
      // OR if it was a completed checkout (handled by agent usually, but here we just send requests)
      if (increment) {
         updatePayload["occupied"] = newOccupied;
      }

      final token = await TokenStorageFallback.getToken();
      if (token == null) return {'success': false, 'error': "Authentication token not found"};

      final body = jsonEncode({
        "payload": updatePayload,
        "authorization": { "token": token }
      });


      final putResponse = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (putResponse.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': "Server: ${putResponse.body}"};
      }
    } catch (e) {
      return {'success': false, 'error': "Exception: $e"};
    }
  }

  /// ===============================
  /// CHECK-IN / CHECK-OUT
  /// ===============================
  Future<void> _handleCheckInOut() async {
    _simulationTimer?.cancel(); // Stop sim if checked out
    // If step 2, we are checking out
    if (_bookingStep == 2) {
      // GEOFENCING CHECK (1km)
      final checkPos = _bikeLocation ?? _currentLocation;
      if (checkPos != null && _selectedParkingSlot != null) {
         double dist = _calculateDistance(checkPos, _selectedParkingSlot!);
         if (dist > 0.05) { // 50m (was 0.5km)
           final fromSource = _bikeLocation != null ? "Bike" : "You";
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("$fromSource are too far! Please come closer to Check Out. (Distance: ${dist.toStringAsFixed(3)} km)"),
               backgroundColor: Colors.red,
             ),
           );
           return;
         }
      }

      
      // Send Request to Backend
      await _updateSlotOccupancy(increment: false); // Sets status to 'check_out_requested'
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Check-Out Requested. Please wait for Agent to confirm."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      // Do NOT reset UI here. Wait for polling to see 'completed' status.
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _currentLocation ?? _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Slots", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: GoogleMap(
              myLocationEnabled: false, // User requested to disable GPS UI
              myLocationButtonEnabled: false,
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
          
            if (_selectedSlotData != null) ...[
               (() {
                  final startPos = _bikeLocation ?? _currentLocation;
                  final hasLoc = startPos != null;
                  final distKm = hasLoc ? _calculateDistance(startPos, _selectedParkingSlot!) : 0.0;
                  final priceStr = _selectedSlotData?['price'] ?? "0";
                  final durationMin = hasLoc ? (distKm / 30 * 60).round() : 0; 
                  
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
                         "Available: ${(_selectedSlotData?['bikesAllowed'] ?? 0) - (_selectedSlotData?['occupied'] ?? 0)} / ${_selectedSlotData?['bikesAllowed'] ?? 0} Bikes",
                           style: TextStyle(fontSize: 16, color: Colors.indigo.shade700, fontWeight: FontWeight.w500),
                         ),
                         const SizedBox(height: 10),
                           Row(
                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                           children: [
                             Column(
                               children: [
                                 Icon(Icons.directions_bike, color: _bikeLocation != null ? Colors.blue : Colors.grey),
                                 Text(hasLoc ? "${distKm.toStringAsFixed(1)} km" : "..."),
                                 if (_bikeLocation != null) const Text("(from bike)", style: TextStyle(fontSize: 10, color: Colors.blue)),
                               ],
                             ),
                             Column(
                               children: [
                                 const Icon(Icons.timer, color: Colors.grey),
                                 Text(hasLoc ? "~$durationMin min" : "..."),
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                                onPressed: () async {
                                    // Prompt for Plate Number
                                    await _makePayment(priceStr);
                                    if (mounted) {
                                       setState(() {
                                         _bookingStep = 1; // Booked
                                         _hasStartedNavigation = false;
                                       });
                                       _startStatusPolling();
                                    }
                                }, 
                                child: const Text("Book Now", style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                          ] else if (_bookingStep == 1) ...[ 
                             SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: _hasStartedNavigation ? Colors.orange : Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                                onPressed: () async {
                                   if (!_hasStartedNavigation) {
                                      if (mounted) {
                                         setState(() {
                                           _hasStartedNavigation = true;
                                            _getDirections(_selectedParkingSlot!);
                                         });
                                      }
                                   } else {
                                      await _updateSlotOccupancy(increment: false); // Sends check_in_requested
                                      if (mounted) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check-in Requested. Wait for Agent.")));
                                      }
                                   }
                                }, 
                                child: _hasStartedNavigation 
                                   ? const Text("Request Check-In", style: TextStyle(fontSize: 18, color: Colors.white))
                                   : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.navigation, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("Start Travel", style: TextStyle(fontSize: 18, color: Colors.white)),
                                      ],
                                    ),
                              ),
                            ),
                          ] else if (_bookingStep == 2) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.green.shade100,
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text("Parked (Active).", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Spacer(),
                                    Text("Agent verified.", style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                               width: double.infinity,
                               child: ElevatedButton.icon(
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                                 onPressed: _handleCheckInOut,
                                 icon: const Icon(Icons.outbound, color: Colors.white),
                                 label: const Text("Check Out", style: TextStyle(fontSize: 18, color: Colors.white)),
                               ),
                             ),
                          ],
                      ],
                    ),
                  );
               }())
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
