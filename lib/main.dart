import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'OfflineLibraryPage.dart';
import 'face_detection_page.dart';
import 'firebase_options.dart';
import 'splash.dart';
import 'home.dart';
import 'login.dart';
import 'register.dart';
import 'profile.dart';
import 'emoDec.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform.copyWith(
      databaseURL: 'https://emo-sik-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final offlineLyrics = await loadOfflineLyrics();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(EmoSikApp(
      isLoggedIn: isLoggedIn,
      offlineLyrics: offlineLyrics,
    ));
  }, (error, stack) {
    debugPrint('❌ Uncaught error: $error');
  });
}

class EmoSikApp extends StatelessWidget {
  final bool isLoggedIn;
  final List<Map<String, dynamic>> offlineLyrics;

  const EmoSikApp({
    super.key,
    required this.isLoggedIn,
    required this.offlineLyrics,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmoSik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff9A8C98),
        scaffoldBackgroundColor: const Color(0xfff7f3e8),
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(isLoggedIn: isLoggedIn, offlineLyrics: offlineLyrics),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomePage(offlineLyrics: offlineLyrics),
            );
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          case '/emotion':
            return MaterialPageRoute(builder: (_) => const EmotionDetectionPage());
          case '/face-detection':
            return MaterialPageRoute(builder: (_) => const FaceDetectionPage());
          case '/offline-library':
            return MaterialPageRoute(
              builder: (_) => OfflineLibraryPage(offlineLyrics: offlineLyrics),
            );
          default:
            return null;
        }
      },
    );
  }
}
