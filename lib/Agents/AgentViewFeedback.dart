import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/token_storage_fallback.dart';
import 'package:intl/intl.dart';

class AgentViewFeedback extends StatefulWidget {
  const AgentViewFeedback({super.key});

  @override
  State<AgentViewFeedback> createState() => _AgentViewFeedbackState();
}

class _AgentViewFeedbackState extends State<AgentViewFeedback> {
  List<dynamic> _feedbacks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    try {
      final token = await TokenStorageFallback.getToken();
      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final url = Uri.parse("http://${appConfig.baseURL}/auth/admin/feedbacks");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({"token": token}), 
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> feedbacksData = [];

        if (decoded is List) {
          feedbacksData = decoded;
        } else if (decoded is Map<String, dynamic>) {
            // Handle Gateway wrapper usually {"data": [...]} or similar
            if (decoded.containsKey('data') && decoded['data'] is List) {
               feedbacksData = decoded['data'];
            } else if (decoded.containsKey('data') && decoded['data'] is Map && decoded['data']['feedbacks'] is List) {
               // Fallback for previous structure just in case
               feedbacksData = decoded['data']['feedbacks'];
            } else {
               // If it's a map but structure is unknown, try to find a list or just ignore
               print("Unexpected JSON structure: $decoded");
            }
        }

        setState(() {
          _feedbacks = feedbacksData;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load feedbacks: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildStarDisplay(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Feedbacks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : _feedbacks.isEmpty
                  ? const Center(child: Text("No feedback available."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _feedbacks.length,
                      itemBuilder: (context, index) {
                        final feedback = _feedbacks[index];
                        final dateStr = feedback['created_at'] ?? '';
                        String formattedDate = dateStr;
                        try {
                           final date = DateTime.parse(dateStr);
                           formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
                        } catch (_) {}

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      feedback['username'] ?? 'Anonymous',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildStarDisplay(feedback['rating'] ?? 0),
                                const SizedBox(height: 12),
                                Text(
                                  feedback['comment'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
