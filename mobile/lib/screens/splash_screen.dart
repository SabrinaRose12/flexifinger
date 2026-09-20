import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    );

    controller.forward();

    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8E7DF2),
              Color(0xFF4CA1FF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(

          child: FadeTransition(
            opacity: animation,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Image.asset(
                  "assets/images/logowhite.png",
                  height: 150,
                ),

                SizedBox(height:20),

                //Text(
                //  "FlexiFinger",
                //  style: TextStyle(
                 //   fontSize: 32,
                   // fontWeight: FontWeight.bold,
                  //  color: Colors.white,
                 // ),
                //),

              ],
            ),
          ),

        ),
      ),
    );
  }
}