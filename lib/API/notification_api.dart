import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationApi {
  void getToken() async {
    await FirebaseMessaging.instance.getToken().then(
            (token) {
          saveTokenInFirebase(token!);
        }
    );
  }
  void saveTokenInFirebase(String token) async {
    await FirebaseFirestore.instance.collection('userTokens')
        .doc(FirebaseAuth.instance.currentUser!.uid).set({
      'token': token,
    });
  }
}