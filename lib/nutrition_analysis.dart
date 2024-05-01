import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NutritionAnalysisPage extends StatefulWidget {
  @override
  _NutritionAnalysisPageState createState() => _NutritionAnalysisPageState();
}

class _NutritionAnalysisPageState extends State<NutritionAnalysisPage> {
  TextEditingController _textInputController = TextEditingController();
  Map<String, dynamic> _analysisResult = {};

  Future<void> _getNutritionAnalysis(String text) async {
  String apiKey = '6d591b8cc2f48c2203031201601ec9f9';
  String appId = '1f3285ba';

  List<String> ingredients = text.split(','); 

  String endpoint =
      'https://api.edamam.com/api/nutrition-data?app_id=$appId&app_key=$apiKey&ingr=';
  Map<String, String> headers = {'Content-Type': 'application/json'};

  try {
    // Iterasi melalui setiap bahan
    for (String ingredient in ingredients) {
      String trimmedIngredient = ingredient.trim(); // Menghapus spasi di awal dan akhir
      final response =
          await http.get(Uri.parse('$endpoint$trimmedIngredient'), headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          // Menggabungkan hasil analisis untuk setiap bahan
          if (_analysisResult.isEmpty) {
            _analysisResult = json.decode(response.body);
          } else {
            // Menggabungkan hasil analisis dari setiap bahan
            Map<String, dynamic> analysis = json.decode(response.body);
            _mergeAnalysisResults(analysis);
            print(analysis);
          }
        });
      } else {
        setState(() {
          _analysisResult = {'error': response.reasonPhrase};
        });
        return; // Menghentikan iterasi jika terjadi kesalahan
      }
    }
  } catch (e) {
    setState(() {
      _analysisResult = {'error': e.toString()};
    });
  }
}

void _mergeAnalysisResults(Map<String, dynamic> analysis) {
  // Menggabungkan hasil analisis dari setiap bahan
  _analysisResult['calories'] += analysis['calories'] ?? 0;
  _analysisResult['totalCO2Emissions'] += analysis['totalCO2Emissions'] ?? 0;
  _analysisResult['totalWeight'] += analysis['totalWeight'] ?? 0;

  // Menggabungkan label
  (_analysisResult['dietLabels'] as List).addAll(analysis['dietLabels'] ?? []);
  (_analysisResult['healthLabels'] as List).addAll(analysis['healthLabels'] ?? []);
  (_analysisResult['cautions'] as List).addAll(analysis['cautions'] ?? []);

  // Menggabungkan nutrisi
  _mergeNutrients(_analysisResult['totalNutrients'], analysis['totalNutrients']);
}

void _mergeNutrients(Map<String, dynamic> existingNutrients, Map<String, dynamic>? newNutrients) {
  if (newNutrients == null) return;

  // Iterasi melalui nutrisi baru dan menambahkannya ke nutrisi yang sudah ada
  newNutrients.forEach((key, value) {
    if (existingNutrients.containsKey(key)) {
      existingNutrients[key]['quantity'] += value['quantity'] ?? 0;
    } else {
      existingNutrients[key] = value;
    }
  });
}

Widget _buildNutrientRow(String label, Map<String, dynamic>? nutrient) {
  if (nutrient == null) {
    return SizedBox.shrink();
  }

  double quantity = nutrient['quantity'] ?? 0.0; 
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
            TextField(
              controller: _textInputController,
              decoration: InputDecoration(
                labelText: 'Enter ingredients (comma separated)',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _getNutritionAnalysis(_textInputController.text);
              },
              child: Text('Analyze'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Result:',
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
                              
                              // Tambahkan baris untuk nutrisi lain di sini sesuai kebutuhan
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
