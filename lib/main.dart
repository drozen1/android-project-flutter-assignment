// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/Provider/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/databaseFunc.dart';
import 'package:flutter/material.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';


//void main() => runApp(MyApp());


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //runApp(App());
  runApp(ChangeNotifierProvider(
      create: (context) => AuthRepository.instance(),
      builder: (context, snapshot) {
        return App();
      }));
}


class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}


// #docregion MyApp
class MyApp extends StatelessWidget {
  // #docregion build
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: RandomWords(),
    );
  }
// #enddocregion build
}
// #enddocregion MyApp

// #docregion RWS-var

class RandomWords extends StatefulWidget {
  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  // final _suggestions =  generateWordPairs().take(10).toList();
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};

  StreamController<String> controller = StreamController.broadcast();

  // #enddocregion RWS-var

  // #docregion _buildSuggestions
  Widget _buildSuggestions() {
   // print("_buildSuggestions");
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(AuthRepository.instance().user?.uid)
            .collection('WordPairs')
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

        if (AuthRepository.instance().isAuthenticated) {
          return Scaffold(
            body: mySnapSheet(_suggestions, _saved),
          );
        }
          return suggestionWidget(_suggestions, _saved, null);


      }
    );
  }

  // #enddocregion _buildSuggestions

  //


  //

  // #docregion RWS-build
  @override
  Widget build(BuildContext context) {
    //print("_RandomWordsState build");

    return Consumer<AuthRepository>(
      builder: (context, authRep, snapshot) {
        return Scaffold(

          appBar: AppBar(

            actions: _setActions(authRep),
            title: const Text('Startup Name Generator'),
          ),
          body: _buildSuggestions(),
        );
      },
    );
  }

  // #enddocregion RWS-build

  List<IconButton> _setActions(authRep){
    if (!authRep.isAuthenticated){
      return [
        IconButton(
          icon: const Icon(Icons.star),
          onPressed: () => _pushSaved(context, controller, _saved),
          tooltip: 'Saved Suggestions',
        ),
        IconButton(
          icon: const Icon(Icons.login),
          onPressed: () {
            _pushLogin(context, _saved);
          },
        )

      ];
    }
    List cloud_words = [];
    //print(cloud_words);
    cloud_words.forEach((element) {
      _saved.add(element);
    });
    updateItems(_saved);

    return [
      IconButton(
        icon: const Icon(Icons.star),
        onPressed: () => _pushSaved(context, controller, _saved),
        tooltip: 'Saved Suggestions',
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: () {
          signOut();
        },
      )];
  }

  void setParentState(){
    setState(() {

    });
  }

  void _pushSaved(BuildContext context, StreamController controller, Set<WordPair> saved) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {


          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            //body: ListView(children: divided),
            body:
            ListViewWidget(_saved, setParentState),
            //StreamBuilder(

          );
        },

      ),
    );
  }

  Future<void> signOut() async {
    final snackBar = SnackBar(
        content: Text('Successfully logged out'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await AuthRepository.instance().signOut();
    setState( ()  {});
    _saved.clear();
  }

  void _pushLogin(BuildContext context, Set<WordPair> saved) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Login'),
              centerTitle: true,
            ),
            body: LoginWidget(_saved, setParentState),
          );
        },
      ),
    );
  }

// #docregion RWS-var
}

class suggestionWidget extends StatefulWidget {
  var _suggestions = <WordPair>[];
  var _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18.0);
  var snapController;
  //
  // var suggestions = <WordPair>[];
  // var saved = <WordPair>{};

  suggestionWidget(this._suggestions,this._saved, this.snapController);

  @override
  _suggestionWidgetState createState() => _suggestionWidgetState();
}

class _suggestionWidgetState extends State<suggestionWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      //itemCount: _suggestions.length,
      itemBuilder: /*1*/ (context, i) {
        if (i.isOdd) return const Divider();
        /*2*/

        final index = i ~/ 2; /*3*/
        if (index >= widget._suggestions.length) {
          widget._suggestions.addAll(generateWordPairs().take(10)); /*4*/
        }
        return _buildRow(widget._suggestions[index]);
      },

    );
  }

  Widget _buildRow(WordPair pair)
  {
    //print("_buildRow");

    final alreadySaved = widget._saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: widget._biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            widget._saved.remove(pair);
          } else {
            widget._saved.add(pair);
          }
          if (AuthRepository.instance().isAuthenticated){
            updateItems(widget._saved);
          }
        });
      },
    );
  }
}


class LoginWidget extends StatefulWidget {


  Set<WordPair> _saved;
  final Function() SetFatherState;
  LoginWidget(this._saved, this.SetFatherState);
  @override
  State<LoginWidget> createState() => LoginWidgetState(this._saved, this.SetFatherState);

}

class LoginWidgetState extends State<LoginWidget> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final bottompasswordController = TextEditingController();
  final errorSnakeBar = SnackBar(
    content: Text('There was an error logging into the app'),
  );
  Set<WordPair> _saved;
  final Function() SetFatherState;
  LoginWidgetState(this._saved, this.SetFatherState);


  @override
  Widget build(BuildContext context) {
    //print("LoginWidget build");

    return Padding(
      padding: EdgeInsets.all(10),
      child: ListView(

        children: <Widget>[
          Container(
            // alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Text(
                'Welcome to Startup Names Generator, please log in below',
              )),
          Container(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
          ),
          Container(
            // padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: TextField(
               obscureText: true,
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
          ),

          //
          //  padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
          Text(
            '',
            style: TextStyle(height: 2, fontSize: 10),
          ),
          Consumer<AuthRepository> (builder: (context, authRep, snapshot) {
            //print("SetFatherState()");

            // SetFatherState();
            bool isAuthenticating = false;
            String text = "Log in";
            if (authRep.status == Status.Authenticating) {
              isAuthenticating = true;
            }
            return RaisedButton(

              textColor: Colors.white,
              color: Colors.deepPurple,
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0),
              ),
              padding: EdgeInsets.fromLTRB(10, 15, 10, 15),

              child: Text(text),
              onPressed: ()   {
                if (!isAuthenticating) {
                  authRep.signIn(nameController.text, passwordController.text).then((value)=> authRep.isAuthenticated ?
                  auxAuthenticated(context, authRep) : ScaffoldMessenger.of(context).showSnackBar(errorSnakeBar));
                  setState(() {
                  });


                } else {
                  return;
                }
              },
            );
          }),
          Text(
            '',
            style: TextStyle(height: 1, fontSize: 10),
          ),
          Consumer<AuthRepository> (builder: (context, authRep, snapshot) {
            //print("SetFatherState()");

            // SetFatherState();
            bool isAuthenticating = false;
            String text = "New user? Click to sign up";
            if (authRep.status == Status.Authenticating) {
              isAuthenticating = true;
            }
            return RaisedButton(
              padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
              textColor: Colors.white,
              color: Colors.blueAccent,
              shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0),
              ),

              child: Text(text),
              onPressed: ()   {

                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Center(
                                    child:
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('Please confirm your password below:', style: TextStyle(fontSize: 16)),
                                    )),
                                Divider(),
                                Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: TextField(
                                    obscureText: true,
                                    // obscureText: true,
                                    controller: bottompasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                    ),
                                  ),
                                ),
                                Divider(),
                                RaisedButton(

                                  textColor: Colors.white,
                                  color: Colors.blueAccent,
                                  // shape: new RoundedRectangleBorder(
                                  // borderRadius: new BorderRadius.circular(30.0),
                                  // ),
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),

                                  child: Text("Confirm"),
                                  onPressed: ()   async {

                                    if (this.nameController.text != "" && this.bottompasswordController.text ==this.passwordController.text){
                                      UserCredential new_user = (await authRep.signUp(this.nameController.text, this.bottompasswordController.text))!;
                                      FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(new_user.user!.uid)
                                          .set({"email": nameController, "WordPairs": {}});
                                      auxAuthenticated(context,authRep);
                                      Navigator.of(context).pop();
                                    }else{
                                      final errorSnakeBar = SnackBar(
                                        content: Text('Passwords must match'),
                                      );
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(errorSnakeBar);
                                    }
                                  },
                                ),
                                Text(""),
                              ],
                            ),
                          ));
                    });
              },
            );
          })

        ],
      ),
    );

  }

  void auxAuthenticated(BuildContext context, AuthRepository authRep) {


    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var currUser = FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email);

      currUser.get().then((snapshot) {
        snapshot.docs.forEach((element) async {
          List cloudWordPairs = await element.data()["WordPairs"];
          for (int i = 0; i < cloudWordPairs.length; i++) {
            widget._saved.add(WordPair(cloudWordPairs[i]['first'], cloudWordPairs[i]['second']));
          }
          updateItems(widget._saved);
          //setState(() {
         // });
        });
      });
    }
    Navigator.of(context).pop();
    return;
  }


}

class ListViewWidget extends StatefulWidget {

  Set<WordPair> _saved;
  final Function() SetFatherState;
  ListViewWidget(this._saved, this.SetFatherState);
  @override
  _ListViewWidgetState createState() => _ListViewWidgetState();
}

class _ListViewWidgetState extends State<ListViewWidget> {
  @override
  Widget build(BuildContext context) {

    //add
    final tiles = widget._saved.map(
          (pair) {
        return ListTile(
          title: Text(
            pair.asPascalCase,
            style: const TextStyle(fontSize: 18.0),
          ),
        );
      },
    );
    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList()
        : <Widget>[];


    return ListView.builder(
      itemCount: divided.length,
      itemBuilder: (context, index) {
        final item = divided[0];
        return Dismissible(
          // Each Dismissible must contain a Key. Keys allow Flutter to
          // uniquely identify widgets.
          key: ValueKey<Widget>(divided[index]),
          // Provide a function that tells the app
          // what to do after an item has been swiped away.

          // Show a red background as the item is swiped away.
          background: Container(
            color: Colors.red,
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(Icons.delete, color: Colors.white),

                  ),
                  TextSpan(
                      text: 'Delete Suggestion',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16)
                  ),
                ],
              ),
            ),
            alignment: Alignment(-1.0, -0.0),
          ),

          confirmDismiss:  (direction) async  {
            // final snackBar = SnackBar(
            //     content: Text('Deletion is not implemented yet'));
            // ScaffoldMessenger.of(context).showSnackBar(snackBar);
            // return Future<bool>.value(false);
            return await showDialog(
              context: context,
              builder: (BuildContext context) {

                return AlertDialog(
                  title: const Text("Delete Suggestion"),
                  actions: <Widget>[
                    FlatButton(
                        onPressed: () {
                         // print("start_debugging");
                         // print(index);
                         // print(widget._saved);
                         // print(divided[index].key);
                          Navigator.of(context).pop(true);
                          //print(widget._saved.elementAt(index));
                          widget._saved.remove(widget._saved.elementAt(index));
                          //divided.removeAt(index);
                         // print(widget._saved);
                          updateItems(widget._saved);
                          setState(() {});
                          widget.SetFatherState();
                        },
                        child: const Text("Yes")
                    ),
                    FlatButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("No"),
                    ),
                  ],
                  content: Text("Are you sure you wish to delete " + widget._saved.elementAt(index).asPascalCase+
                      " from your saved suggestion?"),
                );
              },
            );
          },
          child: divided[index],
        );
      },
    );
  }
}

class mySnapSheet extends StatefulWidget {
  // const mySnapSheet({Key? key}) : super(key: key);
  var _suggestions = <WordPair>[];
  var _saved = <WordPair>{};

  //
  // var suggestions = <WordPair>[];
  // var saved = <WordPair>{};

  mySnapSheet(this._suggestions,this._saved);


  @override
  _mySnapSheetState createState() => _mySnapSheetState();
}

class _mySnapSheetState extends State<mySnapSheet> {
  final snappingSheetController = SnappingSheetController();
  @override
  Widget build(BuildContext context) {
    return SnappingSheet(
        child: suggestionWidget(widget._suggestions, widget._saved, snappingSheetController),
        controller: snappingSheetController,
        grabbing: grabbingWidget(snappingSheetController),
        initialSnappingPosition: SnappingPosition.pixels(positionPixels: 30),
        snappingPositions: [
          SnappingPosition.pixels(positionPixels: 30),
          SnappingPosition.pixels(positionPixels: 160)
        ],
      //snappingPosition.pixels(positionPixels: 30),
        grabbingHeight: 75,

        sheetBelow: SnappingSheetContent(
          draggable: true,

          child: whiteSheet(),

        ),
      );

  }
}

class grabbingWidget extends StatefulWidget {
  var snappingSheetController;
  grabbingWidget(this.snappingSheetController);

  @override
  _grabbingWidgetState createState() => _grabbingWidgetState();
}

class _grabbingWidgetState extends State<grabbingWidget> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String grab_text="";
    if (user != null) {
      grab_text = "Welcome back, " + user.email!;
    }
    return GestureDetector(
      onTap: () {
        if (widget.snappingSheetController.currentPosition == 30) {
          widget.snappingSheetController.snapToPosition(
            SnappingPosition.pixels(positionPixels: 160),
          );
        } else {
          widget.snappingSheetController.snapToPosition(
            SnappingPosition.pixels(positionPixels: 30),
          );
        }
      },
    //  child: BackdropFilter(
       // filter: ImageFilter.blur(sigmaX: xBlurVal, sigmaY: yBlurVal),
        child: Container(
            color: Colors.grey[400],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 0, 10),
                  child: Text(grab_text, style: TextStyle(fontSize: 15)),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Icons.keyboard_arrow_up),
                )
              ],
            )),
    //  ),
    );
  }
}



class whiteSheet extends StatefulWidget {

  @override
  _whiteSheetState createState() => _whiteSheetState();
}

class _whiteSheetState extends State<whiteSheet> {

  String image_url = "";
  final myUser = FirebaseAuth.instance.currentUser;

   final storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    image_url = "";
      storage.ref().child("userAvatars/" + myUser!.uid).
      getDownloadURL().then(exist, onError: notExist);
    }

    Widget build(BuildContext context) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 10, 10),
          child: Row(
            children: [
              (image_url != "")
                  ? CircleAvatar(
                maxRadius: 45,
                backgroundImage: NetworkImage(image_url),
                backgroundColor: Colors.grey[350],
              )
                  : CircleAvatar(
                maxRadius: 45,
                backgroundColor: Colors.grey[350],
              ),
              SizedBox(
                width: 10,
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(myUser!.email!, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    ElevatedButton(
                        child: Text("Change Avatar"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                          minimumSize: MaterialStateProperty.all<Size>(
                              Size(124, 23)),
                        ),
                        onPressed: () => updatePhoto()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  updatePhoto() async {

    final _picker = ImagePicker();
    // PickedFile? image;
    XFile? image;
    await Permission.photos.request();
    var permissionStatus = await Permission.photos.status;
    if (permissionStatus.isGranted) {
      image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
      //  uploadImageToFirebase(image.path);
        var file = File(image.path);
        TaskSnapshot uploadTask = await storage
            .ref()
            .child("userAvatars/" + myUser!.uid)
            .putFile(file);
        String url = await uploadTask.ref.getDownloadURL();
        setState(() {
          image_url = url;
        });

      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No image selected')));
      }
    }
  }

  exist(String url) {
    image_url = url;
    setState(() {});
  }
//
  notExist(error) async {
    final ref = storage.ref().child("userAvatars/defaultAvatar.jpeg");
    image_url = await ref.getDownloadURL();
    setState(() {});
  }

}

class pickDialog extends StatefulWidget {
  const pickDialog({Key? key}) : super(key: key);

  @override
  _pickDialogState createState() => _pickDialogState();
}

class _pickDialogState extends State<pickDialog> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}







