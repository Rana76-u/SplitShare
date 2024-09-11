import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:splitshare_v3/Controller/Routes/general_router.dart';
import 'package:splitshare_v3/Models/event.dart';
import 'package:splitshare_v3/Models/user.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
import '../../View/My Trips/my_trips.dart';
import '../Utility/check_connection.dart';
import '../trip_info_manager.dart';

class OfflineDataHandler {

  Future<String> getTripCode() async {
    var tripBox = Hive.box('tripInfo');
    return await tripBox.get('tripCode');
  }

  Future<List<EventModel>> getAllSaveEventsData() async {
    final box = Hive.box<Event>('events');
    final events = box.values.toList();

    // Sort events based on time
    events.sort((a, b) => b.time.compareTo(a.time));

    List<EventModel> eventsList = [];

    for (var event in events) {
      if(event.action != 'delete'){
        EventModel newEvent = EventModel(
          docID: event.id,
          title: event.title,
          description: event.description,
          amount: event.amount,
          time: event.time,
          adderID: event.addedBy,
          providerID: event.providedBy,
          providerName: event.providerName,
          action: event.action
        );
        eventsList.add(newEvent);
      }
    }

    return eventsList;
  }

  Future<List<UserModel>> getUserInfo(String tripCode, BuildContext context) async {
    //final toNewScreen = navigateTo(context, const MyTrips());

    if (await checkConnection()) {
      TripInfoManager().loadAndSaveTripInfo(tripCode);

      //if the user does not belong to the trip anymore
      //like someone deleted this user
      //then redirect to MyTrips page
      List<String>? tempUserIds = await TripInfoManager().getTripUserIDs();
      if(tempUserIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
        //await backupData();
      }
      else{
        //Unhandled Exception:
        // dependOnInheritedWidgetOfExactType<_ScaffoldMessengerScope>() or dependOnInheritedElement()
        // was called before _HomePageState.initState() completed.
        /*messenger.showSnackBar(
            const SnackBar(
                content: Text('You have been removed from the trip')
            )
        );*/

        //toNewScreen;
        navigateTo(context, const MyTrips());
      }
      //-----------------------------------------------------------------
    }

    List userNames = await TripInfoManager().getUserNames();
    List userIDs = await TripInfoManager().getTripUserIDs();
    List userImageUrls = await TripInfoManager().getUserImageUrls();

    List<UserModel> userList = [];

    for(int i=0; i<userIDs.length; i++){
      UserModel user = UserModel(
        name: userNames[i],
        userId: userIDs[i],
        imageUrl: userImageUrls[i]
      );
      userList.add(user);
    }

    return userList;
  } //previously loadTripInfo

}