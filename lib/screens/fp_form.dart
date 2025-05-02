import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAnswer {
  final String question;
  final dynamic answer;

  UserAnswer({required this.question, required this.answer});

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

class FantapalioFormScreen extends StatefulWidget {
  const FantapalioFormScreen({Key? key}) : super(key: key);

  @override
  State<FantapalioFormScreen> createState() => _FantapalioFormScreenState();
}

class _FantapalioFormScreenState extends State<FantapalioFormScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _submittedAfterDeadline = false;

  final List<UserAnswer> _answers = [];
  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _formValues = {};
  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'text',
      'question': 'Quale borgo si aggiudicher\u00e0 il Palio2k24?',
    },
    {
      'question': 'Scegli il tuo Fantino',
      'type': 'text',
    },
    {
      'question': 'Numero massimo di oche abbattute in un turno',
      'type': 'number',
    },
    {
      'question': 'Chi vincer\u00e0 la corsa alle bandiere?',
      'type': 'text',
    },
    {
      'question': 'Scegli un MEGA-bonus',
      'type': 'multiple_choice',
      'options': [
        'Il fantino vincitore impenna il cavallo',
        'Lo speaker dice una parolaccia',
        'Un figurante cade in arena'
      ]
    },
    {
      'question': 'Scegli un micro-bonus',
      'type': 'multiple_choice',
      'options': [
        'Almeno un fantino si ritira',
        'La Proloco vende pi\u00f9 di 15 fusti di birra',
        'Il Monarca pronuncia la parola “FantaPalio”'
      ]
    }
  ];

  Map<int, dynamic> _originalFormValues = {};

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<bool> _checkIfLateSubmission() async {
    final now = DateTime.now();
    final eventDate = DateTime(2025, 6, 13, 19, 0, 0);
    return now.isAfter(eventDate);
  }

  Future<void> _loadAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('fantapalio_answers')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final answers = data['answers'] as List<dynamic>;

      for (var answer in answers) {
        final questionIndex = _questions.indexWhere(
          (q) => q['question'] == answer['question'],
        );
        if (questionIndex != -1) {
          _formValues[questionIndex] = answer['answer'];
        }
      }

      setState(() {
        _originalFormValues = Map.from(_formValues); // Save original values
      });
    }
  }
  
  Future<void> _saveAnswers() async {
    setState(() {
      _isSubmitting = true;
    });

    final isLate = await _checkIfLateSubmission();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> answers = [];
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i]['question'];
      final answer = _formValues[i];
      answers.add(UserAnswer(question: question, answer: answer).toMap());
    }

    await FirebaseFirestore.instance
        .collection('fantapalio_answers')
        .doc(user.uid)
        .set({
      'answers': answers,
      'submittedAt': DateTime.now(),
      'penalty': isLate,
    });

    setState(() {
      _submittedAfterDeadline = isLate;
      _isSubmitting = false;
      _originalFormValues = Map.from(_formValues); // Update original values
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("FantaModulo inviato!"),
        content: Text(isLate
            ? "Hai inviato dopo l'inizio dell'evento. Le risposte non concorreranno alla classifica, ma potrai comunque visualizzare i risultati."
            : "Ottimo! Le tue risposte sono state salvate correttamente."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"))
        ],
      ),
    );
  }

  void _cancelChanges() {
    setState(() {
      _formValues.clear();
      _formValues.addAll(_originalFormValues); // Revert to original values
      _currentStep = 0; // Reset to the first step
    });
  }

  void _onStepContinue() {
    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveAnswers();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildStepContent(int index) {
    final question = _questions[index];
    final type = question['type'];

    // Dynamically fetch the answer for the current step
    final initialValue = _formValues[index] ?? '';

    switch (type) {
      case 'text':
        final controller = TextEditingController(text: initialValue);
        return TextFormField(
          controller: controller, // Use controller instead of initialValue
          onChanged: (val) => _formValues[index] = val,
          decoration: InputDecoration(labelText: question['question']),
        );
      case 'number':
        final controller = TextEditingController(text: initialValue.toString());
        return TextFormField(
          controller: controller, // Use controller instead of initialValue
          onChanged: (val) => _formValues[index] = int.tryParse(val),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: question['question']),
        );
      case 'multiple_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (question['options'] as List<String>)
              .map((opt) => RadioListTile(
                    title: Text(opt),
                    value: opt,
                    groupValue: _formValues[index], // Prefill only for the current step
                    onChanged: (val) => setState(() {
                      _formValues[index] = val;
                    }),
                  ))
              .toList(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il tuo FantaModulo'),
        actions: [
          TextButton(
            onPressed: _cancelChanges,
            child: const Text(
              "Annulla",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              steps: List.generate(
                _questions.length,
                (index) => Step(
                  title: Text(_questions[index]['question']),
                  content: _buildStepContent(index), // Dynamically load content
                  isActive: index == _currentStep,
                  state: _formValues[index] != null && _formValues[index] != ''
                      ? StepState.complete
                      : StepState.indexed,
                ),
              ),
            ),
    );
  }
}
