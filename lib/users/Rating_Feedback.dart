import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/token_storage_fallback.dart';

class RatingFeedback extends StatefulWidget {
  const RatingFeedback({super.key});

  @override
  State<RatingFeedback> createState() => _RatingFeedbackState();
}

class _RatingFeedbackState extends State<RatingFeedback> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;

  void _submitFeedback() async {
    if (_rating == 0) {
       showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Rating Required"),
          content: const Text("Please select a rating."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await TokenStorageFallback.getToken();
      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final url = Uri.parse("http://${appConfig.baseURL}:8003/auth/feedback");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "rating": _rating,
          "comment": _feedbackController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Feedback Submitted"),
            content: Text("Thank you for rating us $_rating stars!"),
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
      } else {
        throw Exception("Failed to submit feedback: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
        child: SingleChildScrollView(
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
                      onPressed: _isLoading ? null : _submitFeedback,
                      icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? "Sending..." : "Save & Continue"),
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
      ),
    );
  }
}
