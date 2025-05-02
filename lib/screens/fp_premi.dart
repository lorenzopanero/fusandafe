import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorPremiScreen extends StatelessWidget {
  const SponsorPremiScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchSponsors() async {
    final snapshot = await FirebaseFirestore.instance.collection('sponsors').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premi in palio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSponsors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Errore nel caricamento dei dati.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessuno sponsor trovato.'));
          }

          final sponsors = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sponsors.length + 2, // Add 2: one for the introduction and one for the "Premio finale" card
            itemBuilder: (context, index) {
              if (index == 0) {
                // Introduction text
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Con il contributo di:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else if (index <= sponsors.length) {
                final sponsor = sponsors[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                  leading: sponsor['logo'] != null && sponsor['logo'].isNotEmpty
                    ? ClipOval(
                      child: Image.network(
                      sponsor['logo'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      ),
                    )
                    : const Icon(Icons.account_circle),
                  title: Text(sponsor['name'] ?? 'Sponsor'),
                  subtitle: Text(sponsor['address'] ?? 'Indirizzo non disponibile'),
                  ),
                );
              } else {
                // "Premio finale" card
                return Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Premio finale',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Un fantastico premio per il vincitore del FantaPalio!',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}