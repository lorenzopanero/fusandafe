import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

class EventiScreen extends StatefulWidget {
  @override
  _EventiScreenState createState() => _EventiScreenState();
}

class _EventiScreenState extends State<EventiScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID
  bool _showCalendar = false;
  bool _showFavorites = false; // Determines if only favorite events should be displayed
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final LinkedHashMap<DateTime, List<DocumentSnapshot>> _events;
  List<DocumentSnapshot> _selectedEvents = [];
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToToday = false;

  @override
  void initState() {
    super.initState();
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: (key) => key.hashCode,
    );
    _loadEvents();
  }

  void _loadEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _events.clear(); // Ensure the map is reset before adding new data

        for (var event in snapshot.docs) {
          DateTime fullDate = event['date'].toDate();
          // Normalize to UTC to avoid time zone issues
          DateTime date = DateTime.utc(fullDate.year, fullDate.month, fullDate.day);

          if (_events[date] == null) {
            _events[date] = [];
          }
          _events[date]!.add(event);
        }
      });
    });
  }

  // List view

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> events = snapshot.data!.docs;

        // Filter only favorited events if _showFavorites is active
        if (_showFavorites) {
          events = events.where((event) {
            if (event.data() == null || !(event.data() as Map<String, dynamic>).containsKey('favorites')) {
              return false; // Skip events without a "favorites" field
            }

            List<dynamic>? favorites = (event['favorites'] as List<dynamic>?);
            return favorites != null && favorites.contains(userId);
          }).toList();
        }

        Map<String, List<DocumentSnapshot>> groupedEvents = {};
        String todayDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
        int todayIndex = 0;
        int indexCounter = 0;

        for (var event in events) {
          String date = DateFormat('dd/MM/yyyy').format(event['date'].toDate());
          groupedEvents.putIfAbsent(date, () => []).add(event);
        }

        List<Widget> eventWidgets = [];
        groupedEvents.forEach((date, events) {
          if (date == todayDate) {
            todayIndex = indexCounter; // Save the index of today’s section
          }

          eventWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  date,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );

          for (var event in events) {
            eventWidgets.add(_buildEventCard(event));
            indexCounter++;
          }
        });

        // Scroll to today's section once the UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_hasScrolledToToday) {
            _scrollController.animateTo(
              todayIndex * 200.0, // Adjust based on item height
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            _hasScrolledToToday = true;
          }
        });

        return ListView(
          controller: _scrollController,
          children: eventWidgets,
        );
      },
    );
  }

  Widget _buildEventCard(DocumentSnapshot event) {
    List<dynamic> favorites = (event.data() as Map<String, dynamic>).containsKey('favorites') == true
    ? event['favorites']
    : [];
    bool isFavorite = favorites.contains(userId); // Check if user already favorited

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 8.0,
      color: Color.fromARGB(255, 224, 203, 255),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event['title'] ?? 'No Title',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () async {
                    if (userId == null) return; // Ensure user is logged in

                    List<dynamic> updatedFavorites = List.from(favorites);

                    if (isFavorite) {
                      updatedFavorites.remove(userId); // Remove from favorites
                    } else {
                      updatedFavorites.add(userId); // Add to favorites
                    }

                    await FirebaseFirestore.instance
                        .collection('events')
                        .doc(event.id)
                        .update({'favorites': updatedFavorites});
                  },
                ),
              ],
            ),
            Text(
              event['description'] ?? 'No Description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event['place'] ?? 'Unknown Location',
                    style: TextStyle(fontSize: 16.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (event['link'] != null) {
                      final url = Uri.parse(event['link']);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    }
                  },
                  child: Text(event['linkLabel'] ?? 'Open', style: TextStyle(color: Color(0xFF5E17EB))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calendar view

  Color _getEventColor(int eventCount) {
    if (eventCount == 1) {
      return Colors.green;
    } else if (eventCount == 2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          key: ValueKey(_events.hashCode), // Forces widget update
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) async {
            await Future.delayed(Duration(milliseconds: 50)); // Allow async update
            setState(() {
              // Normalize selectedDay to UTC
              _selectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
              _focusedDay = DateTime.utc(focusedDay.year, focusedDay.month, focusedDay.day);
              _selectedEvents = _events[_selectedDay] ?? [];
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
          eventLoader: (day) => _events[day] != null ? _events[day]! : [],
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
        ),
        const SizedBox(height: 10), // Spacing
        _buildEventList(), // List of events
      ],
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

  Widget _buildEventList() {
    return Expanded(
      child: _selectedEvents.isEmpty
          ? const Center(child: Text("Nessun evento in data scelta."))
          : ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                var event = _selectedEvents[index];
                // Ensure that event.data() is not null before proceeding
                Map<String, dynamic>? eventData = event.data() as Map<String, dynamic>?;

                // If eventData is null, return an empty container or handle the error gracefully
                if (eventData == null) {
                  return Container(); // Or handle the null data case as needed
                }

                List<dynamic> favorites = eventData.containsKey('favorites') == true
                    ? eventData['favorites']
                    : [];
                bool isFavorite = favorites.contains(userId); // Check if user already favorited

                return Card(
                  color: Color.fromARGB(255, 224, 203, 255),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(eventData['title'] ?? 'Senza nome'),
                    subtitle: Text(
                      eventData['description'] ?? 'Senza descrizione',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: const Icon(Icons.event, color: Color(0xFF5E17EB)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        eventData['link'] != null && eventData['linkLabel'] != null
                            ? TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final Uri url = Uri.parse(eventData['link']);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    throw "Errore nell'apertura di ${eventData['link']}";
                                  }
                                },
                                child: Text(
                                  eventData['linkLabel'],
                                  style: const TextStyle(color: Color(0xFF5E17EB)),
                                ),
                              )
                            : Container(),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () async {
                            if (userId == null) return; // Ensure user is logged in

                            List<dynamic> updatedFavorites = List.from(favorites);

                            // Toggle favorite status
                            if (isFavorite) {
                              updatedFavorites.remove(userId); // Remove from favorites
                            } else {
                              updatedFavorites.add(userId); // Add to favorites
                            }

                            // Update Firestore (await here)
                            await FirebaseFirestore.instance
                                .collection('events')
                                .doc(event.id)
                                .update({'favorites': updatedFavorites});

                            // Fetch the updated event **before** calling setState()
                            var updatedEventSnapshot = await event.reference.get();

                            // Update state synchronously
                            setState(() {
                              _selectedEvents[index] = updatedEventSnapshot;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventi'),
        actions: [
          if (!_showCalendar) // Hide "Salvati" when in calendar mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showFavorites ? Color(0xFF5E17EB) : Colors.white,
                  foregroundColor: _showFavorites ? Colors.white : Color(0xFF5E17EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showFavorites = !_showFavorites;
                  });
                },
                child: Text('Preferiti'),
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
        color: Colors.transparent,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Color(0xFF5E17EB),
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
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
