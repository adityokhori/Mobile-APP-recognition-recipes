import 'package:flutter/material.dart';

class FoodDetailPage extends StatelessWidget {
  final Map<String, dynamic> foodDetails;

  FoodDetailPage({required this.foodDetails});

  Widget _buildNutrientRow(String label, Map<String, dynamic>? nutrient) {
    if (nutrient == null) {
      return const SizedBox
          .shrink(); // Jika nilai nutrisi null, kembalikan widget kosong
    }

    double quantity = nutrient['quantity'] ?? 0.0; // Nilai default jika null
    String unit = nutrient['unit'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('$quantity $unit'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Title(
                color: Colors.black,
                child: Text(
                  '${foodDetails['ingredients'][0]['parsed'][0]['foodMatch']}',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Calories: ${foodDetails['calories']} kcal',
            ),
            Text(
              'Total CO2 Emissions: ${foodDetails['totalCO2Emissions']}',
            ),
            Text(
              'Total Weight: ${foodDetails['totalWeight']}',
            ),
            Text(
              'Diet Labels: ${(foodDetails['dietLabels'] as List).join(', ')}',
            ),
            Text(
              'Health Labels: ${(foodDetails['healthLabels'] as List).join(', ')}',
            ),
            Text(
              'Cautions: ${(foodDetails['cautions'] as List).join(', ')}',
            ),
            const Divider(),
            const Text(
              'Nutrients:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNutrientRow(
                  'Energy',
                  foodDetails['totalNutrients']['ENERC_KCAL'],
                ),
                _buildNutrientRow(
                  'Fat',
                  foodDetails['totalNutrients']['FAT'],
                ),
                _buildNutrientRow(
                    'Cholesterol', foodDetails['totalNutrients']['CHOLE']),
                _buildNutrientRow('Total Carbohydrate',
                    foodDetails['totalNutrients']['CHOCDF.net']),
                _buildNutrientRow(
                    'Protein', foodDetails['totalNutrients']['PROCNT']),
                _buildNutrientRow(
                    'Sodium', foodDetails['totalNutrients']['NA']),
                _buildNutrientRow(
                    'Calcium', foodDetails['totalNutrients']['CA']),
                _buildNutrientRow(
                    'Sugar', foodDetails['totalNutrients']['Sugar']),
                _buildNutrientRow(
                    'Vitamin A', foodDetails['totalNutrients']['VITA_RAE']),
                _buildNutrientRow(
                    'Vitamin C', foodDetails['totalNutrients']['VITC']),
                _buildNutrientRow(
                    'Vitamin B-6', foodDetails['totalNutrients']['VITB6A']),
                _buildNutrientRow(
                    'Vitamin B-12', foodDetails['totalNutrients']['VITB12']),
                _buildNutrientRow(
                    'Vitamin D', foodDetails['totalNutrients']['VITD']),
                _buildNutrientRow(
                    'Water', foodDetails['totalNutrients']['WATER']),

                // Tambahkan baris untuk nutrisi lain di sini sesuai kebutuhan
              ],
            ),
          ],
        ),
      ),
    );
  }
}
