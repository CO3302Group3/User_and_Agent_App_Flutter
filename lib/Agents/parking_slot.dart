class ParkingSlot {
  final String name;
  final String address;
  final String price;
  final String openingTime;
  final String closingTime;
  final List<String> availableDays;
  final int bikesAllowed;
  final int totalSpaces;

  ParkingSlot({
    required this.name,
    required this.address,
    required this.price,
    required this.openingTime,
    required this.closingTime,
    required this.availableDays,
    required this.bikesAllowed,
    required this.totalSpaces,
  });
}

