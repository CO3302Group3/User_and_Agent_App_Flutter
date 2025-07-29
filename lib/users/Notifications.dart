import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/token_storage_fallback.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<String> notifications = [
    "Suspicious movement detected near your parked bike at 10:45 AM.",
    "Bike lock tampered at 11:30 AM.",
  ];

  @override
  void initState() {
    super.initState();
    _printFCMToken(); // Automatically save FCM token when screen loads
  }

  void _printFCMToken() async {
    try {
      // Check if Firebase is initialized before trying to get token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("Device FCM Token: $token");
        
        // Get user email from storage
        final userInfo = await TokenStorageFallback.getUserInfo();
        final userEmail = userInfo['email'];
        
        if (userEmail != null && userEmail.isNotEmpty) {
          // Save FCM token to Firestore
          await _saveFCMTokenToFirestore(token, userEmail);
        } else {
          print("User email not found. Cannot save FCM token to Firestore.");
        }
      } else {
        print("FCM token is null");
      }
    } catch (e) {
      print("Firebase not initialized or FCM not available: $e");
      print("Please initialize Firebase in main.dart to use FCM tokens");
    }
  }

  Future<void> _saveFCMTokenToFirestore(String token, String email) async {
    try {
      // Reference to the FCM_Tokens collection
      final CollectionReference fcmTokens = FirebaseFirestore.instance.collection('FCM_Tokens');
      
      // Create document data
      final tokenData = {
        'email': email,
        'fcm_token': token,
        'timestamp': FieldValue.serverTimestamp(),
        'device_id': token.substring(0, 20), // Using first 20 chars as device identifier
      };
      
      // Use email as document ID to avoid duplicates for same user
      await fcmTokens.doc(email).set(tokenData, SetOptions(merge: true));
      
      print("FCM token saved to Firestore for user: $email");
      
      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("FCM token saved successfully"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error saving FCM token to Firestore: $e");
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving FCM token: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showSavedTokens() async {
    try {
      final userInfo = await TokenStorageFallback.getUserInfo();
      final userEmail = userInfo['email'];
      
      if (userEmail == null || userEmail.isEmpty) {
        print("User email not found");
        return;
      }
      
      // Get the saved token from Firestore
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('FCM_Tokens')
          .doc(userEmail)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final savedToken = data['fcm_token'];
        final timestamp = data['timestamp'];
        
        print("Saved FCM token for $userEmail: $savedToken");
        print("Timestamp: $timestamp");
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Saved FCM Token"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: $userEmail"),
                  const SizedBox(height: 8),
                  Text("Token: ${savedToken?.substring(0, 50)}..."),
                  const SizedBox(height: 8),
                  Text("Saved: ${timestamp?.toDate() ?? 'Unknown'}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        print("No FCM token found for user: $userEmail");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No saved FCM token found")),
          );
        }
      }
    } catch (e) {
      print("Error retrieving FCM token: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error retrieving token: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notification",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.token, color: Colors.white),
            onPressed: _printFCMToken,
            tooltip: "Save FCM Token to Firestore",
          ),
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white),
            onPressed: _showSavedTokens,
            tooltip: "Show Saved FCM Token",
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == "delete_all") {
                setState(() {
                  notifications.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All notifications deleted")),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "delete_all",
                child: Text("Delete all notifications"),
              )
            ],
          )
        ],
      ),
      body: Container(
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
        child: notifications.isEmpty
            ? const Center(
          child: Text(
            "No notifications",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Anti-Theft Alert",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notifications[index],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == "delete_this") {
                        setState(() {
                          notifications.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Notification deleted")),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "delete_this",
                        child: Text("Delete this notification"),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
