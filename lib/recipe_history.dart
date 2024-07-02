import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'food_recipes.dart';

class RecipeHistoryPage extends StatefulWidget {
  const RecipeHistoryPage({Key? key}) : super(key: key);

  @override
  State<RecipeHistoryPage> createState() => _RecipeHistoryPageState();
}

class _RecipeHistoryPageState extends State<RecipeHistoryPage> {
  Future<String> _downloadAndSaveImage(String recipeLabel) async {
    try {
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('recipe_images/$recipeLabel.png');
      final String localPath =
          '${(await getApplicationDocumentsDirectory()).path}/$recipeLabel.png';
      File file = File(localPath);
      if (!file.existsSync()) {
        await storageReference.writeToFile(file);
      }
      return localPath;
    } catch (e) {
      print('Error downloading image: $e');
      throw Exception('Failed to download image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Recipes'),
        ),
        body: const Center(
          child: Text('Please sign in to view saved recipes.'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Food Recipes History :'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recipes')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No saved recipes yet.'));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              // Ambil semua dokumen dan tambahkan nilai timestamp jika belum ada
              List<DocumentSnapshot> documents = snapshot.data!.docs;
              documents.forEach((doc) {
                if (!doc.exists ||
                    !((doc.data() as Map<String, dynamic>).containsKey('timestamp')) ||
                    doc['timestamp'] == null) {
                  doc.reference.update({'timestamp': Timestamp.now()});
                }
              });

              // Urutkan dokumen berdasarkan timestamp secara descending
              documents.sort((a, b) {
                Timestamp timestampA = (a.data() as Map<String, dynamic>).containsKey('timestamp')
                    ? a['timestamp']
                    : Timestamp.now();
                Timestamp timestampB = (b.data() as Map<String, dynamic>).containsKey('timestamp')
                    ? b['timestamp']
                    : Timestamp.now();
                return timestampB.compareTo(timestampA);
              });

              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot document = documents[index];
                  Map<String, dynamic> recipe = document.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: SizedBox(
                      width: 80,
                      height: 80,
                      child: FutureBuilder<String>(
                        future: _downloadAndSaveImage(recipe['label']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                      ),
                    ),
                    title: Text(recipe['label']),
                    subtitle: Text('Source: ${recipe['source']}'),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == "delete") {
                          _showDeleteConfirmationDialog(context, () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('recipes')
                                .doc(document.id)
                                .delete();
                          });
                        }
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('recipes')
                          .doc(document.id)
                          .update({'opened': true});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailPage(
                            recipe: recipe,
                            showSaveButton: false,
                          ),
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
}


  void _showDeleteConfirmationDialog(
      BuildContext context, Function() onDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

