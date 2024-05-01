import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:tflite/tflite.dart';
import './food_recipes.dart';
import './scan_process.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'package:image_cropper/image_cropper.dart';

bool isLoading = false;

class Recognition extends StatefulWidget {
  const Recognition({super.key});

  @override
  State<Recognition> createState() => _RecognitionState();
}

class _RecognitionState extends State<Recognition> {
  File? imageFile;
  List? recognitions;
  final imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel();
    getFromCamera();
  }

  Future<void> uploadImageToFirebaseStorage(
      File imageFile, String imageId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('users/$userId/scan_images/$imageId.jpg');
        await ref.putFile(imageFile);
        String imageUrl = await ref.getDownloadURL();

        saveRecognitionResult(imageId, imageUrl, recognitions, Timestamp.now());
      } else {
        print("User is null, unable to upload image.");
      }
    } catch (e) {
      print("Failed to upload image: $e");
    }
  }

  void saveRecognitionResult(
      String imageId, String imageUrl, recognitions, Timestamp timestamp) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final recognitionRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final recipesCollectionRef = recognitionRef.collection('scan_name');

      recipesCollectionRef.doc(imageId).set({
        'image_url': imageUrl,
        'recognitions': recognitions,
        'timestamp': timestamp,
      }).then((_) {
        print('Recognition result saved to database');
        print(recognitions);
        setState(() {
          isLoading = false;
        });
      }).catchError((error) {
        print('Failed to save recognition result: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    width: size.width,
                    height: 250,
                    child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        color: Colors.blueGrey,
                        strokeWidth: 1,
                        dashPattern: const [5, 5],
                        child: SizedBox.expand(
                          child: FittedBox(
                            child: imageFile != null
                                ? Image.file(File(imageFile!.path),
                                    fit: BoxFit.cover)
                                : const Icon(
                                    Icons.image_outlined,
                                    color: Colors.blueGrey,
                                  ),
                          ),
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: size.width,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blueGrey),
                        child: Material(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              showPictureDialog();
                            },
                            child: const Center(
                              child: Text(
                                'Pick Image',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: size.width,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blueGrey),
                        child: Material(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                imageFile = null;
                                recognitions = null;
                              });
                            },
                            child: const Center(
                              child: Text(
                                'Clear Image',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: size.width,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.blueGrey),
                        child: Material(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              _processImage();
                            },
                            child: const Center(
                              child: Text(
                                'Process Image',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _processImage() {
    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      String imageId = DateTime.now().millisecondsSinceEpoch.toString();
      runModelOnImage(imageFile!).then((_) {
        uploadImageToFirebaseStorage(imageFile!, imageId);
        // uploadImageToFirebaseStorage(imageFile!, imageId).then((_) {
        // runModelOnImage(imageFile!);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("No Image Selected"),
            content: Text("Please select an image first."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _renderRecognitions() {
    return Column(
      children: recognitions!.map<Widget>((res) {
        final List<String> parts = res["label"].split(' ');
        final String namaLabel = parts.length > 1 ? parts[1] : '';
        print(namaLabel);
        final double confidence = res["confidence"] * 100;
        return Text(
          "$namaLabel: ${confidence.toStringAsFixed(2)}%",
          style: const TextStyle(fontSize: 20, color: Colors.black),
        );
      }).toList(),
    );
  }

  Future<void> showPictureDialog() async {
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Select Action'),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  getFromCamera();
                  Navigator.of(context).pop();
                },
                child: const Text('Open Camera'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  getFromGallery();
                  Navigator.of(context).pop();
                },
                child: const Text('Open Gallery'),
              ),
            ],
          );
        });
  }

 getFromGallery() async {
  final pickedFile = await imagePicker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1800,
    maxHeight: 1800,
  );
  if (pickedFile != null) {
    CroppedFile? croppedFile = await cropImage(File(pickedFile.path));
    if (croppedFile != null) {
      setState(() {
        imageFile = File(croppedFile.path);
      });
    }
  }
}

getFromCamera() async {
  final pickedFile = await imagePicker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1800,
    maxHeight: 1800,
  );
  if (pickedFile != null) {
    CroppedFile? croppedFile = await cropImage(File(pickedFile.path));
    if (croppedFile != null) {
      setState(() {
        imageFile = File(croppedFile.path);
      });
    }
  }
}

Future<CroppedFile?> cropImage(File imageFile) async {
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
    compressQuality: 100,
    maxWidth: 1800,
    maxHeight: 1800,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: Colors.blueGrey,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    ],
  );
  return croppedFile;
}


  Future loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/Models/model_unquant.tflite",
        labels: "assets/Models/labels.txt",
      );
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  runModelOnImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
    );
    setState(() {
      this.recognitions = recognitions;
      print(recognitions);
    });
    _showRecognitionDialog(recognitions);
  }

  void _showRecognitionDialog(List? recognitions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Recognition Result :", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (recognitions != null) _renderRecognitions(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (recognitions != null && recognitions.isNotEmpty) {
                    final String label = recognitions.first['label'];
                    final String foodDetails = _extractFoodName(label);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NutritionAnalysisPage2(foodDetails: foodDetails),
                      ),
                    );
                  }
                },
                child: Text('View Food Details', textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.center,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (recognitions != null && recognitions.isNotEmpty) {
                    final String label = recognitions.first['label'];
                    final String foodName = _extractFoodName(label);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipePage(foodName: foodName),
                      ),
                    );
                  }
                },
                child: Text('View Food Recipes', textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _extractFoodName(String label) {
    final List<String> parts = label.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    } else {
      return label;
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
