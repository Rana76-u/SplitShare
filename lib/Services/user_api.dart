import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserApi {

  String generateUID() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random.secure();
    return List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
  }

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

  //save userID into trip's users list
  addIntoTripsUserList(String tripCode, String uid) async {
    await FirebaseFirestore
        .instance
        .collection('trips')
        .doc(tripCode).update({
      'users': FieldValue.arrayUnion([uid])
    });
  }

  Future<List> getUserNames(List userIds) async {
    List tempUserNames = [];

    for (int i = 0; i < userIds.length; i++) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('userData')
          .doc(userIds[i])
          .get();

      tempUserNames.add(userSnapshot.get('name'));
    }

    return tempUserNames;
  }

  Future<List> getUserImageUrls(List userIds) async {
    List tempImageUrls = [];

    for (int i = 0; i < userIds.length; i++) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('userData')
          .doc(userIds[i])
          .get();

      tempImageUrls.add(userSnapshot.get('imageURL'));
    }

    return tempImageUrls;
  }

}