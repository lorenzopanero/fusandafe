import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ciao!',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5E17EB),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.0),
            Text(
              'Ti diamo il benvenuto nell\'app di Fusandafè.',
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.0),
            Text(
              'Qui potrai giocare al FantaPalio, scoprire eventi in zona, contribuire con le tue idee su Fossano e fare tante altre belle cose.',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.0),
            Text(
              'Lanciati verso la prossima schermata per creare il tuo account ed entrare nel vivo di Fusandafè.',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 60.0),
            ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E17EB), // Background color
              foregroundColor: Colors.white, // Text color
              padding: EdgeInsets.symmetric(vertical: 15.0),
              textStyle: TextStyle(fontSize: 18.0),
            ),
            child: Text('Let\'s goooooo  🚀🚀'),
          ),
          ],
        ),
      ),
    );
  }
}