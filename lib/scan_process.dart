import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionAnalysisPage2 extends StatefulWidget {
  final String foodDetails;
  final bool showSaveButton;

  NutritionAnalysisPage2({
    required this.foodDetails,
    this.showSaveButton = true,
  });

  @override
  _NutritionAnalysisPage2State createState() => _NutritionAnalysisPage2State();
}

class _NutritionAnalysisPage2State extends State<NutritionAnalysisPage2> {
  Map<String, dynamic> _analysisResult = {};

  Future<void> _getNutritionAnalysis(String foodDetails) async {
    String apiKey = '6d591b8cc2f48c2203031201601ec9f9';
    String appId = '1f3285ba';
    
    String endpoint =
        'https://api.edamam.com/api/nutrition-data?app_id=$appId&app_key=$apiKey&ingr=1%20whole%20$foodDetails';
    Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _analysisResult = json.decode(response.body);
        });
      } else {
        setState(() {
          _analysisResult = {'error': response.reasonPhrase};
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = {'error': e.toString()};
      });
    }
  }

  Widget _buildNutrientRow(String label, Map<String, dynamic>? nutrient) {
    if (nutrient == null) {
      return SizedBox.shrink(); // Jika nilai nutrisi null, kembalikan widget kosong
    }

    double quantity = nutrient['quantity'] ?? 0.0; // Nilai default jika null
    String unit = nutrient['unit'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$quantity $unit'),
      ],
    );
  }

  void _saveToFirestore(Map<String, dynamic> foodDetails) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final foodsCollectionRef = userDocRef.collection('foods');

      foodsCollectionRef.add(foodDetails)
        .then((_) {
          // Data saved successfully
          print('Food details saved to Firestore');
        })
        .catchError((error) {
          print('Error saving food details: $error');
        });
    } else {
      print('User not authenticated');
    }
  }

  @override
  void initState() {
    super.initState();
    _getNutritionAnalysis(widget.foodDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Result for ${widget.foodDetails}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    if (_analysisResult.containsKey('error'))
                      Text(
                        'Error: ${_analysisResult['error']}',
                        style: TextStyle(color: Colors.red),
                      ),
                    if (_analysisResult.isNotEmpty &&
                        !_analysisResult.containsKey('error'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calories: ${_analysisResult['calories']} kcal',
                          ),
                          Text(
                            'Total CO2 Emissions: ${_analysisResult['totalCO2Emissions']}',
                          ),
                          Text(
                            'Total Weight: ${_analysisResult['totalWeight']}',
                          ),
                          Text(
                            'Diet Labels: ${(_analysisResult['dietLabels'] as List).join(', ')}',
                          ),
                          Text(
                            'Health Labels: ${(_analysisResult['healthLabels'] as List).join(', ')}',
                          ),
                          Text(
                            'Cautions: ${(_analysisResult['cautions'] as List).join(', ')}',
                          ),
                          Divider(),
                          Text(
                            'Nutrients:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNutrientRow(
                                'Energy',
                                _analysisResult['totalNutrients']['ENERC_KCAL'],
                              ),
                              _buildNutrientRow(
                                'Fat',
                                _analysisResult['totalNutrients']['FAT'],
                              ),
                              _buildNutrientRow(
                                'Cholesterol',
                                _analysisResult['totalNutrients']['CHOLE']
                              ),
                              _buildNutrientRow(
                                'Total Carbohydrate',
                                _analysisResult['totalNutrients']['CHOCDF.net']
                              ),
                              _buildNutrientRow(
                                'Protein',
                                _analysisResult['totalNutrients']['PROCNT']
                              ),
                              _buildNutrientRow(
                                'Sodium',
                                _analysisResult['totalNutrients']['NA']
                              ),
                              _buildNutrientRow(
                                'Calcium',
                                _analysisResult['totalNutrients']['CA']
                              ),
                              _buildNutrientRow(
                                'Sugar',
                                _analysisResult['totalNutrients']['Sugar']
                              ),
                              _buildNutrientRow(
                                'Vitamin A',
                                _analysisResult['totalNutrients']['VITA_RAE']
                              ),
                              _buildNutrientRow(
                                'Vitamin C',
                                _analysisResult['totalNutrients']['VITC']
                              ),
                              _buildNutrientRow(
                                'Vitamin B-6',
                                _analysisResult['totalNutrients']['VITB6A']
                              ),
                              _buildNutrientRow(
                                'Vitamin B-12',
                                _analysisResult['totalNutrients']['VITB12']
                              ),
                              _buildNutrientRow(
                                'Vitamin D',
                                _analysisResult['totalNutrients']['VITD']
                              ),
                              _buildNutrientRow(
                                'Water',
                                _analysisResult['totalNutrients']['WATER']
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (widget.showSaveButton)
              FloatingActionButton(
                onPressed: () {
                  _saveToFirestore(_analysisResult);
                },
                child: Text('Save Data'),
              ),
          ],
        ),
      ),
    );
  }
}
