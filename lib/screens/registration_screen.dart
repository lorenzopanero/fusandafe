import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  double _passwordStrength = 0;

  void _checkPasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      _passwordStrength = score / 4;
    });
  }

  List<String> generateSearchKeywords(String name) {
    List<String> keywords = [];
    for (int i = 1; i <= name.length; i++) {
      keywords.add(name.substring(0, i).toLowerCase());
    }
    return keywords;
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Per favore, riempi tutti i campi.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le password non coincidono.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      List<String> searchKeywords = [
        ...generateSearchKeywords(_firstNameController.text.trim()),
        ...generateSearchKeywords(_lastNameController.text.trim())
      ];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': '+39${_phoneController.text.trim()}',
        'searchKeywords': searchKeywords,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrazione completata! 💯💯')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userCredential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: const Color(0xFF5E17EB)),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea il tuo account',
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5E17EB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'I tuoi dati sono al sicuro con noi.',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  _buildTextFormField(
                    controller: _firstNameController,
                    labelText: 'Nome',
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _lastNameController,
                    labelText: 'Cognome',
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    onChanged: (password) => _checkPasswordStrength(password),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey[300],
                      color: _passwordStrength < 0.5
                          ? Colors.red
                          : _passwordStrength < 0.75
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Conferma Password',
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '+39',
                          style: TextStyle(fontSize: 17.0),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _phoneController,
                          labelText: 'Telefono',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E17EB), // Background color
                            foregroundColor: Colors.white, // Text color
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            textStyle: TextStyle(fontSize: 18.0),
                          ),
                          child: Text('Registrati'),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[800], // Text color
                    ),
                    child: Text('Hai già un account? Clicca qui e accedi.'),
                  ),
                  SizedBox(height: 40), // Extra space at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
