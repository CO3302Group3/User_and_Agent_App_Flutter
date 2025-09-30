import 'package:flutter/material.dart';

class Usersparkinghistory extends StatelessWidget {
  final List<Map<String, dynamic>> historyData = [
    {
      'name': 'Gita Saha',
      'date': '2025-01-15',
      'duration': '2 hrs',
      'price': 'LKR 50',
      'payment': 'Card',
    },
    {
      'name': 'Kiran Sah',
      'date': '2025-02-25',
      'duration': '1 hr',
      'price': 'LKR 30',
      'payment': 'Cash',
    },

  ];

  // Get base color for payment method
  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Colors.blueAccent;
      case 'cash':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Parking History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3F51B5),
        centerTitle: true,
        elevation: 8,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF283593), Color(0xFF7986CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ListView.builder(
          itemCount: historyData.length,
          itemBuilder: (context, index) {
            final item = historyData[index];
            final paymentMethod = item['payment'] ?? 'Unknown';
            final paymentColor = _paymentColor(paymentMethod);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: paymentColor.withOpacity(0.8), width: 2),
              ),
              elevation: 7,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white,  // <-- White background here
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {

                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: paymentColor.darken(0.4),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _infoRow(Icons.date_range, "Date Parked", item['date'], paymentColor),
                      const SizedBox(height: 10),
                      _infoRow(Icons.timelapse, "Duration", item['duration'], paymentColor),
                      const SizedBox(height: 10),
                      _infoRow(Icons.currency_rupee, "Price", item['price'], paymentColor),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(Icons.payment, color: paymentColor.darken(0.3), size: 22),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: paymentColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: paymentColor.withOpacity(0.6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Text(
                              paymentMethod.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.topRight,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: paymentColor.darken(0.3)),
                          onSelected: (value) {
                            if (value == 'delete') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Deleted ${item['name']}'s record")),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.darken(0.3), size: 22),
        const SizedBox(width: 10),
        Text(
          "$label:",
          style: TextStyle(
            color: color.darken(0.4),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color.darken(0.6),
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Extension method to darken a color by [amount]
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
