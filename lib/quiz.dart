import 'package:flutter/material.dart';
import 'package:grinv/start_quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DateTime now = DateTime.now();

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    void updateLastQuizTime() {
      if (user != null) {
        firestore
            .collection('users')
            .doc(user.uid)
            .update({'lastQuizTime': now});
      }
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 155, 92, 167),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayQuiz(),
                  ),
                );
              },
              child: Text(
                'Create Quiz',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (user != null) {
                  firestore.collection('users').doc(user.uid).get().then((doc) {
                    if (doc.exists) {
                      Timestamp? lastQuizTimestamp =
                          doc.data()?['lastQuizTime'];
                      if (lastQuizTimestamp != null) {
                        DateTime lastQuizTime = lastQuizTimestamp.toDate();
                        DateTime nextAccessibleTime =
                            lastQuizTime.add(Duration(hours: 1));
                        if (now.isAfter(nextAccessibleTime)) {
                          updateLastQuizTime();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StartQuiz(),
                            ),
                          );
                        } else {
                          print(
                              'Anda hanya dapat mengakses "Start Quiz" setiap 1 jam sekali.');
                        }
                      } else {
                        updateLastQuizTime();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StartQuiz(),
                          ),
                        );
                      }
                    }
                  });
                }
              },
              child: Text(
                'Start Quiz',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 10), // Spacer
            if (user != null) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  Timestamp? lastQuizTimestamp = snapshot.data?['lastQuizTime'];
                  if (lastQuizTimestamp != null) {
                    DateTime lastQuizTime = lastQuizTimestamp.toDate();
                    DateTime nextAccessibleTime =
                        lastQuizTime.add(Duration(hours: 1));
                    if (now.isBefore(nextAccessibleTime)) {
                      Duration remainingTime =
                          nextAccessibleTime.difference(now);
                      int hours = remainingTime.inHours;
                      int minutes = remainingTime.inMinutes.remainder(60);
                      // int seconds = remainingTime.inSeconds.remainder(60);
                      return Text(
                        'Next access in: ${hours.toString()} hours ${minutes.toString()} minutes',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      );
                    }
                  }
                  return Container(); // Return an empty container if conditions are not met
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlayQuiz extends StatefulWidget {
  @override
  State<PlayQuiz> createState() => _PlayQuizState();
}

class _PlayQuizState extends State<PlayQuiz> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _option1Controller;
  late TextEditingController _option2Controller;
  late TextEditingController _option3Controller;
  late TextEditingController _option4Controller;
  late TextEditingController _correctAnswerController;
  late TextEditingController _difficultyController;
  late TextEditingController _timerController;
  late TextEditingController _pointController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _option1Controller = TextEditingController();
    _option2Controller = TextEditingController();
    _option3Controller = TextEditingController();
    _option4Controller = TextEditingController();
    _correctAnswerController = TextEditingController();
    _difficultyController = TextEditingController();
    _timerController = TextEditingController();
    _pointController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Quiz Question'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(labelText: 'Question'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _option1Controller,
                decoration: InputDecoration(labelText: 'Option 1'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter option 1';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _option2Controller,
                decoration: InputDecoration(labelText: 'Option 2'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter option 2';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _option3Controller,
                decoration: InputDecoration(labelText: 'Option 3'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter option 3';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _option4Controller,
                decoration: InputDecoration(labelText: 'Option 4'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter option 4';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _correctAnswerController,
                decoration: InputDecoration(labelText: 'Correct Answer'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the correct answer';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pointController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Point'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the point';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _difficultyController,
                decoration: InputDecoration(labelText: 'Difficulty'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the difficulty level';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _timerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Timer (seconds)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the time limit';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitQuestion();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitQuestion() {
    int timer = int.tryParse(_timerController.text) ?? 0;
    int point = int.tryParse(_pointController.text) ??
        0; // Mengonversi input point menjadi angka

    FirebaseFirestore.instance.collection('questions').add({
      'question': _questionController.text,
      'options': [
        _option1Controller.text,
        _option2Controller.text,
        _option3Controller.text,
        _option4Controller.text,
      ],
      'correctAnswer': _correctAnswerController.text,
      'difficulty': _difficultyController.text,
      'timer': timer,
      'point': point, // Menambahkan nilai point ke dalam dokumen
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Question added successfully'),
      ));
      _resetForm();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add question: $error'),
      ));
    });
  }

  void _resetForm() {
    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    _correctAnswerController.clear();
    _difficultyController.clear();
    _timerController.clear();
    _pointController.clear();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _correctAnswerController.dispose();
    _difficultyController.dispose();
    _timerController.dispose();
    _pointController.dispose();
    super.dispose();
  }
}
