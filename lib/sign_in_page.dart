import 'package:flutter/material.dart';
import 'reusable_widget/reusable_widget.dart';
import 'package:Becipes/sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Becipes/service/firebase_services.dart';
import 'open_bottom.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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
          Icon(Icons.check, color: Colors.white,),
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
                    Color.fromARGB(255, 123, 213, 255)
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
                        Image.asset('assets/BeCipesLogo.png'),
                        Text(
                          'Sign In',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
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
                        forgotpassword(),
                        SizedBox(
                          height: 15,
                        ),
                        tombol(context, true, () async {
                          setState(() {
                            _isLoading = true;
                          });
                          await Future.delayed(Duration(
                              seconds: 2)); // Menahan proses selama 2 detik
                          FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: _emailTextController.text,
                            password: _passwordTextController.text,
                          )
                              .then((value) {
                            if (value.user != null &&
                                value.user!.emailVerified) {
                              // Sign in berhasil
                              print('Login Success');
                              showCustom(context, value.user!);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OpenButtom(),
                                ),
                              );
                            } else {
                              // Email belum diverifikasi
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
                                      'UDAH SIGN UP BELOM!, MASUKIN DATA YANG BENER, TYPO MUNGKIN'),
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
                        signupoption(),
                        loginoption(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Container forgotpassword() {
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
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(email: _emailTextController.text);
            }
          },
          child: Text(
            'forgot password?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ));
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OpenButtom()),
                    );
                  } else {
                    // Handle error ketika user null
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
              child: Image.asset(
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
