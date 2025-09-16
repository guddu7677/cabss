import 'package:flutter/material.dart';
import 'package:our_cabss/assistents/assistent_method.dart';
import 'package:our_cabss/services/auth_serviece.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  startTimer() {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        if (firebaseAuth.currentUser != null) {
          AssistentMethod.readCurrentOnlineUserInfo();
          Navigator.pushReplacementNamed(context, "/MainScreen");
        } else {
          Navigator.pushReplacementNamed(context, "/LoginScreen");
        }
      } catch (e) {
        print("Error in splash screen navigation: $e");
        Navigator.pushReplacementNamed(context, "/LoginScreen");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_taxi,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Our Cabss',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your Ride, Our Care',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}