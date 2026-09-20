import 'package:flutter/material.dart';
import 'patient_login.dart';
import 'therapist_login.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int currentPage = 0;
  String selectedRole = "Patient";

  List<String> titles = [
    "Welcome to FlexiFinger",
    "Remote Personalized Program",
    "More Than Just Exercises",
    "Evidence-based System"
  ];

  List<String> descriptions = [
    "Your personalized solution for finger exercises, management, and monitoring, available whenever and wherever you need it.",
    "Once your healthcare professional prescribes FlexiFinger, they can remotely adapt, monitor, and motivate you through a program tailored to your needs.",
    "Access a comprehensive library of exercises to prevent and improve finger conditions. Share tips, progress, and support with the FlexiFinger community.",
    "Created and validated by medical professionals based on the latest scientific evidence and successful clinical trials for optimal results."
  ];

  List<String> images = [
    "assets/images/display1.png",
    "assets/images/display2.png",
    "assets/images/display3.png",
    "assets/images/display4.png",
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final topPadding = MediaQuery.of(context).viewPadding.top;

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
        child: SafeArea(
          child: PageView.builder(
            controller: controller,
            itemCount: 4,
            onPageChanged: (index){
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context,index){
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image - lebih kecil
                    Image.asset(
                      images[index],
                      height: screenHeight * 0.28, // 28% dari tinggi screen
                      width: screenWidth * 0.6,
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Title
                    Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.055, // 5.5% dari width
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1032),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.015),

                    // Description
                    Text(
                      descriptions[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04, // 4% dari width
                        color: Color(0xFFFFFFFF),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    if(index == 3) roleSelector(),

                    SizedBox(height: screenHeight * 0.02),

                    nextButton(index),

                    // Extra space untuk phone dengan gesture navigation
                    SizedBox(height: bottomPadding > 0 ? 5 : 10),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget roleSelector(){
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Login as..",
          style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleOption("Patient"),
              _buildRoleOption("Therapist"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildRoleOption(String role) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: (){
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.07, // 7% dari width
            vertical: 8
        ),
        decoration: BoxDecoration(
          color: selectedRole == role
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  Widget nextButton(index){
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.018
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: Size(screenWidth * 0.4, 40),
      ),
      onPressed: (){
        if(index < 3){
          controller.nextPage(
            duration: Duration(milliseconds:300),
            curve: Curves.easeIn,
          );
        }
        else{
          if(selectedRole=="Patient"){
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 950),
                pageBuilder: (_, animation, __) => const PatientLogin(),
                transitionsBuilder: (_, animation, __, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  );
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.10),
                    end: Offset.zero,
                  ).animate(curved);
                  final fade = Tween<double>(
                    begin: 0,
                    end: 1,
                  ).animate(curved);
                  final scale = Tween<double>(
                    begin: 0.97,
                    end: 1,
                  ).animate(curved);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(
                        scale: scale,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            );
          }
          else{
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context)=>TherapistLogin(),
              ),
            );
          }
        }
      },
      child: Text(
        index==3 ? "Continue" : "Next",
        style: TextStyle(
          fontSize: screenWidth * 0.04,
        ),
      ),
    );
  }
}