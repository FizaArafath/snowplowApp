import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:snowplow/widgets/welcomeScreen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {

    super.initState();

    Timer(Duration(seconds: 3),(){
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>welcomeScreen()),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.teal[100],
      body: Stack(
          children: [
            SizedBox(
              width: screenWidth,
          height: screenHeight,
          child: Lottie.asset(
            'assets/snowplow.json',
            fit: BoxFit.cover
          ),
            ),
            Center(
              child: Padding(
                     padding: const EdgeInsets.all(28.0),
                     child: Text(
                       "Snow Plow",
                       style: GoogleFonts.poppins(
                           fontWeight: FontWeight.bold,
                           fontSize: 30,
                           color: Colors.white
                       ),
                     ),
                   ),
            ),

        ],
        ),

      );

  }
}