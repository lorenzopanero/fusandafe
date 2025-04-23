import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fp_form.dart';
import 'fp_bonus.dart';
import 'fp_results.dart';

class FantapalioDashboardScreen extends StatefulWidget {
  const FantapalioDashboardScreen({super.key});

  @override
  State<FantapalioDashboardScreen> createState() => _FantapalioDashboardScreenState();
}

class _FantapalioDashboardScreenState extends State<FantapalioDashboardScreen> {
  int xp = 0;
  int level = 1;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String selectedBorgo = "Scegli i tuoi colori!"; // Default text for bottom button
  Color buttonColor = Color(0xFF5E17EB); // Default button color
  Color buttonTextColor = Colors.white; // Default button text color
  final borghi = {
    'Vecchio': {'primary': const Color.fromARGB(255, 12, 12, 12), 'secondary': const Color.fromARGB(255, 238, 52, 39)},
    'Piazza': {'primary': const Color.fromARGB(255, 59, 23, 10), 'secondary': const Color.fromARGB(255, 236, 222, 96)},
    'Salice': {'primary': const Color.fromARGB(255, 5, 86, 153), 'secondary': Colors.white},
    'S. Antonio': {'primary': const Color.fromARGB(255, 8, 109, 11), 'secondary': Colors.white},
    'S. Bernardo': {'primary': const Color.fromARGB(255, 145, 0, 0), 'secondary': Colors.white},
    'Nuovo': {'primary': const Color.fromARGB(255, 12, 12, 12), 'secondary': Colors.white},
    'Romanisio': {'primary': const Color.fromARGB(255, 1, 18, 48), 'secondary': const Color.fromARGB(255, 238, 52, 39)},
  };

  final levelDescriptions = [
    "Pulcino d’Oca",
    "Pulcino Adolescente",
    "Pulcino Maturo",
    "Pennuta Novizia",
    "Oca da Cortile",
    "Oca da Sfilata",
    "Oca Funesta",
    "Oca da Marcia",
    "Oca da Caccia",
    "Oca da Allenamento",
    "Oca da Gara",
    "Oca Maestra",
    "Oca dell’Arena",
    "Oca da Palio",
    "Oca Gloriosa",
    "Oca Eroica",
    "Oca del Monarca",
    "Sovrana delle Oche",
    "Oca Imperiale",
    "Oca Angelica",
    "Leggenda delle Oche",
    "Oca Celestiale",
    "Oca Divina"
  ];

  @override
  void initState() {
    super.initState();
    fetchUserXP();
    checkUserBorgo();
  }

  Future<void> fetchUserXP() async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists && doc.data() != null) {
    final data = doc.data()!;
    setState(() {
      xp = data['xp'] ?? 0;

      // Define XP thresholds for each level
      final List<int> xpThresholds = [
        10, 20, 40, 80, 160, 240, 320, 400, 500, 600, 700, 800, 1000, 1200, 1400,
        1600, 1800, 2000, 2400, 2800, 3200, 3600, 4000
      ];

      // Determine the current level based on XP thresholds
      level = 1; // Default to level 1
      for (int i = 0; i < xpThresholds.length; i++) {
        if (xp < xpThresholds[i]) {
          level = i + 1;
          break;
        }
      }

      // If XP exceeds all thresholds, set to max level
      if (xp >= xpThresholds.last) {
        level = xpThresholds.length + 1;
      }
    });
  }
}

  void navigateTo(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> checkUserBorgo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final borgo = data['borgo'] as String?;

      if (borgo != null && borgo.isNotEmpty) {
        if (borghi.containsKey(borgo)) {
          setState(() {
            selectedBorgo = "Forza Borgo $borgo!";
            buttonColor = borghi[borgo]!['primary']!;
            buttonTextColor = borghi[borgo]!['secondary']!;
          });
        }
      }
    }
  }

  Future<void> _selectBorgo(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey.shade200, // Set modal sheet background color to grey
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ListView(
            children: [
              ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      backgroundColor: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.purple, // Secondary circle for "Colori originali"
                    ),
                  ],
                ),
                title: const Text("Colori originali"),
                onTap: () {
                  Navigator.pop(context, "Colori originali");
                },
              ),
              ...borghi.entries.map((entry) {
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: entry.value['primary'],
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: entry.value['secondary'], // Add secondary color circle
                      ),
                    ],
                  ),
                  title: Text("Borgo ${entry.key}"), // Add "Borgo" before each name
                  onTap: () {
                    Navigator.pop(context, entry.key);
                  },
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        if (selected == "Colori originali") {
          selectedBorgo = "Scegli i tuoi colori!";
          buttonColor = const Color(0xFF5E17EB); // Default button color
          buttonTextColor = Colors.white; // Default button text color
        } else {
          selectedBorgo = "Forza Borgo $selected!";
          buttonColor = borghi[selected]!['primary']!;
          buttonTextColor = borghi[selected]!['secondary']!;
        }
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'borgo': selected == "Colori originali" ? "" : selected,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Il tuo FantaPalio"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 8,
                      spreadRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  const SizedBox(height: 10),
                  if (level == 0)
                    Text("Livello 0", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                  else if (level <= levelDescriptions.length)
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Livello $level: ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                      levelDescriptions[level - 1],
                      style: const TextStyle(fontSize: 18),
                      ),
                    ],
                    )
                  else
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Livello $level: ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                      levelDescriptions.last,
                      style: const TextStyle(fontSize: 18),
                      ),
                    ],
                    ),
                  const SizedBox(height: 5),
                  XPProgressBar(xp: xp, buttonColor: buttonColor, levelDescriptions: levelDescriptions),
                  const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  DashboardButton(
                    icon: Icons.edit_document,
                    label: 'Compila / Rivedi il tuo FantaModulo',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FantapalioFormScreen(),
                        ),
                      );
                    },
                    buttonColor: buttonColor,
                    buttonTextColor: buttonTextColor,
                  ),
                  const SizedBox(height: 16),
                  DashboardButton(
                    icon: Icons.card_giftcard,
                    label: 'Punti Bonus & Spiegazioni',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FantapalioBonusScreen(),
                        ),
                      );
                    },
                    buttonColor: buttonColor,
                    buttonTextColor: buttonTextColor,
                  ),
                  const SizedBox(height: 16),
                  DashboardButton(
                    icon: Icons.leaderboard,
                    label: 'Classifica generale',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FantapalioResultScreen(
                            totalScore: 0, // Replace with the actual total score
                            placement: 0,  // Replace with the actual placement
                          ),
                        ),
                      );
                    },
                    buttonColor: buttonColor,
                    buttonTextColor: buttonTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _selectBorgo(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                  color: buttonColor,
                ),
                child: Center(
                  child: Text(
                    selectedBorgo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color buttonColor;
  final Color buttonTextColor;

  const DashboardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.buttonColor, // Initialize buttonColor
    required this.buttonTextColor, // Initialize buttonTextColor
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor, // Use the inherited buttonColor
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: buttonColor,
              blurRadius: 8,
              offset: const Offset(2, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: buttonTextColor), // Use buttonTextColor for the icon
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: buttonTextColor, // Use buttonTextColor for the text
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPProgressBar extends StatelessWidget {
  final int xp;
  final Color buttonColor;
  final List<String> levelDescriptions;

  const XPProgressBar({
    super.key,
    required this.xp,
    required this.buttonColor,
    required this.levelDescriptions,
  });

  @override
  Widget build(BuildContext context) {
    // Define XP thresholds for each level
    final List<int> xpThresholds = [
      10, 20, 40, 80, 160, 240, 320, 400, 500, 600, 700, 800, 1000, 1200, 1400,
      1600, 1800, 2000, 2400, 2800, 3200, 3600, 4000
    ];

    // Determine the current level and progress
    int currentLevel = 0;
    double progress = 0.0;
    int xpForCurrentLevel = 0;
    int xpForNextLevel = 0;

    for (int i = 0; i < xpThresholds.length; i++) {
      if (xp < xpThresholds[i]) {
        currentLevel = i + 1;
        xpForCurrentLevel = i == 0 ? 0 : xpThresholds[i - 1];
        xpForNextLevel = xpThresholds[i];
        progress = (xp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
        break;
      }
    }

    // If XP exceeds all thresholds, set to max level
    if (currentLevel == 0) {
      currentLevel = xpThresholds.length + 1;
      xpForCurrentLevel = xpThresholds.last;
      xpForNextLevel = xpForCurrentLevel; // No next level
      progress = 1.0;
    }

    // Determine the next level description
    currentLevel++;
    String nextLevelDescription = currentLevel < levelDescriptions.length + 1
        ? levelDescriptions[currentLevel - 1]
        : "Oca Divina Lv. $currentLevel";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: buttonColor,
              backgroundColor: Color.fromARGB(
                (buttonColor.alpha * 0.3).toInt(),
                buttonColor.red,
                buttonColor.green,
                buttonColor.blue,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$xp/$xpForNextLevel XP per diventare: $nextLevelDescription",
            style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 119, 119, 119)),
          ),
        ],
      ),
    );
  }
}
