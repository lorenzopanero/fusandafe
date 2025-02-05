import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fantapalio_screen.dart';
import 'eventi_screen.dart';
import 'idee_screen.dart';
import 'offerte_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _firstName = userDoc['firstName'];
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () => _navigateToScreen(screen),
      child: Card(
        color: const Color(0xFF5E17EB), // Purple background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 4.0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50.0, color: Colors.white), // Changed icon color to white for better contrast
              SizedBox(height: 10.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Changed text color to white for better contrast
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ciao, $_firstName!',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.black,),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Cosa ti stuzzica oggi?',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    _buildCard('FantaPalio', Icons.sports_soccer, FantaPalioScreen()),
                    _buildCard('Eventi', Icons.event, EventiScreen()),
                    _buildCard('Idee', Icons.lightbulb, IdeeScreen()),
                    _buildCard('Offerte', Icons.local_offer, OfferteScreen()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}