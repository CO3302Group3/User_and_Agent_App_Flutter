import 'package:computer_engineering_project/users/Loginscreen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart' as main;

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.2, // Reduced to 20% of screen
              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                "assets/images/spinlock.jpg",
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20.0,),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align "Name" to the left
                  mainAxisSize: MainAxisSize.min, // Avoid full height
                  children: [
                    const Text(
                      "User Name",
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
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your name",
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
            SizedBox(height: 15.0,),
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
            SizedBox(height: 15.0,),
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
                      child: TextField(
                        obscureText: true,

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

           const SizedBox(height: 20.0,),
            Center(
              child: SizedBox(
                width: 200, // Set your desired width here
                child: ElevatedButton(
                  onPressed: () async {
                    if (_usernameController.text.isEmpty ||
                        _emailController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final response = await createuser(
                        main.appConfig.baseURL,
                        _usernameController.text,
                        _passwordController.text,
                        _emailController.text,
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Loginscreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration failed: ${response.body}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
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
                    "Sign Up",

                    style: TextStyle(fontSize: 18,color: Colors.white),
                  ),

                ),

              ),
            ),


          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<http.Response> createuser(String baseURL, String username, String password , String email) {
    return http.post(
      Uri.parse('http://$baseURL/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'username': username, 'password': password , 'email':email}),
    );
  }




}




