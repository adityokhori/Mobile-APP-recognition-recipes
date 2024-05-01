import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'full_nutrition_page.dart';

class FoodsHistoryPage extends StatefulWidget {
  const FoodsHistoryPage({Key? key}) : super(key: key);

  @override
  State<FoodsHistoryPage> createState() => _FoodsHistoryPageState();
}

class _FoodsHistoryPageState extends State<FoodsHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Please sign in to view saved recipes.'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Food Nutri History :'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('foods')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No saved recipes yet.'));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<DocumentSnapshot> documents = snapshot.data!.docs;
              documents.forEach((doc) {
                if (!doc.exists ||
                    (doc.data()! as Map<String, dynamic>)
                            .containsKey('timestamp') &&
                        doc['timestamp'] == null) {
                  doc.reference.update({'timestamp': Timestamp.now()});
                }
              });

              documents.sort((a, b) {
                Timestamp timestampA =
                    (a.data()! as Map<String, dynamic>).containsKey('timestamp')
                        ? a['timestamp']
                        : Timestamp.now();
                Timestamp timestampB =
                    (b.data()! as Map<String, dynamic>).containsKey('timestamp')
                        ? b['timestamp']
                        : Timestamp.now();
                return timestampB.compareTo(timestampA);
              });

              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot document = documents[index];

                  Map<String, dynamic> foodData =
                      document.data()! as Map<String, dynamic>;

                  List<dynamic> ingredients = foodData['ingredients'] ?? [];
                  String foodMatch = '';

                  if (ingredients.isNotEmpty) {
                    Map<String, dynamic> firstIngredient =
                        ingredients.first ?? {};
                    foodMatch =
                        firstIngredient['parsed']?[0]['foodMatch'] ?? '';
                  }

                  String foodName =
                      foodMatch.isNotEmpty ? foodMatch : 'Unknown Food';

                  bool isFoodOpened = foodData.containsKey('opened')
                      ? foodData['opened']
                      : false;

                  return ListTile(
                    title: Text(foodName),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'delete') {
                          _showDeleteConfirmationDialog(context, () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('foods')
                                .doc(document.id)
                                .delete();
                          });
                        }
                      },
                      icon: Icon(Icons.more_vert),
                    ),
                    onTap: () async {
                      if (!isFoodOpened) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('foods')
                            .doc(document.id)
                            .update({'opened': true});
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FoodDetailPage(foodDetails: foodData),
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Function() onDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
