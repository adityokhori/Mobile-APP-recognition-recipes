import 'package:flutter/material.dart';
import 'package:grinv/food_history.dart';
import 'package:grinv/recipe_history.dart';
import 'package:grinv/scan_history.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late PageController _pageController;
  int _selectedButton = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedButton);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedButton =
                      index; 
                });
              },
              children: [
                RecipeHistoryPage(),
                FoodsHistoryPage(),
                ScanHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () {
            _selectTab(0);
          },
          child: Text('Recipes', style: TextStyle(color: Colors.black),),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                return _selectedButton == 0
                    ? Colors.green.shade100
                    : Colors.grey.shade100;
              },
              
            ),
            minimumSize: MaterialStateProperty.all(
                Size(120, 40)), 
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _selectTab(1);
          },
          child: Text('Foods', style: TextStyle(color: Colors.black),),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                return _selectedButton == 1
                    ? Colors.green.shade100
                    : Colors.grey.shade100;
              },
            ),
            minimumSize: MaterialStateProperty.all(
                Size(120, 40)), 
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _selectTab(2);
          },
          child: Text('Scanner', style: TextStyle(color: Colors.black),),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                return _selectedButton == 2
                    ? Colors.green.shade100
                    : Colors.grey.shade100;
              },
            ),
            minimumSize: MaterialStateProperty.all(
                Size(120, 40)), 
          ),
        ),
      ],
    );
  }

  void _selectTab(int indexButton) {
    setState(() {
      _selectedButton = indexButton;
      _pageController.animateToPage(
        indexButton,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }
}
