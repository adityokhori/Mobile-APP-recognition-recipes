import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import './service/firebase_recipes.dart';

bool isLoading = false;

class RecipePage extends StatefulWidget {
  final String foodName;

  RecipePage({required this.foodName});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<dynamic> recipes = [];
  String? _selectedDiet;
  String? _selectedHealth;

  final List<String> _dietOptions = [
    'balanced',
    'high-fiber',
    'high-protein',
    'low-fat',
    'low-carb',
    'low-sodium',
  ];

  final List<String> _healthOptions = [
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
  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes({String? dietLabel, String? healthLabel}) async {
    final String apiKey = 'e082fc4e59a2231ad81032cf8d5f64e7';
    final String foodName = widget.foodName;
    final String appId = '7e85a1ab';
    String apiUrl =
        'https://api.edamam.com/search?q=$foodName&app_id=$appId&app_key=$apiKey';

    if (dietLabel != null && dietLabel.isNotEmpty) {
      apiUrl += '&diet=$dietLabel';
    }

    if (healthLabel != null && healthLabel.isNotEmpty) {
      apiUrl += '&health=$healthLabel';
    }
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('hits')) {
          setState(() {
            recipes = data['hits'];
          });
        }
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Recipes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Diet'),
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
                decoration: const InputDecoration(labelText: 'Health'),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchRecipes(
                    dietLabel: _selectedDiet, healthLabel: _selectedHealth);
                setState(() {
                  _selectedDiet = null;
                  _selectedHealth = null;
                });
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes for ${widget.foodName}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (BuildContext context, int index) {
                final recipe = recipes[index]['recipe'];
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recipe['label']),
                            Text('Calories: ${recipe['calories']}'),
                          ],
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        child: recipe['image'] != null
                            ? FutureBuilder<String>(
                                future: _downloadAndSaveImage(recipe['image']),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return const Icon(Icons.error);
                                  } else {
                                    return Image.file(
                                      File(snapshot.data!),
                                      fit: BoxFit.cover,
                                    );
                                  }
                                },
                              )
                            : const Placeholder(),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed:_showFilterDialog,
        child: const Text('+ Filter'),
      ),
    );
  }

  Future<String> _downloadAndSaveImage(String url) async {
    try {
      var response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'your_app_name_here'});
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath =
          '${appDocDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return localPath;
    } catch (e) {
      print('Error downloading image: $e');
      throw Exception('Failed to download image');
    }
  }
}

class RecipeDetailPage extends StatefulWidget {
  final dynamic recipe;
  final bool showSaveButton;

  RecipeDetailPage({required this.recipe, this.showSaveButton = true});
  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final RecipeFirestoreService firestoreService = RecipeFirestoreService();

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe['label']),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.recipe['image'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            widget.recipe['image'],
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '- This recipe is from ${widget.recipe['source']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _launchURL(widget.recipe['url']);
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: '- You can get more information at ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${widget.recipe['url']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16.0),
                    const Text('Ingredients:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    for (var ingredient in widget.recipe['ingredients'])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (ingredient['image'] != null)
                                Expanded(
                                  child: Image.network(
                                    ingredient['image'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text('- ${ingredient['text']}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    const SizedBox(height: 16.0),
                    const Text('Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    const Text(
                        'Please tap the button below to view the instructions for this recipe:'),
                    ElevatedButton(
                      onPressed: () {
                        _launchURL(Uri.parse(widget.recipe['url']));
                      },
                      child: const Text('View Instructions'),
                    ),
                    if (widget.showSaveButton)
                      ElevatedButton(
                        onPressed: () {
                          saveRecipeToFirestore(widget.recipe, context);
                        },
                        child: const Text('Save Data'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void saveRecipeToFirestore(
      Map<String, dynamic> recipe, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isLoading = true;
      });

      final userId = user.uid;
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final recipesCollectionRef = userDocRef.collection('recipes');

      String imageUrl =
          await _uploadImageToStorage(recipe['image'], recipe['label']);

      recipe['image'] = imageUrl;

      recipesCollectionRef.add(recipe).then((_) {
        print('Recipe details saved to Firestore');
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Recipe details have been saved.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }).catchError((error) {
        print('Error saving recipe details: $error');
        setState(() {
          isLoading = false;
        });
      });
    } else {
      print('User not authenticated');
    }
  }

  Future<String> _uploadImageToStorage(
      String imageUrl, String recipeLabel) async {
    try {
      var response = await http.get(Uri.parse(imageUrl),
          headers: {'User-Agent': 'your_app_name_here'});
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('recipe_images/$recipeLabel.png');
      final UploadTask uploadTask =
          storageReference.putData(response.bodyBytes);
      await uploadTask.whenComplete(() => null);
      final String downloadUrl = await storageReference.getDownloadURL();
      print('GAMBAR TELAH DISIMPAN');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      throw Exception('Failed to upload image');
    }
  }
}
