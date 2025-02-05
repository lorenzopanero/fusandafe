import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  DateTime? _selectedDate;

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': Timestamp.fromDate(_selectedDate!),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No date chosen!'
                      : 'Picked Date: ${DateFormat.yMd().format(_selectedDate!)}',
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Choose Date'),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _addEvent,
              child: Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}