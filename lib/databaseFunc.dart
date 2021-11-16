
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/Provider/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

class MyUser {
  String? firststring;
  String? secondstring;

  MyUser(this.firststring, this.secondstring);

  MyUser.fromJson(Map<String, dynamic> m)
      : this(m['first_string'], m['second_string']);
}
/**

Future<MyUser> addUser(String firstName, int age) =>
    _firestore.collection('users')
        .add({
      'first_name': firstName,
      'age': age,
      'created_at': Timestamp.now()
    })
        .then((docReference) => docReference.get())
        .then((snapshot) => MyUser.fromJson({ 'id': snapshot.id, ...?snapshot?.data() }));
    */



Future<void> _updateUserOccupation(String userId, String newOccupation) {
  return _firestore
      .collection('users')
      .doc(userId)
      .update({'occupation': newOccupation});
}

Future<DocumentSnapshot> _getUser(String documentId) {
  return _firestore.collection('users').doc(documentId).get();
}

Future<List<QueryDocumentSnapshot>> _getAllUsers() {
  return _firestore.collection('users').get().then(
          (value) => value.docs); // Map the query result to the list of documents
}


List fromSetToList(Set<WordPair> saved){
  List list = [];
  saved.forEach((x) {
    list.add({'first': x.first, 'second': x.second});
  });
  return list;
}

void updateItems(Set<WordPair> saved) async {
  final authRep = AuthRepository.instance();
  final user = FirebaseAuth.instance.currentUser;
    if (user != null && authRep.isAuthenticated ) {
      try {
        FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get()
            .then((snapshot) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.docs.first.id)
              .update({'WordPairs': fromSetToList(saved)});
        });
      }
      catch (e){

      }
    }

  }
