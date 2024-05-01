import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeFirestoreService {
  final CollectionReference recipeCollection = FirebaseFirestore.instance.collection('recipes');

  Future<void> addRecipe(Map<String, dynamic> recipe) async {
    try {
      await recipeCollection.add(recipe);
    } catch (e) {
      print('Error adding recipe: $e');
    }
  }
}
