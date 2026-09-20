import 'package:flutter/material.dart';
import 'package:mobile/models/patient.dart';
import 'package:mobile/screens/homepage_patient.dart';
import 'package:mobile/screens/patient_login.dart';
import 'package:mobile/screens/therapist_login.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ApiService (load token from storage)
  await ApiService.init();
  runApp(FlexiFingerApp());
}

class FlexiFingerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FlexiFinger",
      home: SplashScreen(),
    );

  }

}