import 'package:computer_engineering_project/Agents/Agentloginscreen.dart';
import 'package:computer_engineering_project/users/Signupscreen.dart';
import 'package:computer_engineering_project/users/bottomnavigationbar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            Container(


              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                "assets/images/spinlock.jpg",
                fit: BoxFit.cover,
              ),


            ),
            SizedBox(height: 30.0,),

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

            const SizedBox(height: 25.0,),
            Center(
              child: SizedBox(
                width: 200, // Set your desired width here
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> Bottomnavigationbar()));
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
    );
  }




}

