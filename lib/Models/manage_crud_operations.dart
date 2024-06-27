import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitshare_v3/API/hive_api.dart';
import 'package:splitshare_v3/Models/Hive/Event/hive_event_model.dart';
import '../Widgets/bottom_nav_bar.dart';

class ManageCRUDOperations {

  Future<void> uploadInfo (
      String title, String description, double amount,
      String providerID, String providerName, String? docID, String tripCode)
  async {

    //if internet is connected
      //update old data
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
     //post new data
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

    Get.to(
            () => BottomBar(bottomIndex: 0),
        transition: Transition.fade
    );
  }

  saveOffline(String title, String description, double amount,
      String providerID, String providerName, String? docID, String tripCode)
  async {
    //if OLD data edited
    if(docID != 'new'){
      Event event = await HiveApi().getEvent(docID!);
      HiveApi().updateAnEvent(
          event, title, description, amount,
          event.time, event.addedBy,
          providerID, providerName, docID, 'update');
    }
    //if NEW data
    else{
      //Create Event object
      Event event = Event(
          id: 'new',
          title: title,
          description: description,
          amount: amount,
          time: DateTime.now(),
          addedBy: FirebaseAuth.instance.currentUser!.uid,
          providedBy: providerID,
          providerName: providerName,
          action: 'update'
      );

      // Save data to Hive
      HiveApi().saveOrUpdateEvent(event);
    }

    Get.to(
            () => BottomBar(bottomIndex: 0),
        transition: Transition.fade
    );
  }

  Future<void> deleteEventFromDB (String docID, String tripCode) async {
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
  }

  deleteFromSave(String eventId) async {
    final box = Hive.box<Event>('events');

    // Find the event with the specified ID
    final eventKey = box.keys.firstWhere(
          (key) {
        final event = box.get(key);
        return event!.id == eventId;
      },
      orElse: () => null,
    );

    if (eventKey != null) {
      // Delete the event from the Hive box using its key
      await box.delete(eventKey);
    }

  }

}