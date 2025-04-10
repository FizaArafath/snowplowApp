import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/widgets/customer/homePage.dart';
import 'package:snowplow/widgets/customer/order_list.dart';
import 'package:snowplow/widgets/customer/profileScreen.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  State<BottomNavigationBarWidget> createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends State<BottomNavigationBarWidget> {
  int _selectIndex = 0;
  String? userId;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
    // setupFirebaseMessaging();
  }

  // void setupFirebaseMessaging() async {
  //   // Request notification permission
  //   NotificationSettings settings = await messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //
  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     print("✅ User granted permission for notifications.");
  //   } else {
  //     print("❌ User denied notification permission.");
  //     return;
  //   }
  //
  //   // Get FCM Token with error handling
  //   try {
  //     String? token = await messaging.getToken();
  //     if (token != null) {
  //       print("✅ FCM Token: $token");
  //     } else {
  //       print("❌ Failed to get FCM token.");
  //     }
  //   } catch (e) {
  //     print("❌ Error retrieving FCM token: $e");
  //   }
  //
  //   // Listen for foreground messages
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print(
  //         "📩 Foreground notification received: ${message.notification?.title}");
  //   });
  //
  //   // Handle background notification click
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print("📩 Background notification clicked: ${message.data}");
  //   });
  // }

  Future<void> _loadCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString("userId");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      homePage(),
      OrderList(),
      userId != null
          ? profileScreen(userId: userId!)
          : const Center(child: CircularProgressIndicator())
    ];

    return Scaffold(
      body: pages[_selectIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
