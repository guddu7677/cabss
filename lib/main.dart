import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:our_cabss/infoHandler/app_info.dart';
import 'package:our_cabss/screens/forget_password.dart';
import 'package:our_cabss/screens/login_screen.dart';
import 'package:our_cabss/screens/main_screen.dart';
import 'package:our_cabss/screens/register_screen.dart';
import 'package:our_cabss/screens/search_places_screen.dart';
import 'package:our_cabss/splash_screen/splash_screen.dart';
import 'package:our_cabss/theme_provider/theme_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAGsIg4cXLbdOpeB9HNIi5spdyi9LBYz5c",
      appId: "1:372274440315:android:e7661a3dfb02fe5ef6dade",
      messagingSenderId: "372274440315",
      projectId: "cabbss-e6079",
      // databaseURL: "https://cabbss-e6079-default-rtdb.firebaseio.com",
    ),
  );
  runApp(const OurCabss());
}

class OurCabss extends StatelessWidget {
  const OurCabss({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (context) => AppInfo(),
    child: MaterialApp(
      title: "Our Cabss",
      theme: Mythemes.lightTheme,
      darkTheme: Mythemes.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: SearchPlacesScreen(),
      routes: {
        "/RegisterScreen": (context) => RegisterScreen(),
        "/LoginScreen": (context) => LoginScreen(),
        "/MainScreen": (context) => MainScreen(),
        "/SplashScreen": (context) => SplashScreen(),
        "/ForgetPasswordScreen": (context) => ForgetPasswordScreen(),
                "/SearchPlacesScreen": (context) => SearchPlacesScreen(),

      },
    ),
    );
  }
}
