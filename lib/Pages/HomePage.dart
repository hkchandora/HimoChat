import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telegramchatapp/Pages/ChattingPage.dart';
import 'package:telegramchatapp/main.dart';
import 'package:telegramchatapp/models/user.dart';
import 'package:telegramchatapp/Pages/AccountSettingsPage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';


class HomeScreen extends StatefulWidget {
  
  final String currentUserId;
  
  HomeScreen({Key key, @required this.currentUserId}) : super(key: key);
  
  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> {

  HomeScreenState({Key key, @required this.currentUserId});

  TextEditingController searchTextEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResults;

  final String currentUserId;

  homePageHeader()
  {
    return AppBar(
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.settings, size: 30.0, color: Colors.white,),
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
          },
        ),
      ],
      backgroundColor: Colors.lightBlue,
      title: Container(
        margin: new EdgeInsets.only(bottom: 4.0),
        child: TextFormField(
          style: TextStyle(fontSize: 18.0, color: Colors.white),
          controller: searchTextEditingController,
          decoration: InputDecoration(
            hintText: "Search here...",
            hintStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            filled: true,
            prefixIcon: Icon(Icons.person_pin, color: Colors.white, size: 30.0,),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.white,),
              onPressed: emptyTextFormField,
            ),
          ),
          onFieldSubmitted: controlSearching,
        ),
      ),
    );
  }


  controlSearching(String userName)
  {
    Future<QuerySnapshot> allFoundUsers = Firestore.instance.collection("users")
        .where("nickname", isGreaterThanOrEqualTo: userName).getDocuments();

    setState(() {
      futureSearchResults = allFoundUsers;
    });

  }

  emptyTextFormField()
  {
    searchTextEditingController.clear();
  }


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
    appBar: homePageHeader(),
      body: futureSearchResults == null ? displayNoSearchResultScreen() : displayTheUserFoundScreen(),
    );
  }

  displayTheUserFoundScreen()
  {
    return FutureBuilder(
      future: futureSearchResults,
      builder: (context, dataSnapshot)
      {
        if(!dataSnapshot.hasData)
          {
            return circularProgress();
          }

        List<UserResult> searchUserResult = [];
        dataSnapshot.data.documents.forEach((document)
        {
          User eachUser = User.fromDocument(document);
          UserResult userResult = UserResult(eachUser);

          if(currentUserId != document["id"])
          {
           searchUserResult.add(userResult);
          }
        });
        return ListView(children: searchUserResult);
      },
    );
  }


  displayNoSearchResultScreen()
  {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Icon(Icons.group, color: Colors.lightBlueAccent, size: 200.0,),
            Text(
              "Search Users",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 50.0, fontWeight: FontWeight.w500,),
            ),
          ],
        ),
      ),
    );
  }
}



class UserResult extends StatelessWidget
{

  final User eachUser;
  UserResult(this.eachUser);


  @override
  Widget build(BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: ()=> sendUserToChatPage(context),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: CachedNetworkImageProvider(eachUser.photoUrl),
                ),
                title: Text(
                  eachUser.nickname,
                  style: TextStyle(
                    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "About Me : "+ eachUser.aboutMe.toString(),
//                      + DateFormat("dd MMMM, yyyy - hh:mm aa")
//                  .format(DateTime.fromMillisecondsSinceEpoch(int.parse(eachUser.createdAt))),
                  style: TextStyle(color: Colors.grey, fontSize: 14.0, fontStyle: FontStyle.italic,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  sendUserToChatPage(BuildContext context)
  {
    Navigator.push(context, MaterialPageRoute
      (
        builder: (context) => Chat
          (
            receiverId: eachUser.id,
            receiverAvatar: eachUser.photoUrl,
            receiverName: eachUser.nickname
        )));
  }

}
