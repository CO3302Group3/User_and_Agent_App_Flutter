import 'package:flutter/material.dart';
import 'package:computer_engineering_project/users/bikestatus.dart';
import 'package:computer_engineering_project/users/home.dart';
import 'package:computer_engineering_project/users/profile.dart';
import 'package:computer_engineering_project/users/Notifications.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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
  int currentTabIndex = 0;

  bool _chatOpen = false;
  double chatTop = 100;
  double chatLeft = 100;

  @override
  void initState() {
    homepage = Home();
    bikestatus = Bikestatus();
    notification = Notifications();
    profile = Profile();
    pages = [homepage, bikestatus, notification, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          pages[currentTabIndex],

          // Floating Chat Window Overlay
          if (_chatOpen)
            Positioned(
              top: chatTop,
              left: chatLeft,
              child: Draggable(
                feedback: chatWindow(),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    chatLeft = details.offset.dx;
                    chatTop = details.offset.dy -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight;
                  });
                },
                child: chatWindow(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.indigo.shade800,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white, size: 30.0),
          Icon(Icons.motorcycle_outlined, color: Colors.white, size: 30.0),
          Icon(Icons.notifications, color: Colors.white, size: 30.0),
          Icon(Icons.person_outline, color: Colors.white, size: 30.0),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF3F51B5),
        onPressed: () {
          setState(() {
            _chatOpen = !_chatOpen;
          });
        },
        child: Icon(_chatOpen ? Icons.close : Icons.chat),
      ),
    );
  }

  Widget chatWindow() {
    return Container(
      width: 250,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Chat',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _chatOpen = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(child: Text('Chat content goes here')),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
