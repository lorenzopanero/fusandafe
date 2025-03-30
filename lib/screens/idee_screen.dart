import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IdeeScreen extends StatefulWidget {
  @override
  _IdeeScreenState createState() => _IdeeScreenState();
}

class _IdeeScreenState extends State<IdeeScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
  String? selectedCategory = 'Tutte'; // Selected category from the dropdown
  String selectedOrder = 'Più votate'; // Selected ordering criteria

  Future<void> _vote(String ideaId, bool isUpvote) async {
    DocumentReference ideaRef = FirebaseFirestore.instance.collection('ideas').doc(ideaId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ideaRef);
      if (!snapshot.exists) return;

      List<dynamic> upvotes = snapshot['upvotes'] ?? [];
      List<dynamic> downvotes = snapshot['downvotes'] ?? [];

      // Ensure the userId is available
      if (userId == null) return;

      if (isUpvote) {
        if (upvotes.contains(userId)) {
          // User already upvoted, remove from upvotes
          upvotes.remove(userId);
        } else {
          // Add user to upvotes if not already in upvotes
          upvotes.add(userId);
          // If the user had downvoted, remove from downvotes
          if (downvotes.contains(userId)) {
            downvotes.remove(userId);
          }
        }
      } else {
        if (downvotes.contains(userId)) {
          // User already downvoted, remove from downvotes
          downvotes.remove(userId);
        } else {
          // Add user to downvotes if not already in downvotes
          downvotes.add(userId);
          // If the user had upvoted, remove from upvotes
          if (upvotes.contains(userId)) {
            upvotes.remove(userId);
          }
        }
      }

      // Update Firestore with the new upvotes and downvotes lists
      transaction.update(ideaRef, {
        'upvotes': upvotes,
        'downvotes': downvotes,
      });
    });
  }

  Widget _voteButton(IconData icon, int count, List<String> usersVoted, bool isUpvote, String ideaId) {
    bool isVoted = usersVoted.contains(userId);  // Check if the current user has voted
    Color iconColor = Colors.black;  // Default color for unvoted
    if (isVoted) {
      iconColor = isUpvote ? Colors.blue : Colors.red;  // Set color based on the vote type
    }

    return Row(
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor),
          onPressed: () {
            _vote(ideaId, isUpvote);
          },
        ),
        Text("$count", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idee'),
        actions: [
          // Category Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              hint: Text('Categoria'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                });
              },
              items: [
                'Tutte', 'Sport', 'Cultura', 'Musica', 'Cibo', 'Arte', 'Urbanistica', 'Altro'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          // Ordering Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedOrder,
              onChanged: (String? newValue) {
                setState(() {
                  selectedOrder = newValue!;
                });
              },
              items: [
                'Più votate',
                'Più recenti',
                'Meno recenti',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF5E17EB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white, size: 22.0),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddIdeaScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ideas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nessuna idea. Sii il primo!"));
          }

          List<DocumentSnapshot> ideas = snapshot.data!.docs;

          // Filter ideas based on selected category
          if (selectedCategory != null && selectedCategory != 'Tutte') {
            ideas = ideas.where((idea) {
              var data = idea.data() as Map<String, dynamic>?;
              return data?['category'] == selectedCategory;
            }).toList();
          }

          // Sort ideas based on selected order
          if (selectedOrder == 'Più votate') {
            ideas.sort((a, b) {
              int upvotesA = (a['upvotes'] as List).length;
              int downvotesA = (a['downvotes'] as List).length;
              int upvotesB = (b['upvotes'] as List).length;
              int downvotesB = (b['downvotes'] as List).length;
              return (upvotesB - downvotesB).compareTo(upvotesA - downvotesA);
            });
          } else if (selectedOrder == 'Più recenti') {
            ideas.sort((a, b) {
              Timestamp timestampA = a['timestamp'];
              Timestamp timestampB = b['timestamp'];
              return timestampB.compareTo(timestampA); // Most recent first
            });
          } else if (selectedOrder == 'Meno recenti') {
            ideas.sort((a, b) {
              Timestamp timestampA = a['timestamp'];
              Timestamp timestampB = b['timestamp'];
              return timestampA.compareTo(timestampB); // Least recent first
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              var idea = ideas[index];
              Map<String, dynamic>? data = idea.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              String title = data['title'] ?? 'Senza titolo';
              String description = data['description'] ?? 'Nessuna descrizione';
              String author = data['author'] ?? 'Anonimo';
              String category = data['category'] ?? 'Altro';
              Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
              List<String> upvotes = List<String>.from(data['upvotes'] ?? []);
              List<String> downvotes = List<String>.from(data['downvotes'] ?? []);

              String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("👤 $author", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      // Upvote & Downvote Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _voteButton(Icons.thumb_up, upvotes.length, upvotes, true, idea.id),
                          const SizedBox(width: 10),
                          _voteButton(Icons.thumb_down, downvotes.length, downvotes, false, idea.id),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddIdeaScreen extends StatefulWidget {
  @override
  _AddIdeaScreenState createState() => _AddIdeaScreenState();
}

class _AddIdeaScreenState extends State<AddIdeaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  String? _category;
  final List<String> _categories = ['Sport', 'Cultura', 'Musica', 'Cibo', 'Arte', 'Urbanistica', 'Altro'];

  Future<void> _addIdea() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _category == null) { // Check if category is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, riempi tutti i campi.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('ideas').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'author': _authorController.text,
      'category': _category, // Store the selected category
      'timestamp': Timestamp.now(),
      'upvotes': [],
      'downvotes': [],
    });

    Navigator.pop(context);
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    void Function(String)? onChanged,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aggiungi Idea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextFormField(
              controller: _titleController,
              labelText: 'Titolo',
              inputFormatters: [
                LengthLimitingTextInputFormatter(35),
              ],
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              controller: _descriptionController,
              labelText: 'Descrizione',
              maxLines: 4,
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              controller: _authorController,
              labelText: 'Autore',
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _category,
              hint: Text('Seleziona Categoria'),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _category = newValue;
                });
              },
              decoration: InputDecoration(
                labelText: 'Categoria',
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
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _addIdea,
              child: Text('Invia Idea'),
            ),
          ],
        ),
      ),
    );
  }
}
