import 'package:flutter/material.dart';
import 'recognition.dart';
import 'account_info.dart';
import 'history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EdamamRecipes.dart';
import 'nutrition_analysis.dart';
import 'quiz.dart';

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

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _selectedIndex == 0
        ? QuizPage()
          : _selectedIndex == 1
            ? HistoryPage()
              : _selectedIndex == 2
                ? Recognition()
                  : MyAccount();

    return Scaffold(
      appBar: AppBar(
        title: ColorFiltered(
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
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications)),
        ],
      ),
      body: Stack( 
        children: [
          body,
          Positioned( 
            bottom: 80, 
            right: 16,
            child: FloatingActionButton(
              heroTag: 'buttonAnalysis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NutritionAnalysisPage()),
                );
              },
              child: Icon(Icons.analytics, color: Colors.white,),
              backgroundColor: Colors.green, 
            ),
          ),
          Positioned( 
            bottom: 16, 
            right: 16, 
            child: FloatingActionButton(
              heroTag: 'buttonRecipes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EdamamRecipes()),
                );
              },
              child: Icon(Icons.receipt, color: Colors.white,),
              backgroundColor: Colors.green,
            ),
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
