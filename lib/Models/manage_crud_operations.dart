import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Widgets/bottom_nav_bar.dart';

class ManageCRUDOperations {

  List<String> titles = [];
  List<String> descriptions = [];
  List<String> amounts = [];
  List<String> times = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];
  List<String> docIDs = [];
  List<String> isChanged = [];

  Future<void> uploadInfo (
      String title,
      String description,
      double amount,
      String providerID,
      String providerName,
      String? docID,
      String tripCode,
      ) async {

    //if internet is connected
    if(await InternetConnectionChecker().hasConnection){
     if(docID != 'new'){
       await FirebaseFirestore
           .instance
           .collection('trips')
           .doc(tripCode)
           .collection('Events')
           .doc(docID)
           .update({
         'title': title,
         'description': description,
         'amount': amount,
         'providedBy': providerID,
       });
     }
     else{
       await FirebaseFirestore
           .instance
           .collection('trips')
           .doc(tripCode)
           .collection('Events')
           .doc()
           .set({
         'title': title,
         'description': description,
         'amount': amount,
         'time': DateTime.now(),
         'addedBy': FirebaseAuth.instance.currentUser!.uid,
         'providedBy': providerID,
       });
     }

     //Send Notification
    }

    //if internet is not connected
    else{
      //Call Locally Saved Data
      final prefs = await SharedPreferences.getInstance();

      //Transfer Them into Lists
      if(prefs.containsKey('titles')){
        titles = prefs.getStringList('titles')!;
        descriptions = prefs.getStringList('descriptions')!;
        amounts = prefs.getStringList('amounts')!;
        times = prefs.getStringList('times')!;
        providerNames = prefs.getStringList('providerNames')!;
        providerIDs = prefs.getStringList('providerIDs')!;
        docIDs = prefs.getStringList('docIDs')!;
        isChanged = prefs.getStringList('isChanged')!;
      }

      //Add new Data into Lists
      //if OLD data edited
      if(docID != 'new'){
        int index = docIDs.indexOf(docID!);

        titles[index] = title;
        descriptions[index] = description;
        amounts[index] = amount.toStringAsFixed(0);
        providerIDs[index] = providerID;
        providerNames[index] = providerName;
        isChanged[index] = 'changed';
        //no need to change docID as it was
      }
      //if NEW data
      else{
        titles.add(title);
        descriptions.add(description);
        amounts.add(amount.toString());
        times.add((DateTime.now()).toString());
        providerIDs.add(providerID);
        providerNames.add(providerName);
        docIDs.add('new');
        isChanged.add('changed');
      }

      //Save All new Lists into PREFS
      await prefs.setStringList('titles', titles);
      await prefs.setStringList('descriptions', descriptions);
      await prefs.setStringList('amounts', amounts);
      await prefs.setStringList('times', times);
      await prefs.setStringList('providerNames', providerNames);
      await prefs.setStringList('providerIDs', providerIDs);
      await prefs.setStringList('docIDs', docIDs);
      await prefs.setStringList('isChanged', isChanged);
    }

    Get.to(
            () => BottomBar(bottomIndex: 0),
        transition: Transition.fade
    );
  }

  Future<void> deleteEvent (String docID, String tripCode) async {
    //if internet is connected
    if(await InternetConnectionChecker().hasConnection){
      await FirebaseFirestore
          .instance
          .collection('trips')
          .doc(tripCode)
          .collection('Events')
          .doc(docID)
          .delete();
    }

    Get.to(
            () => BottomBar(bottomIndex: 0),
        transition: Transition.fade
    );
  }
}