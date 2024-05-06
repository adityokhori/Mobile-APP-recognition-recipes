import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:grinv/open_bottom.dart';

class StartQuiz extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('questions').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No questions available.'),
            );
          }

          var randomQuestionData =
              snapshot.data!.docs[Random().nextInt(snapshot.data!.docs.length)];

          return QuizQuestionCard(
            difficult: randomQuestionData['difficulty'],
            question: randomQuestionData['question'],
            options: List<String>.from(randomQuestionData['options']),
            timer: randomQuestionData['timer'],
            correctAnswer: randomQuestionData['correctAnswer'],
            point: randomQuestionData['point'],
          );
        },
      ),
    );
  }
}

class QuizQuestionCard extends StatefulWidget {
  final String difficult;
  final String question;
  final List<String> options;
  final int timer;
  final String correctAnswer;
  final int point;

  QuizQuestionCard(
      {required this.difficult,
      required this.question,
      required this.options,
      required this.timer,
      required this.correctAnswer,
      required this.point});

  @override
  _QuizQuestionCardState createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard>
    with SingleTickerProviderStateMixin {
  late int _currentTimer;
  late Timer _timer;
  int? _selectedOptionIndex;
  bool _isTimeUpDialogShown = false;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _currentTimer = widget.timer;
    startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentTimer > 0) {
          _currentTimer--;
        } else {
          _timer.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Center(
                    child: Text(
                      '$_currentTimer',
                      style: TextStyle(color: Colors.purple, fontSize: 25),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Card(
            margin: EdgeInsets.all(10.0),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          'Level : ${widget.difficult}',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        child: Text(
                          '${widget.point} point',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.purple,
                    ),
                    child: Text(
                      '${widget.question}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(widget.options.length, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                          onPressed: _isAnswered
                              ? null
                              : () {
                                  setState(() {
                                    _selectedOptionIndex = index;
                                    _isAnswered = true;
                                  });
                                  _checkAnswer();
                                },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (_selectedOptionIndex == index) {
                                  if (_selectedOptionIndex != null &&
                                      widget.options[_selectedOptionIndex!] ==
                                          widget.correctAnswer) {
                                    return Colors.green;
                                  } else {
                                    return Colors.red;
                                  }
                                }
                                return Colors.white;
                              },
                            ),
                          ),
                          child: Text(
                            widget.options[index],
                            style: TextStyle(
                              color: _selectedOptionIndex == index
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (_isAnswered)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OpenButtom()),
                  );
                },
                child: Icon(Icons.arrow_back),
              ),
            ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    if (_currentTimer > 0) {
      _timer.cancel();

      bool isCorrect = _selectedOptionIndex != null &&
          widget.options[_selectedOptionIndex!] == widget.correctAnswer;
      int point = isCorrect ? widget.point : 0;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isCorrect
            ? 'Correct Answer!, You got $point point'
            : 'Wrong Answer!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
      ));
      if (isCorrect) {
        _updateUserPoints(point);
      }
    } else {
      if (!_isTimeUpDialogShown) {
        _showTimeUpDialog();
      }
    }
  }

  void _showTimeUpDialog() {
    print('SHOWTIME');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _isTimeUpDialogShown = true;

        return AlertDialog(
          title: Text("Time's Up!"),
          content: Text("You ran out of time. Quiz will now end."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OpenButtom()),
                );
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _updateUserPoints(int pointsToAdd) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      var userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

      var userData = await userDoc.get();

      if (userData.exists && userData.data()!.containsKey('point_quiz')) {
        int currentPoints = userData.data()!['point_quiz'];
        int updatedPoints = currentPoints + pointsToAdd;

        await userDoc.update({'point_quiz': updatedPoints});
      } else {
        await userDoc.set({'point_quiz': pointsToAdd}, SetOptions(merge: true));
      }
    } catch (error) {
      print('Error updating user points: $error');
    }
  }
}
