import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripInfoManager {

  Future<void> saveTripInfo(String tripCode) async {

    String tripCreator = '';
    String tripDate = '';
    String lastEdited = '';
    String tripName = '';
    List<dynamic> users = [];

    DocumentSnapshot snapshot =
    await FirebaseFirestore.instance.collection('trips').doc(tripCode).get();

    //Get All the data from Firebase
    tripCreator = snapshot.get('creator');
    tripDate = snapshot.get('date').toString();
    lastEdited = snapshot.get('lastEdited').toString();
    tripName = snapshot.get('tripName');
    users = snapshot.get('users');

    //Save everything into SharedPreference
    final prefs = await SharedPreferences.getInstance();

    List<String> usersStringList = users.map((item) => item.toString()).toList();

    await prefs.setString('tripCode', tripCode); //await
    await prefs.setString('tripCreator', tripCreator);
    await prefs.setString('tripDate', tripDate);
    await prefs.setString('lastEdited', lastEdited);
    await prefs.setString('tripName', tripName);
    await prefs.setStringList('userIDs', usersStringList);
  }

  Future<String?> getTripName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tripName');
  }

  Future<String?> getTripCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tripCode');
  }

  Future<String?> getTripDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('date');
  }

  Future<String?> getTripCreator() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('creator');
  }

  Future<List<String>?> getTripUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('users');
  }

  Future<void> clearTripInfo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('tripName');
    await prefs.remove('tripCode');
    await prefs.remove('date');
    await prefs.remove('creator');
    await prefs.remove('users');
  }

}