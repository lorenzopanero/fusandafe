import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FantapalioResultScreen extends StatefulWidget {
  final int totalScore;
  final int placement;
  final bool showLeaderboard;
  final List<Map<String, dynamic>>? leaderboard; // [{"username": "Mario", "score": 240}, ...]

  const FantapalioResultScreen({
    Key? key,
    required this.totalScore,
    required this.placement,
    this.showLeaderboard = false,
    this.leaderboard,
  }) : super(key: key);

  @override
  State<FantapalioResultScreen> createState() => _FantapalioResultScreenState();
}

class _FantapalioResultScreenState extends State<FantapalioResultScreen> {
  late String medalAsset;
  late String placementText;

  @override
  void initState() {
    super.initState();
    _determineMedal();
  }

  void _determineMedal() {
    if (widget.placement == 1) {
      medalAsset = 'assets/lottie/gold_medal.json';
      placementText = '🏆 1° posto! Sei il campione!';
    } else if (widget.placement == 2) {
      medalAsset = 'assets/lottie/silver_medal.json';
      placementText = '🥈 2° posto! Ottimo lavoro!';
    } else if (widget.placement == 3) {
      medalAsset = 'assets/lottie/bronze_medal.json';
      placementText = '🥉 3° posto! Grande prova!';
    } else {
      medalAsset = 'assets/lottie/fireworks.json';
      placementText = 'Hai totalizzato ${widget.totalScore} punti!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risultati Fantapalio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              placementText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Lottie.asset(
              medalAsset,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 20),
            if (widget.placement > 3)
              Text(
                'Ti sei classificato al ${widget.placement}° posto! 👏',
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 30),
            Text(
              'Punteggio totale: ${widget.totalScore} XP',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            if (widget.showLeaderboard && widget.leaderboard != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classifica globale',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.leaderboard!.length,
                    itemBuilder: (context, index) {
                      final player = widget.leaderboard![index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0
                              ? Colors.amber
                              : index == 1
                                  ? Colors.grey
                                  : index == 2
                                      ? Colors.brown
                                      : Colors.blueGrey,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(player['username'] ?? 'Anonimo'),
                        trailing: Text('${player['score']} XP'),
                      );
                    },
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
