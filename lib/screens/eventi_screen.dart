import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EventiScreen extends StatelessWidget {
  
  Widget _buildEventCard(DocumentSnapshot event) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'],
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              event['description'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: () {
                  // Handle save to favorites action
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventi'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEventScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> events = snapshot.data!.docs;
          Map<String, List<DocumentSnapshot>> groupedEvents = {};

          for (var event in events) {
            String date = DateFormat('dd/MM/yyyy').format(event['date'].toDate());
            if (groupedEvents[date] == null) {
              groupedEvents[date] = [];
            }
            groupedEvents[date]!.add(event);
          }

          List<Widget> eventWidgets = [];
          groupedEvents.forEach((date, events) {
            eventWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    date,
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
            events.forEach((event) {
              eventWidgets.add(_buildEventCard(event));
            });
          });

          return ListView(
            children: eventWidgets,
          );
        },
      ),
    );
  }
}

class AddEventScreen extends StatefulWidget {
  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  DateTime? _selectedDate;
  File? _eventImage;
  String? _eventImageUrl;

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null || _placeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Per favore, riempi tutti i campi.')),
      );
      return;
    }

    // Upload image to storage and get URL (not implemented here)
    // String imageUrl = await uploadImage(_selectedImage);

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': Timestamp.fromDate(_selectedDate!),
      'place': _placeController.text,
      // 'image': imageUrl,
    });

    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _eventImage = File(pickedFile.path);
      });

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_eventImage!);
        _eventImageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.of(context).size.width * 0.6;

    return Scaffold(
      appBar: AppBar(
        title: Text('Aggiungi Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: _eventImage != null
                      ? DecorationImage(
                          image: FileImage(_eventImage!),
                          fit: BoxFit.cover,
                        )
                      : (_eventImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_eventImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: AssetImage('assets/default_event_thumbnail.png'),
                              fit: BoxFit.cover,
                            )),
                ),
                child: _eventImage == null && _eventImageUrl == null
                    ? Center(child: Icon(Icons.camera_alt, color: Colors.white))
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titolo'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrizione'),
              maxLines: 3,
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),
            TextField(
              controller: _placeController,
              decoration: InputDecoration(labelText: 'Luogo'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'Nessuna data selezionata'
                      : 'Data scelta: ${DateFormat.yMd().format(_selectedDate!)}',
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Scegli data'),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _addEvent,
              child: Text('Invia Evento'),
            ),
          ],
        ),
      ),
    );
  }
}
