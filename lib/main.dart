import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grinv/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grinv/sign_in_page.dart';
import 'package:grinv/open_bottom.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: stayApp(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen(); 
          } else {
            if (snapshot.hasError) {
              return ErrorScreen(); 
            } else {
              final bool isLoggedIn = snapshot.data ?? false;
              if (isLoggedIn) {
                return OpenButtom();
              } else {
                return const SignInPage();
              }
            }
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logoV.png',
          color: Colors.green,
          width: 100,
          height: 100, 
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Error occurred!'),
      ),
    );
  }
}

Future<bool> stayApp() async {
  SharedPrefService sharedPrefService = SharedPrefService();
  String? value = await sharedPrefService.readCache(key: "email");
  await Future.delayed(const Duration(seconds: 3));
  if (value != null) {
    print('read dulu Y');
    return true; 
  } else {
    print('read dulu G');
    return false;
  }
}
