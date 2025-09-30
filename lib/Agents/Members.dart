import 'package:flutter/material.dart';

class Members extends StatefulWidget {
  const Members({super.key});

  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  final List<Map<String, String>> members = [
    {
      'name': 'Vithurshana',
      'plate': 'AB-1234',
      'arrival': '09:15 AM',
      'payment': 'Card',
    },

  ];

  Color _getPaymentColor(String method) {
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
        title: const Text('Members', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF3F51B5),
        centerTitle: true,
        elevation: 6,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5),
              Color(0xFFC5CAE9),
              Color(0xFFE8EAF6), ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: ListView.separated(
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final member = members[index];
            final paymentColor = _getPaymentColor(member['payment'] ?? '');

            return Material(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(22),
              elevation: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  // You can add member detail view or actions here
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  child: Row(
                    children: [
                      // Profile Circle with initials
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.indigo.shade400,
                        child: Text(
                          _getInitials(member['name'] ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Member Info Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF283593),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _infoRow(Icons.directions_car, 'Plate', member['plate'] ?? '-'),
                            const SizedBox(height: 4),
                            _infoRow(Icons.access_time, 'Arrival', member['arrival'] ?? '-'),
                          ],
                        ),
                      ),

                      // Payment Badge
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payment, size: 18, color: paymentColor),
                            const SizedBox(width: 6),
                            Text(
                              member['payment'] ?? '-',
                              style: TextStyle(
                                color: paymentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    String initials = '';
    for (var part in parts) {
      if (part.isNotEmpty) initials += part[0];
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
