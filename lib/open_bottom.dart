import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recognition.dart';
import 'account_info.dart';
import 'history.dart';
import 'EdamamRecipes.dart';
import 'nutrition_analysis.dart';
import 'quiz.dart';
import 'package:grinv/news.dart';

class OpenButtom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BottomNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _checkAndResetDurations(user!.uid);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkAndResetDurations(String userId) async {
    final userData = await _firestore.collection('users').doc(userId).get();
    if (userData.exists) {
      final data = userData.data();
      await _checkAndResetDuration(userId, 'optionAnalysis',
          'optionAnalysisFirstActive', 'optionAnalysisHours', data);
      await _checkAndResetDuration(userId, 'optionRecipes',
          'optionRecipesFirstActive', 'optionRecipesHours', data);
    }
  }

  Future<void> _checkAndResetDuration(
      String userId,
      String optionKey,
      String firstActiveKey,
      String hoursKey,
      Map<String, dynamic>? data) async {
    if (data != null &&
        data.containsKey(firstActiveKey) &&
        data.containsKey(hoursKey)) {
      final firstActiveTimestamp = data[firstActiveKey];
      final hours = data[hoursKey];
      if (firstActiveTimestamp != null && hours != null) {
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        final durationInMillis = hours * 3600000;

        if (currentTimestamp - firstActiveTimestamp >= durationInMillis) {
          // Reset semua atribut terkait jika durasi telah habis
          await _firestore.collection('users').doc(userId).update({
            optionKey: false,
            firstActiveKey: null,
            hoursKey: 0,
          });
          print('Durasi untuk $optionKey telah habis, reset atribut.');
        }
      }
    }
  }

  Future<bool> _getOptionAnalysisStatus(String userId) async {
    final userData = await _firestore.collection('users').doc(userId).get();
    if (userData.exists) {
      final data = userData.data();
      if (data != null && data.containsKey('optionAnalysis')) {
        return data['optionAnalysis'];
      }
    }
    return false;
  }

  Future<bool> _getOptionRecipesStatus(String userId) async {
    final userData = await _firestore.collection('users').doc(userId).get();
    if (userData.exists) {
      final data = userData.data();
      if (data != null && data.containsKey('optionRecipes')) {
        return data['optionRecipes'];
      }
    }
    return false;
  }

  Future<void> _setOptionAnalysisFirstActive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'optionAnalysisFirstActive': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _setOptionRecipesFirstActive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'optionRecipesFirstActive': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _selectedIndex == 0
    ? const NewsApi()
      : _selectedIndex == 1
        ? const QuizPage()
        : _selectedIndex == 2
            ? HistoryPage()
            : _selectedIndex == 3
                ? const Recognition()
                : const MyAccount();

    return Scaffold(
      appBar: AppBar(
        title: const ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.green,
              BlendMode.srcIn,
            ),
            child: Text(
              'grinv',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'SalmaproMedium-yw9ad'),
            )),
      ),
      body: Stack(
        children: [
          body,
          FutureBuilder<bool>(
            future: _getOptionAnalysisStatus(user!.uid),
            builder: (context, snapshot) {
              // if (snapshot.connectionState == ConnectionState.waiting) {
              //   return CircularProgressIndicator();
              // }
              if (snapshot.hasData && snapshot.data == true) {
                return Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'buttonAnalysis',
                    onPressed: () async {
                      await _setOptionAnalysisFirstActive(user!.uid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NutritionAnalysisPage()),
                      );
                    },
                    child: Icon(
                      Icons.analytics,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          FutureBuilder<bool>(
            future: _getOptionRecipesStatus(user!.uid),
            builder: (context, snapshot) {
              // if (snapshot.connectionState == ConnectionState.waiting) {
              //   return CircularProgressIndicator();
              // }
              if (snapshot.hasData && snapshot.data == true) {
                return Positioned(
                  bottom: 15,
                  right: 16, // Adjust the position of buttonRecipes here
                  child: FloatingActionButton(
                    heroTag: 'buttonRecipes',
                    onPressed: () async {
                      await _setOptionRecipesFirstActive(user!.uid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EdamamRecipes()),
                      );
                    },
                    child: Icon(
                      Icons.receipt,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class MyBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  MyBottomNavigationBar(
      {required this.selectedIndex, required this.onItemTapped});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'News',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera),
          label: 'Recognition',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_rounded),
          label: 'Account',
        ),
      ],
      currentIndex: widget.selectedIndex,
      selectedItemColor: Colors.green,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      unselectedItemColor: Colors.grey,
      onTap: widget.onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }
}
