import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'food_recipes.dart';

class EdamamRecipes extends StatefulWidget {
  @override
  _EdamamRecipesState createState() => _EdamamRecipesState();
}

class _EdamamRecipesState extends State<EdamamRecipes> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _recipes = [];
  String _query = '';
  String? _selectedDiet;
  String? _selectedHealth; 

  List<String> _dietOptions = [
    'balanced',
    'high-fiber',
    'high-protein',
    'low-fat',
    'low-carb',
    'low-sodium',
  ];

  List<String> _healthOptions = [
    'alcohol-cocktail',
    'alcohol-free',
    'celery-free',
    'crustacean-free',
    'dairy-free',
    'DASH',
    'egg-free',
    'fish-free',
    'fodmap-free',
    'gluten-free',
    'immuno-supportive',
    'keto-friendly',
    'kidney-friendly',
    'kosher',
    'low-fat-abs',
    'low-potassium',
    'low-sugar',
    'lupine-free',
    'Mediterranean',
    'mollusk-free',
    'mustard-free',
    'no-oil-added',
    'paleo',
    'peanut-free',
    'pescatarian',
    'pork-free',
    'red-meat-free',
    'sesame-free',
    'shellfish-free',
    'soy-free',
    'sugar-conscious',
    'sulfite-free',
    'tree-nut-free',
    'vegan',
    'vegetarian',
    'wheat-free',
  ];

  Future<void> _fetchRecipes(String query,
      {String? dietLabel, String? healthLabel}) async {
    final String appId = '7e85a1ab';
    final String appKey = 'e082fc4e59a2231ad81032cf8d5f64e7';
    String apiUrl =
        'https://api.edamam.com/search?q=$query&app_id=$appId&app_key=$appKey';

    if (dietLabel != null && dietLabel.isNotEmpty) {
      apiUrl += '&diet=$dietLabel';
    }

    if (healthLabel != null && healthLabel.isNotEmpty) {
      apiUrl += '&health=$healthLabel';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        _recipes = json.decode(response.body)['hits'];
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Recipes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Diet'),
                value: _selectedDiet,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDiet = newValue;
                  });
                },
                items: _dietOptions.map((String diet) {
                  return DropdownMenuItem<String>(
                    value: diet,
                    child: Text(diet),
                  );
                }).toList(),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Health'),
                value: _selectedHealth,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHealth = newValue;
                  });
                },
                items: _healthOptions.map((String health) {
                  return DropdownMenuItem<String>(
                    value: health,
                    child: Text(health),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchRecipes(_query, dietLabel: _selectedDiet, healthLabel: _selectedHealth);
                setState(() {
                  _selectedDiet = null;
                  _selectedHealth = null;
                });
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Recipes',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _query = _searchController.text;
                          _fetchRecipes(_query, dietLabel: _selectedDiet, healthLabel: _selectedHealth);
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _showFilterDialog,
                  child: Text('Filter', style: TextStyle(color: Colors.green),),
                ),
              ],
            ),
          ),
          Expanded(
            child: _recipes.isEmpty
                ? Center(
                    child: Text('No recipes found'),
                  )
                : ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index]['recipe'];
                      return ListTile(
                        leading: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.network(
                            recipe['image'],
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(recipe['label'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Source: ${recipe['source']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
