import 'package:computer_engineering_project/Agents/Agentloginscreen.dart';
import 'package:computer_engineering_project/users/Signupscreen.dart';
import 'package:computer_engineering_project/users/bottomnavigationbar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_storage_fallback.dart';
import '../main.dart' as main;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize IP field with current appConfig baseURL
    _ipController.text = main.appConfig.baseURL;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3F51B5),
              Color(0xFFC5CAE9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
          children: [
            Container(


              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                "assets/images/spinlock.jpg",
                fit: BoxFit.cover,
              ),


            ),




            SizedBox(height: 10.0,),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align "Name" to the left
                  mainAxisSize: MainAxisSize.min, // Avoid full height
                  children: [
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8), // Space between text and container

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your email",
                          hintStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.0,),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align "Name" to the left
                  mainAxisSize: MainAxisSize.min, // Avoid full height
                  children: [
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8), // Space between text and container

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your password",
                          hintStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            SizedBox(height: 10.0,),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align "Name" to the left
                  mainAxisSize: MainAxisSize.min, // Avoid full height
                  children: [
                    const Text(
                      "IP address",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8), // Space between text and container

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your IP address",
                          hintStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 25.0,),
            Center(
              child: SizedBox(
                width: 200, // Set your desired width here
                child: ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    final ipAddress = _ipController.text.trim();
                    
                    // Update appConfig with user-provided IP first (before validation)
                    if (ipAddress.isNotEmpty && ipAddress != main.appConfig.baseURL) {
                      // Basic IP validation (accepts both IP addresses and hostnames)
                      if (_isValidIPOrHostname(ipAddress)) {
                        main.appConfig.updateBaseURL(ipAddress);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Server IP updated to: $ipAddress'),
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid IP address or hostname'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }
                    
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in email and password')),
                      );
                      return;
                    }

                    try {
                      final token = await loginuser(main.appConfig.baseURL, password, email);
                      if (token != null) {
                        // Save the token for future use
                        await TokenStorageFallback.saveToken(token);
                        
                        // Extract username from JWT
                        String? username;
                        try {
                          final parts = token.split('.');
                          if (parts.length == 3) {
                            final payload = parts[1];
                            final normalized = base64Url.normalize(payload);
                            final resp = utf8.decode(base64Url.decode(normalized));
                            final payloadMap = jsonDecode(resp);
                            username = payloadMap['username'];
                          }
                        } catch (e) {
                          print("Error decoding ID token: $e");
                        }

                        await TokenStorageFallback.saveUserInfo(
                          email: email, 
                          username: username ?? email // Fallback to email if no username
                        );
                        
                        print("Login successful: $token");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login successful!')),
                        );
                        
                        // Navigate to the next screen
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => Bottomnavigationbar())
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed. Please check your credentials.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    minimumSize: const Size.fromHeight(50), // Only height is fixed
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Log in",

                    style: TextStyle(fontSize: 18,color: Colors.white),
                  ),

                ),

              ),
            ),

            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[ Text(
                "Don't have an account?",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),

              ),
                SizedBox(width: 10.0),
                ElevatedButton(

                  onPressed: (){
                   Navigator.push(context, MaterialPageRoute(builder: (context)=> Signupscreen()));
                  },
                  child: Text(
                    "Sign up ",
                    style: TextStyle(color: Colors.indigo.shade600, fontWeight: FontWeight.bold),
                  ),

                )
              ]
            ),

            SizedBox(height: 60.0,),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[ Text(
                  "Continue as",
                  style: TextStyle(color: Colors.white70,fontWeight: FontWeight.bold, fontSize: 18),

                ),
                  SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: (){
                     Navigator.push(context, MaterialPageRoute(builder: (context)=> Agentloginscreen()));
                    },
                    child: Text(
                      "Agent",
                      style: TextStyle(color: Colors.indigo.shade600,fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ]
            ),


          ],

            ),
        ),
        ),

      ),
    );
  }
  Future<String?> loginuser(String baseURL, String password, String email) async {
    try {
      final String basicauth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));

      final response = await http.post(
        Uri.parse('http://$baseURL/auth/login'),
        headers: <String, String>{
          'authorization': basicauth,
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login response: $data');
        return data['data']['access_token'];
      } else {
        print("Login failed: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  // Simple validation for IP address or hostname
  bool _isValidIPOrHostname(String input) {
    if (input.isEmpty) return false;
    
    // Check if it's a valid IP address (basic regex)
    RegExp ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipRegex.hasMatch(input)) {
      // Validate IP octets are between 0-255
      List<String> parts = input.split('.');
      for (String part in parts) {
        int? num = int.tryParse(part);
        if (num == null || num < 0 || num > 255) {
          return false;
        }
      }
      return true;
    }
    
    // Check if it's a valid hostname (basic validation)
    RegExp hostnameRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$');
    return hostnameRegex.hasMatch(input) || input == 'localhost';
  }
}

