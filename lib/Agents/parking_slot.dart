class ParkingSlot {
  final String? id; // Added ID field for backend synchronization
  final String name;
  final String address;
  final String price;
  final String openingTime;
  final String closingTime;
  final List<String> availableDays;
  final int bikesAllowed;
  final int totalSpaces;
  final String? assignedDeviceId;
  final String status; // Added status field

  final int occupied;
  final List<dynamic> bookings;
  final List<dynamic> members; // Added members field

  ParkingSlot({
    this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.openingTime,
    required this.closingTime,
    required this.availableDays,
    required this.bikesAllowed,
    required this.totalSpaces,
    this.assignedDeviceId,
    this.status = 'pending',
    this.occupied = 0,
    this.bookings = const [], 
    this.members = const [], // Default to empty
  });
}

