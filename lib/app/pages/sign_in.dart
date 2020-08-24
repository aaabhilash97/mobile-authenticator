import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

var logger = Logger();

class SignIn extends StatefulWidget {
  @override
  SignInState createState() {
    return SignInState();
  }
}

Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // Create a new credential
  final GoogleAuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

class SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   iconTheme: IconThemeData(
      //     color: Theme.of(context).appBarTheme.color,
      //   ),
      //   elevation: 0,
      //   backgroundColor: Colors.transparent,
      //   title: Text(
      //     "Add account details",
      //     style: TextStyle(
      //       color: Theme.of(context).appBarTheme.color,
      //     ),
      //   ),
      // ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width - 100,
          padding: EdgeInsets.all(10),
          child: RaisedButton(
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/organization_icons/google.png',
                    scale: 1.5,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 30),
                    child: Text("Signin with google"),
                  )
                ],
              ),
              onPressed: () async {
                await signInWithGoogle();
                Navigator.of(context).pop();
              }),
        ),
      ),
    );
  }
}
