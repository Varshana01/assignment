import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'login.dart';
import 'OfflineLibraryPage.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final List<Map<String, dynamic>> offlineLyrics;

  const SplashScreen({
    Key? key,
    required this.isLoggedIn,
    required this.offlineLyrics,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
Future<List<Map<String, dynamic>>> loadOfflineLyrics() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith('lyrics_'));

  List<Map<String, dynamic>> lyricsList = [];

  for (var key in keys) {
    final title = key.replaceFirst('lyrics_', '');
    final lyrics = prefs.getString(key) ?? '';
    final path = prefs.getString('audio_$title') ?? '';
    lyricsList.add({'title': title, 'lyrics': lyrics, 'localPath': path});
  }

  return lyricsList;
}
class _SplashScreenState extends State<SplashScreen> {
  late List<Map<String, dynamic>> offlineLyrics;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    final keys = prefs.getKeys().where((k) => k.startsWith('lyrics_'));
    offlineLyrics = [];

    for (var key in keys) {
      final title = key.replaceFirst('lyrics_', '');
      final lyrics = prefs.getString(key) ?? '';
      final path = prefs.getString('audio_$title') ?? '';
      offlineLyrics.add({'title': title, 'lyrics': lyrics, 'localPath': path});
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => isLoggedIn
          ? HomePage(offlineLyrics: offlineLyrics)
          : const LoginPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8), // same as native splash bg
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Emosik.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 10),
            const CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }
}
