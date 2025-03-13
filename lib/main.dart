import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:snowplow/firebase_options.dart';
import 'package:snowplow/widgets/customer/bottomNavigationBar.dart';
import 'package:snowplow/widgets/customer/homePage.dart';
import 'package:snowplow/widgets/customer/order_list.dart';
import 'package:snowplow/widgets/customer/login_page.dart';
import 'package:snowplow/widgets/customer/registration_page.dart';
import 'package:snowplow/widgets/customer/requestForm.dart';
import 'package:snowplow/widgets/serviceProviders/companyBottomNavifationBar.dart';
import 'package:snowplow/widgets/serviceProviders/loginScreen.dart';
import 'package:snowplow/widgets/serviceProviders/registrationScreen.dart';
import 'package:snowplow/widgets/serviceProviders/serviceHomePage.dart';
import 'package:snowplow/widgets/splashScreen.dart';
import 'package:snowplow/widgets/welcomeScreen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("handling Background Message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase first!

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/splashScreen",
      routes: {
        "/splashScreen": (context) => SplashScreen(),
        "/welcomeScreen": (context) => welcomeScreen(),
        "/register": (context) => userRegForm(),
        "/login": (context) => loginPage(),
        "/bottomNavigationBar": (context) => BottomNavigationBarWidget(),
        "/home": (context) => homePage(),
        "/orderList": (context) => orderList(),
        "/request": (context) => bidRequestForm(),
        "/companyRegForm": (context) => CompanyRegForm(),
        "/companyLogin": (context) => LoginScreen(),
        "/companyHomePage": (context) => ServiceProviderHome(),
        "/companyBottomNavigation": (context) => CompanyBottomNavigation()
      },

      // home:directPlaceOrder(),
    );
  }
}
