import 'package:computer_engineering_project/users/Accountsetting.dart';
import 'package:computer_engineering_project/users/Appupdatescreen.dart';
import 'package:computer_engineering_project/users/Loginscreen.dart';
import 'package:computer_engineering_project/users/Rating_Feedback.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isNotificationOn = true;
  int rating =0;
  final TextEditingController feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: Container(
        width: double.infinity,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            SizedBox(
              height: 115,
              width: 115,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage("assets/images/Profile.png"),
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
                        onPressed: () {
                          // Add your image upload logic here
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(

                  padding: const EdgeInsets.symmetric( vertical: 20),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> AccountSettingsPage()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                     SizedBox(width: 20,),
                    Icon(Icons.person_outline,
                        size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "Account",
                      style: TextStyle(color: Colors.white,fontSize: 16),
                    ),
                    SizedBox(width: 170,),

                    Icon(Icons.chevron_right, size: 22, color: Colors.white,)
                  ],
                ),
              ),
            ),

            SizedBox(height: 10,),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(

                  padding: const EdgeInsets.symmetric( vertical: 10),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  setState(() {
                    isNotificationOn = !isNotificationOn;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20,),
                    Icon(Icons.notifications,
                        size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "Notifications",
                      style: TextStyle(color: Colors.white,fontSize: 16),
                    ),
                    SizedBox(width: 110,), // Pushes the switch to the far right
                    Switch(
                      value: isNotificationOn,
                      onChanged: (bool value) {
                        setState(() {
                          isNotificationOn = value;
                        });
                      },
                      activeColor: Colors.white,
                      inactiveThumbColor: Colors.grey[300],
                      inactiveTrackColor: Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(

                  padding: const EdgeInsets.symmetric( vertical: 20),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> RatingFeedback()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20,),
                    Icon(Icons.feedback_outlined,
                        size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "Rating & Feedback ",
                      style: TextStyle(color: Colors.white,fontSize: 16),
                    ),
                    SizedBox(width: 90,),

                    Icon(Icons.chevron_right, size: 22, color: Colors.white,)
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppUpdateScreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20),
                    Icon(Icons.privacy_tip, size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "Terms & Conditions ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 80),
                    Icon(Icons.chevron_right, size: 22, color: Colors.white),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AppUpdateScreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20),
                    Icon(Icons.system_update_alt_outlined, size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "App Updates & Notices",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 60),
                    Icon(Icons.chevron_right, size: 22, color: Colors.white),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10,),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextButton(
                style: TextButton.styleFrom(

                  padding: const EdgeInsets.symmetric( vertical: 20),
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder:(context)=> Loginscreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20,),
                    Icon(Icons.logout,
                        size: 22, color: Colors.white),
                    SizedBox(width: 30),
                    Text(
                      "Log Out",
                      style: TextStyle(color: Colors.white,fontSize: 16),
                    ),
                    SizedBox(width: 170,),

                    Icon(Icons.chevron_right, size: 22, color: Colors.white,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
