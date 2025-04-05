import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OfferteScreen extends StatefulWidget {
  @override
  _OfferteScreenState createState() => _OfferteScreenState();
}

class _OfferteScreenState extends State<OfferteScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ValidateOfferScreen(),
          ));
        },
        child: Icon(Icons.qr_code_scanner),
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

class ValidateOfferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Valida Offerta')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerScreen(),
                  ),
                );
              },
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scansiona QR'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to manual input
              },
              icon: Icon(Icons.keyboard),
              label: Text('Inserisci Codice Manualmente'),
            ),
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
      _showToast('Offerta non trovata');
      return;
    }

    final offerData = offerSnap.data()!;
    final redeemedBy = offerData['redeemedBy'] ?? {};
    final max = offerData['maxRedemptions'];
    final current = offerData['redeemedCount'] ?? 0;

    if (redeemedBy.containsKey(userId)) {
      _showToast('Offerta già usata da questo utente.');
      return;
    }

    if (max != null && current >= max) {
      _showToast('Offerta esaurita.');
      return;
    }

    await offerRef.update({
      'redeemedBy.$userId': true,
      'redeemedCount': FieldValue.increment(1),
    });

    _showToast('Offerta validata con successo!');
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
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