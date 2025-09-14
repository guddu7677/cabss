import 'package:flutter/material.dart';
import 'package:our_cabss/assistents/assistent_method.dart';
import 'package:our_cabss/services/auth_serviece.dart';
import 'package:our_cabss/services/auth_serviece.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
 
  startTimer() {
    Future.delayed(const Duration(seconds: 3), ()async {
      if(await firebaseAuth.currentUser != null){
        firebaseAuth.currentUser != null?AssistentMethod.readCurrentOnlineUserInfo():null;
        Navigator.pushReplacementNamed(context, "/MainScreen");
      }
      else{
        Navigator.pushReplacementNamed(context, "/LoginScreen");
      }
      
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Splash Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}