import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserApi {

  addUser(String uid, String name, String imageURL, List tripCodes) async {
    final userData = await FirebaseFirestore.instance.collection('userData').doc(uid).get();
    if (!userData.exists) {
      // Save user data if the user is new
      FirebaseFirestore.instance.collection('userData').doc(uid).set({
        'name' : name,
        'imageURL' : imageURL,
        'tripCodes': FieldValue.arrayUnion(tripCodes),
      });
    }
  }

  String generateUID() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random.secure();
    return List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
  }

  //save userID into trip's users list
  addIntoTripsUserList(String tripCode, String uid) async {
    await FirebaseFirestore
        .instance
        .collection('trips')
        .doc(tripCode).update({
      'users': FieldValue.arrayUnion([uid])
    });
  }

}