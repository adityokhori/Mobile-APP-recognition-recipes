import 'package:cloud_firestore/cloud_firestore.dart';

class FoodFirestoreService {
  final CollectionReference foodCollection = FirebaseFirestore.instance.collection('foods');

  Future<void> addFood(Map<String, dynamic> foodDetails) async {
    try {
      await foodCollection.add(foodDetails);
    } catch (e) {
      print('Error adding food: $e');
    }
  }
}
