import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/token_storage_fallback.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // ... existing password controllers ...
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  File? _profileImage;
  final picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userInfo = await TokenStorageFallback.getUserInfo();
    setState(() {
      _usernameController.text = userInfo['username'] ?? '';
      _emailController.text = userInfo['email'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.indigo.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
      ),
      labelStyle:
      TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
       final token = await TokenStorageFallback.getToken();
       if (token == null) return;
       
       final url = Uri.parse("http://${appConfig.baseURL}:8003/user/update");
       
       final Map<String, dynamic> payload = {
         "username": _usernameController.text.trim(),
         "email": _emailController.text.trim(),
       };
       
       // Handle Password Change if fields are entered
       if (_newPasswordController.text.isNotEmpty) {
          if (_newPasswordController.text != _confirmPasswordController.text) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("New and Confirm Password do not match."), backgroundColor: Colors.red),
             );
             setState(() => _isLoading = false);
             return;
          }
          payload["password"] = _newPasswordController.text.trim();
       }
       
       final response = await http.put(
         url,
         headers: {
           "Content-Type": "application/json",
           "Authorization": "Bearer $token",
         },
         body: jsonEncode(payload),
       );
       
       if (response.statusCode == 200) {
          // Update local storage
          await TokenStorageFallback.saveToken(token);
          await TokenStorageFallback.saveUserInfo(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
          );

          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Saved"),
                content: const Text("Account details updated successfully."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  )
                ],
              ),
            );
            
            // Clear passwords
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          }
       } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Update Failed: ${response.body}"), backgroundColor: Colors.red),
             );
          }
       }
    } catch (e) {
       print("Error updating profile: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
         );
       }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changePassword() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all password fields.")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New and Confirm Password do not match."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password changed successfully."),
        backgroundColor: Colors.green,
      ),
    );

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _resetPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password reset link sent to your email."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        width: double.infinity,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 115,
                width: 115,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage("assets/images/Profile.png")
                      as ImageProvider,
                    ),
                    Positioned(
                      right: -10,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF5F6F9),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _usernameController,
                decoration: _customInputDecoration("Username", Icons.person),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: _customInputDecoration("Email", Icons.email),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 1),
              const SizedBox(height: 10),
              const Text(
                "Change Password",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _currentPasswordController,
                decoration:
                _customInputDecoration("Current Password", Icons.lock_outline),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newPasswordController,
                decoration:
                _customInputDecoration("New Password", Icons.lock_reset),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                _customInputDecoration("Confirm Password", Icons.lock),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_open),
                      label: const Text("Change Password"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text("Save All Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
