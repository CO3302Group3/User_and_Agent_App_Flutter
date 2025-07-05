import 'package:computer_engineering_project/Agents/AgentDashboard.dart';
import 'package:computer_engineering_project/Agents/Agentnotifications.dart';
import 'package:computer_engineering_project/Agents/Agentprofile.dart';
import 'package:computer_engineering_project/Agents/Manageparkingslot.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';


class Agentbottomnavigationbar extends StatefulWidget {
  const Agentbottomnavigationbar({super.key});

  @override
  State<Agentbottomnavigationbar> createState() => _AgentbottomnavigationbarState();
}

class _AgentbottomnavigationbarState extends State<Agentbottomnavigationbar> {
  late List<Widget> pages;
  late Agentdashboard dashboard;
  late Manageparkingslot parkingslot;
  late Agentnotifications notification;
  late Agentprofile profile;
  int currentTabIndex = 0;

  bool _chatOpen = false;
  double chatTop = 100;
  double chatLeft = 100;

  @override
  void initState() {
    dashboard= Agentdashboard();
    parkingslot= Manageparkingslot();
    notification = Agentnotifications();
    profile = Agentprofile();
    pages = [dashboard, parkingslot, notification, profile];
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
          Icon(Icons.dashboard, color: Colors.white, size: 30.0),
          Icon(Icons.local_parking, color: Colors.white, size: 30.0),
          Icon(Icons.notifications, color: Colors.white, size: 30.0),
          Icon(Icons.person_outline, color: Colors.white, size: 30.0),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 30,
        height: 30,
        child: FloatingActionButton(

          onPressed: () {
            setState(() {
              _chatOpen = !_chatOpen;
            });
          },
          child: Icon(_chatOpen ? Icons.close : Icons.chat, color: Colors.white, size: 18, ),
          backgroundColor: Colors.indigo.shade400,
        ),

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
