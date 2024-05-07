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

  SharedPrefService sharedPrefService = SharedPrefService();

  final imagePicker = ImagePicker();
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
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
            SnackBar(
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
          title: Text('Change Display Name'),
          content: TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              hintText: 'Enter your new display name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _displayName = _displayNameController.text;
                });
                await _changeProfile();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
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
                  // Tambahkan logika untuk menampilkan foto baru
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
            SizedBox(height: 20),
            Text(
              _displayName,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              _email,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'My point: $_point',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                _showPointChangeDialog(context);
              },
              child: Text(
                'Change Your Point',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _showChangeDisplayNameDialog(context);
              },
              child: Text(
                'Change Display Name',
                style: TextStyle(color: Colors.black),
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
              child: Text(
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
          title: Text("Change Your Point"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Nutrition Analysis"),
                onTap: () {
                  _selectNutritionAnalysis(context);
                },
              ),
              ListTile(
                title: Text("Book Recipes"),
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
              child: Text("Cancel"),
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
          title: Text("Book recipes"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("3 days"),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("7 days"),
                onTap: () {
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
              child: Text("Back"),
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
          title: Text("Nutrition Analysis"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("3 days"),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("7 days"),
                onTap: () {
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
              child: Text("Back"),
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
              title: Text('Confirm Sign Out'),
              content: Text('Are you sure you want to sign out?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Sign Out'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
