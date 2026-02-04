import 'package:computer_engineering_project/services/auth_service.dart';
import 'package:computer_engineering_project/services/token_storage_fallback.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:computer_engineering_project/main.dart' as main;

class ReportComplaintScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData; // e.g., {'subject': 'Bike Issue: BIKE123'}

  const ReportComplaintScreen({Key? key, this.prefillData}) : super(key: key);

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillData != null) {
      if (widget.prefillData!['subject'] != null) {
        _subjectController.text = widget.prefillData!['subject'];
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await TokenStorageFallback.getToken();
      
      final response = await http.post(
        Uri.parse('http://${main.appConfig.baseURL}/auth/complaints'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "complaint": {
             "subject": _subjectController.text.trim(),
             "description": _descriptionController.text.trim(),
          },
          // Based on the user's backend pattern, they often pass token in body
          // But my snippet suggests: { "subject": "...", "description": "..." } AND token in Query or Body?
          // Let's stick to the structure compatible with the snippet I generated.
          // The snippet expects: create_complaint(complaint: ComplaintCreate, token_request: TokenRequest)
          // FastAPI handles body composition. IF they are separate body params, it might be tricky.
          // BUT, if I look at `list_non_staff_users(token_request: TokenRequest, ...)`
          // It seems they pass JUST TokenRequest in body.
          // In my snippet: `create_complaint(complaint: ComplaintCreate, token_request: TokenRequest)`
          // This implies the body should be: { "complaint": {...}, "token_request": {...} } OR composite.
          // Wait, FastAPI with multiple Pydantic models in body expects:
          // { "complaint": { "subject": "...", ... }, "token_request": { "token": "..." } }
          
          "complaint": {
            "subject": _subjectController.text.trim(),
            "description": _descriptionController.text.trim(),
          },
          "token_request": {
            "token": token ?? ""
          }
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to submit complaint: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Complaint"),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        height: double.infinity,
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject",
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a subject' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitComplaint,
                     style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit Complaint",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
