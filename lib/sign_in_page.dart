import 'package:flutter/material.dart';
import 'reusable_widget/reusable_widget.dart';
import 'package:grinv/sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grinv/service/firebase_services.dart';
import 'open_bottom.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  Future writeCache({required String key, required String value}) async {
    print('write dulu');
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool isSaved = await pref.setString(key, value);
    debugPrint("PREF IS SAVED ${isSaved.toString()}");
  }

  Future<String?> readCache({required String key}) async {
    print('read dulu');
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? value = pref.getString(key);
    if (value != null) {
      return value;
    }
    return null;
  }

  Future<bool> removeCache({required String key}) async {
    print('removed dulu');
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool? isCleared = await pref.clear();
    debugPrint("PREF IS REMOVED ${isCleared.toString()}");
    return isCleared;
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  SharedPrefService sharedPrefService = SharedPrefService();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  showCustom(BuildContext context, User user) {
    FToast fToast = FToast();
    fToast.init(context);
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.green,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            Icons.check,
            color: Colors.white,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Welcome, Sign in as ${user.displayName} (${user.email})',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    fToast.showToast(
      child: toast,
      toastDuration: Duration(seconds: 3),
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.lightGreen,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(45),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/logoV.png',
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        reusTextField(
                            'Email', Icons.email, false, _emailTextController),
                        SizedBox(
                          height: 20,
                        ),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            reusTextField('Password', Icons.lock,
                                _isPasswordHidden, _passwordTextController),
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
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        forgotPassword(),
                        SizedBox(
                          height: 15,
                        ),
                        tombol(context, true, () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await Future.delayed(Duration(seconds: 2));
                          FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: _emailTextController.text,
                            password: _passwordTextController.text,
                          )
                              .then((value) {
                            if (value.user != null &&
                                value.user!.emailVerified) {
                              print('Login Success');
                              showCustom(context, value.user!);

                              sharedPrefService.writeCache(
                                  key: "email",
                                  value: _emailTextController.text);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OpenButtom(),
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Email Not Verified"),
                                    content: const Text(
                                        "Please verify your email to login."),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          User? user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user != null) {
                                            try {
                                              await user
                                                  .sendEmailVerification();
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        "Verification Email Sent"),
                                                    content: const Text(
                                                        "A verification email has been sent to your email address. Please check your inbox and verify your email."),
                                                    actions: [
                                                      ElevatedButton(
                                                        child: const Text("OK"),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            } catch (e) {
                                              print(
                                                  'Error sending verification email: $e');
                                            }
                                          }
                                        },
                                        child: const Text(
                                            'Send Verification Email'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }).catchError((error) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Error"),
                                  content: Text(
                                      'Wrong email or password.\nTry again please..'),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          }).whenComplete(() {
                            setState(() {
                              _isLoading = false;
                            });
                          });
                        }),
                        Text('Or sign in with'),
                        loginoption(context),
                        SizedBox(
                          height: 20,
                        ),
                        signupoption(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Container forgotPassword() {
    return Container(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () async {
          if (_emailTextController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Error"),
                  content: Text("Please enter your email."),
                  actions: <Widget>[
                    ElevatedButton(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: _emailTextController.text,
              );
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Reset Password"),
                    content: Text(
                      "Please check your email to proceed with the password reset process.",
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } catch (error) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Error"),
                    content: Text(error.toString()),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Container loginoption(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GestureDetector(
              onTap: () async {
                setState(() {
                  _isLoading = true;
                });
                FirebaseServices firebaseServices = FirebaseServices();
                bool success = await firebaseServices.signInWithGoogle();
                if (success) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    showCustom(context, user);
                    sharedPrefService.writeCache(
                        key: "email", value: _emailTextController.text);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OpenButtom()),
                    );
                  } else {
                    // Handle null
                  }
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage()),
                  );
                }
                setState(() {
                  _isLoading = false;
                });
              },
              child: 
              Image.asset(
                'assets/googleLogo.png',
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Row signupoption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Dont have account?', style: TextStyle(color: Colors.black)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SignUpPage()));
          },
          child: const Text(
            ' Sign Up',
            style: TextStyle(
                color: Color.fromARGB(255, 19, 121, 255),
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
