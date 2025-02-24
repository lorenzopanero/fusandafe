import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

class EventiScreen extends StatefulWidget {
  @override
  _EventiScreenState createState() => _EventiScreenState();
}

class _EventiScreenState extends State<EventiScreen> {
  bool _showCalendar = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DocumentSnapshot>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    FirebaseFirestore.instance.collection('events').orderBy('date').snapshots().listen((snapshot) {
      setState(() {
        _events = {};
        for (var event in snapshot.docs) {
          DateTime date = event['date'].toDate();
          if (_events[date] == null) {
            _events[date] = [];
          }
          _events[date]!.add(event);
        }
      });
    });
  }

  List<DocumentSnapshot> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Color _getEventColor(int eventCount) {
    if (eventCount == 1) {
      return Colors.green;
    } else if (eventCount == 2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildEventCard(DocumentSnapshot event) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 8.0, // Increase the elevation for more shadow
      color: Color.fromARGB(255, 224, 203, 255), // Very light tone of the same palette as #5E17EB
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event['title'],
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    // Handle save to favorites action
                  },
                ),
              ],
            ),
            Text(
              event['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event['place'],
                    style: TextStyle(fontSize: 16.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(event['link']);
                    print('Attempting to launch URL: $url');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      print('Could not launch $url');
                      throw 'Could not launch $url';
                    }
                  },
                  child: Text(event['linkLabel']),
                ),
              ],
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
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF5E17EB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddEventScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _showCalendar ? _buildCalendarView() : _buildListView(),
      bottomNavigationBar: BottomAppBar(
        child: TextButton(
          onPressed: () {
            setState(() {
              _showCalendar = !_showCalendar;
            });
          },
          child: Text(_showCalendar ? 'Visualizza Lista' : 'Visualizza Calendario'),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
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
    );
  }

  Widget _buildCalendarView() {
    return TableCalendar(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay; // update `_focusedDay` here as well
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: _getEventsForDay,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isNotEmpty) {
            return Positioned(
              right: 1,
              bottom: 1,
              child: _buildEventMarker(events.length),
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEventMarker(int eventCount) {
    return Container(
      width: 16.0,
      height: 16.0,
      decoration: BoxDecoration(
        color: _getEventColor(eventCount),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$eventCount',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
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
  final _linkController = TextEditingController();
  final _linkLabelController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null || _placeController.text.isEmpty || _linkController.text.isEmpty || _linkLabelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Per favore, riempi tutti i campi.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': Timestamp.fromDate(_selectedDate!),
      'place': _placeController.text,
      'link': _linkController.text,
      'linkLabel': _linkLabelController.text,
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
        title: Text('Aggiungi Evento'),
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
              maxLines: 3,
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              controller: _placeController,
              labelText: 'Luogo',
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              controller: _linkController,
              labelText: 'Link (es. locandina, iscrizione...)',
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              controller: _linkLabelController,
              labelText: 'Etichetta del Link',
              inputFormatters: [
                LengthLimitingTextInputFormatter(20),
              ],
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