
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:snowplow/widgets/customer/login_page.dart';
import 'package:snowplow/widgets/serviceProviders/loginScreen.dart';

class welcomeScreen extends StatefulWidget {
  const welcomeScreen({super.key});

  @override
  State<welcomeScreen> createState() => _welcomeScreenState();
}

class _welcomeScreenState extends State<welcomeScreen> {
  // @override
  // void initState() {
  //
  //   super.initState();
  //
  //   Timer(Duration(seconds: 3),(){
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) =>loginPage()),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.teal[100],
      body: Stack(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Lottie.asset('assets/snowplow.json', fit: BoxFit.cover),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Snow Plow",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.white),
                ),
                SizedBox(height: 40),
                Center(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _builButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()));
                        },
                        icon: Icons.person,
                        text: "Become a Plower"),
                    SizedBox(width: 25),
                    _builButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => loginPage()));
                        },
                        icon: Icons.ac_unit,
                        text: "Request Plowing")
                  ],
                )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _builButton(
      {required VoidCallback onPressed,
      required IconData icon,
      required String text}) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: Size(160, 45),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 40),
            backgroundColor: Colors.white60,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.teal[200], size: 30),
            SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            )
          ],
        ));
  }
}
