import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinv/open_bottom.dart';

class StartQuiz extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Quiz'),
      ),
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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var questionData = snapshot.data!.docs[index];
              return QuizQuestionCard(
                question: questionData['question'],
                options: List<String>.from(questionData['options']),
                timer: questionData['timer'],
                correctAnswer: questionData['correctAnswer'],
              );
            },
          );
        },
      ),
    );
  }
}

class QuizQuestionCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final int timer;
  final String correctAnswer;

  QuizQuestionCard(
      {required this.question,
      required this.options,
      required this.timer,
      required this.correctAnswer});

  @override
  _QuizQuestionCardState createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  late int _currentTimer;
  late Timer _timer;
  List<bool> _isChecked = [];

  @override
  void initState() {
    super.initState();
    _currentTimer = widget.timer;
    _isChecked = List<bool>.generate(widget.options.length, (index) => false);
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
    return Card(
      margin: EdgeInsets.all(10.0),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question: ${widget.question}',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Options:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(widget.options.length, (index) {
                return CheckboxListTile(
                  title: Text(widget.options[index]),
                  value: _isChecked[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 10.0),
            Text(
              'Timer: $_currentTimer seconds',
              style: TextStyle(fontSize: 16.0),
            ),
            ElevatedButton(
              onPressed: _checkAnswer,
              child: Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAnswer() {
    _timer.cancel(); // Stop the timer when submitting answer
    List<String> selectedOptions = [];
    for (int i = 0; i < _isChecked.length; i++) {
      if (_isChecked[i]) {
        selectedOptions.add(widget.options[i]);
      }
    }

    bool isCorrect = selectedOptions.contains(widget.correctAnswer);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isCorrect ? 'Correct Answer!' : 'Wrong Answer!'),
    ));
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Time's Up!"),
          content: Text("You ran out of time for this question."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OpenButtom(),
                      ),
                    );
              },
            ),
          ],
        );
      },
    );
  }
}
