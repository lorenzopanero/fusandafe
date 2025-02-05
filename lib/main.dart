import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/profile_screen.dart';
import 'dart:async';

void main() async {
  

  // Catch any uncaught Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Catch any uncaught Dart errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    );

    // Check the initial route based on authentication status
    final initialRoute = await _getInitialRoute();
    
    runApp(MyApp(initialRoute: initialRoute));
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}

Future<String> _getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  if (isFirstTime) {
    await prefs.setBool('isFirstTime', false);
    return '/intro';
  }

  final user = FirebaseAuth.instance.currentUser;
  return user != null ? '/profile' : '/intro';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Test App',
      initialRoute: initialRoute,
      routes: {
        '/': (context) => LoginScreen(),
        '/intro': (context) => IntroScreen(),
        '/register': (context) => RegistrationScreen(),
        '/profile': (context) => ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
      },
    );
  }
}
