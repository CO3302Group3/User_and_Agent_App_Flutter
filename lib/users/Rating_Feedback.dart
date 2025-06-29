import 'package:flutter/material.dart';

class RatingFeedback extends StatefulWidget {
  const RatingFeedback({super.key});

  @override
  State<RatingFeedback> createState() => _RatingFeedbackState();
}

class _RatingFeedbackState extends State<RatingFeedback> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitFeedback() {
    String message = _rating == 0
        ? "Please select a rating."
        : "Thank you for rating us $_rating stars!\nFeedback: ${_feedbackController.text.trim()}";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Feedback Submitted"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rating = 0;
                _feedbackController.clear();
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.yellow.shade700,
        size: 36,
      ),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rating & Feedback",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Text(
              "How would you rate your experience?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Write your feedback:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: "Describe your experience......",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20,width: 20,),

            Padding(
              padding: const EdgeInsets.only(top: 10, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text("Save & Continue"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
