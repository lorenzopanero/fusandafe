import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class OfferteScreen extends StatefulWidget {
  @override
  _OfferteScreenState createState() => _OfferteScreenState();
}

class _OfferteScreenState extends State<OfferteScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
  bool _showValidationButtons = false; // State to toggle the validation buttons

  void _toggleValidationButtons() {
    setState(() {
      _showValidationButtons = !_showValidationButtons;
    });
  }

  void _showOfferPopup(BuildContext context, QueryDocumentSnapshot offer) {
    String uniqueCode = "${offer.id}_$userId";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: SizedBox(
            width: 300, // Set an appropriate width
            height: 300, // Set an appropriate height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: uniqueCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                SelectableText("Codice: $uniqueCode"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offerte'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddOfferScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('offers').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var offers = snapshot.data!.docs;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
            ),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              var offer = offers[index];
              return GestureDetector(
                onTap: () => _showOfferPopup(context, offer),
                child: Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(offer['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(offer['shop']),
                      if (offer['deadline'] != null) Text('Scade il: ${offer['deadline']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Main Floating Action Button
          FloatingActionButton(
            heroTag: 'mainFab', // Assign a unique heroTag
            onPressed: _toggleValidationButtons,
            child: Icon(_showValidationButtons ? Icons.close : Icons.qr_code_scanner),
          ),
          // "Scansiona QR" Button
          if (_showValidationButtons)
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton.extended(
                heroTag: 'scanQrFab', // Assign a unique heroTag
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRScannerScreen()),
                  );
                },
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scansiona QR'),
              ),
            ),
          // "Inserisci Manualmente" Button
          if (_showValidationButtons)
            Padding(
              padding: const EdgeInsets.only(bottom: 150.0),
              child: FloatingActionButton.extended(
                heroTag: 'manualInputFab', // Assign a unique heroTag
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualInputScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.keyboard),
                label: Text('Inserisci Manualmente'),
              ),
            ),
        ],
      ),
    );
  }
}

class AddOfferScreen extends StatefulWidget {
  @override
  _AddOfferScreenState createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  final _titleController = TextEditingController();
  final _shopController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _maxRedemptionsController = TextEditingController();

  Future<void> _addOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _titleController.text.isEmpty || _shopController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compila tutti i campi obbligatori.')));
      return;
    }

    await FirebaseFirestore.instance.collection('offers').add({
      'title': _titleController.text,
      'shop': _shopController.text,
      'authorId': user.uid,
      'deadline': _deadlineController.text.isNotEmpty ? _deadlineController.text : null,
      'maxRedemptions': _maxRedemptionsController.text.isNotEmpty ? int.tryParse(_maxRedemptionsController.text) : null,
      'redemptions': [],
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crea Offerta')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Titolo')),
            TextField(controller: _shopController, decoration: InputDecoration(labelText: 'Autore/Negozi')),
            TextField(controller: _deadlineController, decoration: InputDecoration(labelText: 'Scadenza (opzionale)')),
            TextField(controller: _maxRedemptionsController, decoration: InputDecoration(labelText: 'Max utilizzi (opzionale)')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _addOffer, child: Text('Salva Offerta')),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final data = scanData.code ?? '';
      if (!data.contains('_')) return;

      final parts = data.split('_');
      final offerId = parts[0];
      final userId = parts[1];

      await validateOffer(offerId, userId);
      controller.pauseCamera();
      Navigator.pop(context);
    });
  }

  Future<void> validateOffer(String offerId, String userId) async {
    final offerRef = FirebaseFirestore.instance.collection('offers').doc(offerId);
    final offerSnap = await offerRef.get();

    if (!offerSnap.exists) {
      _showSnackbar(context, 'Offerta non trovata', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    final offerData = offerSnap.data()!;
    final authorId = offerData['authorId']; // Get the author ID from the offer document
    final redeemedBy = offerData['redemptions'] ?? {};
    final max = offerData['maxRedemptions'];
    final current = offerData['redeemedCount'] ?? 0;

    // Check if the current user is the author of the offer
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != authorId) {
      _showSnackbar(context, 'Solo l\'autore dell\'offerta può validarla.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    if (redeemedBy.containsKey(userId)) {
      _showSnackbar(context, 'Offerta già usata da questo utente.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    if (max != null && current >= max) {
      _showSnackbar(context, 'Offerta esaurita.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    await offerRef.update({
      'redemptions': FieldValue.arrayUnion([userId]),
      'redeemedCount': FieldValue.increment(1),
    });

    _showSnackbar(context, 'Offerta validata con successo!', const Color.fromARGB(255, 32, 83, 33));
    return;
  }

  void _showSnackbar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scansiona QR')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.deepPurple,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }
}

class ManualInputScreen extends StatefulWidget {
  @override
  _ManualInputScreenState createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _offerIdController = TextEditingController();

  @override
  void dispose() {
    _offerIdController.dispose();
    super.dispose();
  }

  Future<void> validateOffer(String offerId, String userId) async {
    final offerRef = FirebaseFirestore.instance.collection('offers').doc(offerId);
    final offerSnap = await offerRef.get();

    if (!offerSnap.exists) {
      _showSnackbar(context, 'Offerta non trovata', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    final offerData = offerSnap.data()!;
    final authorId = offerData['authorId']; // Get the author ID from the offer document
    final redeemedBy = offerData['redemptions'] ?? {};
    final max = offerData['maxRedemptions'];
    final current = offerData['redeemedCount'] ?? 0;

    // Check if the current user is the author of the offer
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != authorId) {
      _showSnackbar(context, 'Solo l\'autore dell\'offerta può validarla.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    if (redeemedBy.containsKey(userId)) {
      _showSnackbar(context, 'Offerta già usata da questo utente.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    if (max != null && current >= max) {
      _showSnackbar(context, 'Offerta esaurita.', const Color.fromARGB(255, 146, 34, 26));
      return;
    }

    await offerRef.update({
      'redemptions': FieldValue.arrayUnion([userId]),
      'redeemedCount': FieldValue.increment(1),
    });

    _showSnackbar(context, 'Offerta validata con successo!', const Color.fromARGB(255, 32, 83, 33));
    return;
  }

  void _showSnackbar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserisci Manualmente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _offerIdController,
              decoration: InputDecoration(
                labelText: 'Inserisci l\'ID dell\'offerta',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final offerId = _offerIdController.text.trim();
                if (offerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Per favore, inserisci un ID valido.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Utente non autenticato.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await validateOffer(offerId, userId);
                Navigator.pop(context);
              },
              child: Text('Valida Offerta'),
            ),
          ],
        ),
      ),
    );
  }
}
