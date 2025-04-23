import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FantapalioBonusScreen extends StatefulWidget {
  const FantapalioBonusScreen({super.key});

  @override
  State<FantapalioBonusScreen> createState() => _FantapalioBonusScreenState();
}

class _FantapalioBonusScreenState extends State<FantapalioBonusScreen> {
  bool hasClaimedToday = false;
  int userXp = 0;

  final List<String> megaBonus = [
    'I trattori sistemano il circuito durante il Palio',
    'Lo speaker dice una parolaccia',
    'Più di 3 false partenze dei cavalli',
    'Un figurante cade in arena',
    'Il fantino vincitore impenna il cavallo'
  ];

  final List<String> microBonus = [
    'Lo speaker dice la parola "FantaPalio"',
    'Almeno un fantino si ritira',
    'La Proloco vende più di 15 fusti di birra',
    'I fantini non prendono la spada almeno 2 volte',
    'Almeno 3 striscioni parlano del FantaPalio',
    'Il Monarca pronuncia la parola “FantaPalio”'
  ];

  @override
  void initState() {
    super.initState();
    _checkDailyXpClaim();
    _loadUserXp();
  }

  Future<void> _checkDailyXpClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyXp')
        .doc(today);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      setState(() {
        hasClaimedToday = true;
      });
    }
  }

  Future<void> _loadUserXp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists && docSnapshot.data()!.containsKey('xp')) {
      setState(() {
        userXp = docSnapshot['xp'];
      });
    }
  }

  Future<void> _claimDailyXp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || hasClaimedToday) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final xpDocRef = userRef.collection('dailyXp').doc(today);

    await xpDocRef.set({'claimed': true, 'timestamp': DateTime.now()});
    await userRef.set({'xp': FieldValue.increment(10)}, SetOptions(merge: true));

    setState(() {
      hasClaimedToday = true;
      userXp += 10;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('XP giornaliero riscattato! +10 XP')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (userXp % 100) / 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonus e Regole'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGamificationBar(progress),
            const SizedBox(height: 20),
            _buildDailyXpButton(),
            const SizedBox(height: 20),
            const Text(
              'Mega-Bonus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...megaBonus.map((b) => ListTile(leading: const Icon(Icons.stars), title: Text(b))),
            const SizedBox(height: 20),
            const Text(
              'Micro-Bonus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...microBonus.map((b) => ListTile(leading: const Icon(Icons.bolt), title: Text(b))),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Regole e Premio Finale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ogni giorno puoi riscattare 10 XP come premio fedeltà. '
              'I mega e micro bonus verranno calcolati dopo il Palio. '
              'Il premio finale andrà al partecipante con più XP al termine del Palio!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progresso XP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Container(
              height: 20,
              width: MediaQuery.of(context).size.width * progress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('$userXp XP'),
      ],
    );
  }

  Widget _buildDailyXpButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: hasClaimedToday ? null : _claimDailyXp,
        icon: const Icon(Icons.cake),
        label: Text(hasClaimedToday ? 'Già riscattato oggi' : 'Riscatta XP giornaliero'),
      ),
    );
  }
}
