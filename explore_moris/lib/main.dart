
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Screens
import 'firebase_options.dart';
import 'Signup.dart';
import 'SignIn.dart';
import 'HomeScreen.dart'; // your home screen file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExploreMoris',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      // Start with Splash
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait 2 seconds then check auth state
    Timer(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User already logged in → go to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Not logged in → go to sign in
        Navigator.pushReplacementNamed(context, '/signin');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF007B7B), // teal background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            // Title text
            const Text(
              "EXPLOREMORIS",
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
