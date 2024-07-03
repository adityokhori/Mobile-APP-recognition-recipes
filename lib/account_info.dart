import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grinv/service/firebase_services.dart';
import 'package:grinv/sign_in_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  late String _displayName = '';
  late String _email = '';
  late String _point = '';
  late String _photoURL = '';
  int optionAnalysisDays = 0;
  int optionRecipesDays = 0;

  SharedPrefService sharedPrefService = SharedPrefService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final imagePicker = ImagePicker();
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _updateFirebaseAttribute(String option, bool value) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int incrementDays = 0;
        String optionKey = ''; // Untuk menyimpan kunci opsi yang akan diupdate
        String firstActiveKey =
            ''; // Untuk menyimpan kunci timestamp pertama kali aktif
        int pointDeduction = 0;

        if (option.startsWith('optionAnalysis')) {
          String daysString = option.split(' ')[1];
          incrementDays = int.parse(daysString);
          optionKey =
              'optionAnalysis'; // Menggunakan kunci yang sama untuk semua opsi analisis
          firstActiveKey = 'optionAnalysisFirstActive';
          optionAnalysisDays += incrementDays;
          pointDeduction = incrementDays == 3 ? 50 : 100;
        } else if (option.startsWith('optionRecipes')) {
          String daysString = option.split(' ')[1];
          incrementDays = int.parse(daysString);
          optionKey =
              'optionRecipes'; // Menggunakan kunci yang sama untuk semua opsi resep
          firstActiveKey = 'optionRecipesFirstActive';
          optionRecipesDays += incrementDays;
          pointDeduction = incrementDays == 3 ? 50 : 100;
        }

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        int currentPoints =
            (userDoc.data() as Map<String, dynamic>)['point_quiz'] ?? 0;

        if (currentPoints >= pointDeduction) {
          Map<String, dynamic> updateData = {
            optionKey: value,
            'point_quiz': currentPoints - pointDeduction,
          };

          if (!(await _checkAttributeExists(user.uid, firstActiveKey))) {
            updateData[firstActiveKey] = DateTime.now().millisecondsSinceEpoch;
          }

          if (optionKey == 'optionAnalysis') {
            updateData['optionAnalysisDays'] = optionAnalysisDays;
          } else if (optionKey == 'optionRecipes') {
            updateData['optionRecipesDays'] = optionRecipesDays;
          }

          await _firestore.collection('users').doc(user.uid).update(updateData);
          setState(() {
            _point = (currentPoints - pointDeduction).toString();
          });

          print('Berhasil memperbarui nilai $option di Firestore.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not enough points to choose this option.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Gagal memperbarui nilai $option di Firestore: $e');
    }
  }

  Future<bool> _checkAttributeExists(
      String userId, String attributeName) async {
    final userData = await _firestore.collection('users').doc(userId).get();
    return userData.exists && userData.data()!.containsKey(attributeName);
  }

  void _onOptionSelected(String option) async {
    if (option == 'optionAnalysis 3 Days' ||
        option == 'optionAnalysis 7 Days') {
      await _updateFirebaseAttribute(option, true);
    } else if (option == 'optionRecipes 3 Days' ||
        option == 'optionRecipes 7 Days') {
      await _updateFirebaseAttribute(option, true);
    }
  }

  void _getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      var pointQuiz =
          (userDoc.data() as Map<String, dynamic>)['point_quiz'] ?? 0;

      setState(() {
        _displayName = user.displayName ?? '';
        _email = user.email ?? '';
        _photoURL = user.photoURL ?? '';
        _point = pointQuiz.toString();
      });
    }
  }

  Future<bool> _checkStorageConnection() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('USER TELAH AUTENTIKASI $_displayName'); //SUDAH JALAN
      }
      print('Mencoba mengakses Firebase Storage...'); //SUDAH JALAN
      return true;
    } catch (e) {
      print('Koneksi Firebase Storage GAGAL: $e');
      return false;
    }
  }

  Future<void> _changeProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(_displayNameController.text);

      setState(() {
        _displayName = _displayNameController.text;
      });
    }
  }

  Future<File?> _pickAndUploadImage() async {
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool isConnected = await _checkStorageConnection();
        if (!isConnected) {
          print('Tidak terhubung ke Firebase Storage');
          return null;
        }

        File imageFile = File(image.path);
        String userId = user.uid;

        final Reference ref = FirebaseStorage.instance
            .ref()
            .child('users/$userId/profile_images/$imageFile');

        print(ref);
        print('INTANCE SUKSES');

        try {
          print('UNGGAH');
          await ref.putFile(imageFile);
          String photoURL = await ref.getDownloadURL();
          await user.updatePhotoURL(photoURL);
          setState(() {
            _photoURL = photoURL;
            print('BERHASIL MEMPERBARUI STATE');
          });
          print('Gambar berhasil diunggah dan URL foto profil diperbarui');
          return imageFile;
        } catch (e) {
          print('Kesalahan: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah atau memperbarui foto profil.'),
            ),
          );
          return null;
        }
      } else {
        print('Pengguna belum masuk');
        return null;
      }
    }
    return null;
  }

  Future<void> _showChangeDisplayNameDialog(BuildContext context) async {
    _displayNameController.text = _displayName;
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Display Name'),
          content: TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              hintText: 'Enter your new display name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _displayName = _displayNameController.text;
                });
                await _changeProfile();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                File? image = await _pickAndUploadImage();
                if (image != null) {
                  _photoURL = image.path;
                }
              },
              child: CircleAvatar(
                backgroundImage:
                    _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
                child: _photoURL.isEmpty
                    ? Icon(Icons.account_circle, size: 100)
                    : null,
                radius: 100,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _displayName,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              _email,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Your Point: ',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  TextSpan(
                    text: '$_point',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                _showPointChangeDialog(context);
              },
              child: const Text(
                'Change Your Point',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _showChangeDisplayNameDialog(context);
              },
              child: const Text(
                'Change Display Name',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                bool confirmSignOut =
                    await _showSignOutConfirmationDialog(context);
                if (confirmSignOut) {
                  await FirebaseServices().signOut();
                  bool isRemoved =
                      await sharedPrefService.removeCache(key: "email");
                  if (isRemoved) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignInPage()),
                    );
                  }
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Change Your Point"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Nutrition Analysis"),
                onTap: () {
                  _selectNutritionAnalysis(context);
                },
              ),
              ListTile(
                title: const Text("Book Recipes"),
                onTap: () {
                  _selectBookRecipes(context);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _selectBookRecipes(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Book recipes"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("3 Days (50 point)"),
                onTap: () {
                  _onOptionSelected('optionRecipes 3 Days');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("7 Days (100 point)"),
                onTap: () {
                  _onOptionSelected('optionRecipes 7 Days');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Back"),
            ),
          ],
        );
      },
    );
  }

  void _selectNutritionAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Nutrition Analysis"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("3 Days (50 point)"),
                onTap: () {
                  _onOptionSelected('optionAnalysis 3 Days');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("7 Days (100 point)"),
                onTap: () {
                  _onOptionSelected('optionAnalysis 7 Days');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Back"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showSignOutConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
