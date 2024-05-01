import 'dart:convert';
import 'package:http/http.dart' as http;

class USDAFoodAPI {
  static const String apiKey = '7sl2yJUh4NkhWmGBpXrbaNTPQFvdkzMdcHXs1cdc'; // Ganti dengan API Key Anda

  static Future<Map<String, dynamic>?> getFoodDetails(int fdcId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/food/$fdcId?api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('FOOD DETAIL : $data');
        return data;
      } else {
        throw Exception('Failed to load food details');
      }
    } catch (e) {
      print('Error fetching food details: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getNutritionInfo(String foodName) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey&query=$foodName&dataType=Survey%20(FNDDS)'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> foods = data['foods'];
        if (foods.isNotEmpty) {
          final Map<String, dynamic> food = foods.first;
          final int fdcId = food['fdcId'];
          final Map<String, dynamic>? foodDetails = await getFoodDetails(fdcId);
          if (foodDetails != null) {
            // Tambahkan keterangan description di sini
            foodDetails['description'] = '$foodName, raw';
          }
          return foodDetails;
        } else {
          return null;
        }
      } else {
        throw Exception('Failed to load nutrition info');
      }
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }
}
