import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grinv/firebase_options.dart';
import './sign_in_page.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        duration: 3000,
        splash: Center(
          child: Transform.scale(
            scale: 1.2,
            child: Image.asset(
              'assets/logoV.png',
              color: Colors.green,
            ),
          ),
        ),
        nextScreen: SignInPage(),
        splashTransition: SplashTransition.fadeTransition,
        pageTransitionType: PageTransitionType.fade,
        backgroundColor: Colors.white,
      ),
    );
  }
}
