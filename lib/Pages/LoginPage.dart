import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget
{

  LoginScreen({Key key}) : super(key : key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;

  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async
  {
    this.setState(() {
      isLoggedIn = true;
    });
    preferences = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if(isLoggedIn)
    {
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: preferences.getString(""))));
    }

    this.setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.lightBlueAccent, Colors.purpleAccent],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Himo Chat",
              style: TextStyle(fontSize: 82.0, color: Colors.white, fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: controlSignIn,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 270.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/google_signin_button.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: isLoading ? circularProgress() : Container(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<Null> controlSignIn() async
  {
    preferences = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuthentication = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider
        .getCredential(idToken: googleAuthentication.idToken, accessToken: googleAuthentication.accessToken);

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

    //SignIn Success
    if(firebaseUser != null)
    {
      //Check if already SignUp
      final QuerySnapshot resultQuery = await Firestore.instance.collection("users")
          .where("id", isEqualTo: firebaseUser.uid).getDocuments();

      final List<DocumentSnapshot> documentSnapshots = resultQuery.documents;

      //Save Data to firestore - if new user
      if(documentSnapshots.length == 0)
      {
        Firestore.instance.collection("users").document(firebaseUser.uid).setData({
          "nickname" : firebaseUser.displayName,
          "photoUrl" : firebaseUser.photoUrl,
          "id" : firebaseUser.uid,
          "aboutMe" : "I am using Himo Chat app.",
          "createAt" : DateFormat("MMMM dd, yyyy HH:MM a").format(DateTime.now()).toString(),
//          "createAt" : DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith" : null,
        });

        //Write data to Local
        currentUser = firebaseUser;
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("nickname", currentUser.displayName);
        await preferences.setString("photoUrl", currentUser.photoUrl);
      }
      else
      {
        //Write data to Local
        currentUser = firebaseUser;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString("nickname", documentSnapshots[0]["nickname"]);
        await preferences.setString("photoUrl", documentSnapshots[0]["photoUrl"]);
        await preferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);
      }
      Fluttertoast.showToast(msg: "Congratulation, Sign in Successful");
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
    }
    //SignIn Not Success - SignIn Failed
    else
    {
        Fluttertoast.showToast(msg: "Try Again, Sign in Failed");
        this.setState(() {
          isLoading = false;
        });
    }
  }

}
