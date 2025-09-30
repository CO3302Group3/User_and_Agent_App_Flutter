import 'package:flutter/material.dart';

class Receivepayment extends StatelessWidget {
  final List<Map<String, dynamic>> paymentData = [
    {
      'name': 'Vithurshana',
      'amount': '₹500',
      'method': 'Card',
      'date': '5th July 2025',
    },

  ];

  Color getMethodColor(String method) {
    if (method.toLowerCase() == 'card') {
      return Colors.blueAccent;
    } else if (method.toLowerCase() == 'cash') {
      return Colors.orangeAccent;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Payments', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5),
              Color(0xFFC5CAE9),
              Color(0xFFE8EAF6),],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          itemCount: paymentData.length,
          itemBuilder: (context, index) {
            final item = paymentData[index];
            final methodColor = getMethodColor(item['method']);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),

                  // Payment details text column
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        children: [
                          TextSpan(
                            text: item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: " paid "),
                          TextSpan(
                            text: item['amount'],
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: " via"),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: methodColor,

                              ),
                            ),
                          ),
                          TextSpan(
                            text: item['method'],
                            style: TextStyle(
                              color: methodColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: " on "),
                          TextSpan(
                            text: item['date'],
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
