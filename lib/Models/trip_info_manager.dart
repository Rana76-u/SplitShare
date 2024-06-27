import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../API/user_api.dart';
import 'Hive/User/hive_user_model.dart';

class TripInfoManager {

  Future<void> loadAndSaveTripInfo(String tripCode) async {

    DocumentSnapshot snapshot =
    await FirebaseFirestore.instance.collection('trips').doc(tripCode).get();

    //Get All the data from Firebase
    List userIDs = await snapshot.get('users');
    List userNames = await UserApi().getUserNames(userIDs);
    List userImageUrls = await UserApi().getUserImageUrls(userIDs);

    //Save Trip Info
    var box = Hive.box('tripInfo');
    box.put('tripCreator', snapshot.get('creator'));
    box.put('tripDate', snapshot.get('date').toString());
    box.put('tripName', snapshot.get('tripName'));

    //Save UserInfo
    for(int i=0; i<userIDs.length; i++){
      UserClass userClass = UserClass(
          uid: userIDs[i],
          name: userNames[i],
          imageUrl: userImageUrls[i]
      );

      final box = Hive.box<UserClass>('users');
      box.put(userClass.uid, userClass);
    }
  }

  Future<String> getTripName() async {
    final box = Hive.box('tripInfo');
    return box.get('tripName');
  }

  Future<String> getTripCode() async {
    final box = Hive.box('tripInfo');
    return box.get('tripCode');
  }

  Future<String> getTripDate() async {
    final box = Hive.box('tripInfo');
    return box.get('tripDate');
  }

  Future<String> getTripCreator() async {
    final box = Hive.box('tripInfo');
    return box.get('tripCreator');
  }

  Future<List<String>> getTripUserIDs() async {
    final box = Hive.box<UserClass>('users');
    return box.keys.cast<String>().toList();
  }

  Future<List<String>> getUserNames() async {
    final box = Hive.box<UserClass>('users');
    return box.values.map((user) => user.name).toList();
  }

  Future<List<String>> getUserImageUrls() async {
    final box = Hive.box<UserClass>('users');
    return box.values.map((user) => user.imageUrl).toList();
  }



/*  Future<void> clearTripInfo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('tripName');
    await prefs.remove('tripCode');
    await prefs.remove('date');
    await prefs.remove('creator');
    await prefs.remove('users');
  }*/

}