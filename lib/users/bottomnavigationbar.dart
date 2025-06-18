import 'package:flutter/material.dart';
import 'package:computer_engineering_project/users/bikestatus.dart';
import 'package:computer_engineering_project/users/home.dart';
import 'package:computer_engineering_project/users/profile.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:computer_engineering_project/users/Notifications.dart';



class Bottomnavigationbar extends StatefulWidget {
  const Bottomnavigationbar({super.key});

  @override
  State<Bottomnavigationbar> createState() => _BottomnavigationbarState();
}

class _BottomnavigationbarState extends State<Bottomnavigationbar> {
  late List<Widget> pages;
  late Home homepage;
  late Bikestatus bikestatus;
  late Notifications notification;
  late Profile profile;
  int currentTabIndex=0;
  @override

  void initState(){
    homepage = Home();
    bikestatus = Bikestatus();
    notification=Notifications();
    profile = Profile();
    pages = [homepage, Bikestatus(),Notifications(), profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.indigo.shade800,
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index){
          setState(() {
            currentTabIndex=index;
          });

        },
        items: [
          Icon(Icons.home_outlined, color: Colors.white, size: 30.0,),
          Icon(Icons.motorcycle_outlined, color: Colors.white,size: 30.0),
          Icon(Icons.notifications, color: Colors.white, size: 30.0,),
          Icon(Icons.person_outline, color: Colors.white,size: 30.0),

        ],
      ),
      body: pages[ currentTabIndex],


    );
  }
}
