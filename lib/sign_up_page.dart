import 'package:flutter/material.dart';
import 'reusable_widget/reusable_widget.dart';
import 'package:grinv/sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

late String _displayName;

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _confirmPasswordTextController =
      TextEditingController();
  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.white, Colors.white,Colors.white, Colors.lightGreen],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(45),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/logoV.png',
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(
                    height: 20,
                  ),
                  reusTextField('Display Name', Icons.person, false,
                      _displayNameController),
                  const SizedBox(
                    height: 20,
                  ),
                  reusTextField(
                      'Email', Icons.email, false, _emailTextController),
                  const SizedBox(
                    height: 20,
                  ),
                  Stack(alignment: Alignment.centerRight, children: [
                    reusTextField('Password', Icons.lock, _isPasswordHidden,
                        _passwordTextController),
                    IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                  ]),
                  const SizedBox(
                    height: 20,
                  ),
                  Stack(alignment: Alignment.centerRight, children: [
                    reusTextField('Confirm Password', Icons.lock,
                        _isPasswordHidden, _confirmPasswordTextController),
                    IconButton(
                      icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                  ]),
                  const SizedBox(
                    height: 20,
                  ),
                  tombol(context, false, () {
                    if (_passwordTextController.text ==
                        _confirmPasswordTextController.text) {
                      FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _emailTextController.text,
                        password: _passwordTextController.text,
                      )
                          .then((value) async {
                        print('Created New Account');
                        await _changeProfile();

                        value.user?.sendEmailVerification().then((_) {
                          print('Verification email sent');
                        }).catchError((error) {
                          print('Failed to send verification email: $error');
                        });

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.perm_identity_outlined,
                                      color: Colors.green),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text("Sign Up Success")
                                ],
                              ),
                              content: const Text(
                                  "You have successfully created an account. Please verify your email."),
                              actions: [
                                ElevatedButton(
                                  child: const Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignInPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }).catchError((error) {
                        print('Error ${error.toString()}');
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Error"),
                            content: const Text("Passwords do not match."),
                            actions: [
                              ElevatedButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }),
                  signinoption()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(_displayNameController.text);

      setState(() {
        _displayName = _displayNameController.text;
        _displayName = user.displayName ?? '';
      });
    }
  }

  Row signinoption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?', style: TextStyle(color: Colors.black)),
        GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => const SignInPage()));
          },
          child: const Text(
            ' Sign In',
            style: TextStyle(
                color: Color.fromARGB(255, 19, 121, 255),
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
