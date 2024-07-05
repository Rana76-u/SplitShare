import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:splitshare_v3/API/hive_api.dart';
import 'package:splitshare_v3/Models/manage_crud_operations.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/CRUD/crud_event.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Screens/Home/home_floating.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
import '../../Widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? connectionTimer;
  bool connection = false;
  bool showNoConnectionMessage = false;

  final bool _isSearching = false;
  bool _isLoading = false;
  bool isBackupInProgress = false;

  String selectedUserID = '';

  String tripCode = '';

  List<String> titles = [];
  List<String> descriptions = [];
  List<String> amounts = [];
  List<String> times = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];
  List<String> docIDs = [];
  List<dynamic> userNames = [];
  List<dynamic> userImageUrls = [];
  List<dynamic> userIDs = [];

  TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  initState() {
    _isLoading = true;
    setTripCode();
    getAllSavedData();
    startConnectionCheckTimer();
    loadTripInfo();
    super.initState();
  } //Done

  void setTripCode() async {
    var tripBox = await Hive.box('tripInfo');
    tripCode = await tripBox.get('tripCode');
  } //Done

  void startConnectionCheckTimer() {
    // Create a timer that checks the connection status every 0.5 seconds.
    connectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        checkConnection();
      }
    });
  } //Done

  Future<void> checkConnection() async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;

    if (mounted) {
      if (hasConnection != connection) {

        if (hasConnection == true) {
          if (!isBackupInProgress) {
            isBackupInProgress = true;
            backupData().then((_) {
              isBackupInProgress = false;
            });
          }
        }
        else if(hasConnection == false){
          showNoConnectionMessage = true;
          await getAllSavedData();
        }

        // The connection status has changed.
        setState(() {
          connection = hasConnection;
        });
      }
    }
  }
 //Done

  Future<void> getAllSavedData() async {
    docIDs.clear();
    titles.clear();
    descriptions.clear();
    amounts.clear();
    times.clear();
    providerIDs.clear();
    providerNames.clear();

    final box = Hive.box<Event>('events');
    final events = box.values.toList();

    // Sort events based on time
    events.sort((a, b) => b.time.compareTo(a.time));

    for (var event in events) {
      if(event.action != 'delete'){
        docIDs.add(event.id);
        titles.add(event.title);
        descriptions.add(event.description);
        amounts.add(event.amount.toString());
        times.add(event.time.toString());
        providerIDs.add(event.providedBy);
        providerNames.add(event.providerName);
      }
    }

    setState(() {
      _isLoading = false;
    });
  } //Done

  Future<void> loadTripInfo() async {

    if (connection) {
      TripInfoManager().loadAndSaveTripInfo(tripCode);

      //if the user does not belong to the trip anymore
      //like someone deleted this user
      //then redirect to MyTrips page
      List<String>? tempUserIds = await TripInfoManager().getTripUserIDs();
      if(tempUserIds.contains(FirebaseAuth.instance.currentUser!.uid)) {
        await backupData();
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

        Get.to(
                () => const MyTrips(),
            transition: Transition.fade
        );
      }
      //-----------------------------------------------------------------
    }

    userNames = await TripInfoManager().getUserNames();
    userIDs = await TripInfoManager().getTripUserIDs();
    userImageUrls = await TripInfoManager().getUserImageUrls();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }  //Done [setup backup]


  Future<void> _handleRefresh() async {
    final navigator = Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BottomBar(bottomIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );

    // Simulate a delay for the refresh indicator
    await Future.delayed(const Duration(seconds: 1));

    // Reload the same page by pushing a new instance onto the stack
    navigator;
  } //Done

  // todo
  Future<void> backupData() async {
    //get all the offline event and check if the action says 'update' or not
    final box = Hive.box<Event>('events');
    final events = box.values.toList();

    for (var event in events) {
      if(event.action == 'update') {
        await ManageCRUDOperations().uploadInfo(event.title, event.description, event.amount,
            event.providedBy, event.providerName, event.id, tripCode);

        //change event.action to 'none'
        event.action = 'none';

        // Save the updated event back to the Hive box
        box.put(event.key, event);
      }
      else if(event.action == 'delete'){
        //means only saved in hive not DB
        if(event.id == 'new'){
          ManageCRUDOperations().deleteFromSave(event.id);
        }
        else{
          ManageCRUDOperations().deleteEventFromDB(event.id, tripCode);
          ManageCRUDOperations().deleteFromSave(event.id);
        }
      }
    }

  } //On Test


  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed to prevent memory leaks.
    connectionTimer?.cancel();
  } //Done

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: HomeAppBar(
          connected: connection,
          isLoading: _isLoading,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: const HomeFloatingActionButton(),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(), /*Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/backup.json',
                  height: 300,
                  width: 200,
                ),
                const Text(
                  "Please Wait 'Backing Up'\nOffline Data",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            )*/
                )
              :
              //SingleChildScrollView
              SingleChildScrollView(
                  child: Column(
                    children: [
                      //Internet Checker
                      // todo
                      if (showNoConnectionMessage) ...[
                        Container(
                          color: Colors.red,
                          width: double.infinity,
                          child: const Text(
                            "no internet connection",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],

                      searchAndFilterWidget(),

                      //Problem is here cause the connection variable is always set to true initially
                      //and the connection checker timer calls himself after 2s
                      //Todo Temporarily I set connection to false initially - if it works then ok
                      /*if (connection) ...[
                        SingleChildScrollView(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: loadItemFromDatabase()
                          ),
                        )
                      ]
                      else ...[
                        //Show From Saved
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: loadItemFromHive()
                        )
                      ],*/

                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: connection
                              ? loadItemFromDatabase() // Load from Firebase when online
                              : loadItemFromHive() // Load from Hive when offline
                      ),

                      const SizedBox(
                        height: 100,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget searchAndFilterWidget() {

    return Column(
      children: [
        // Search TextField
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Card(
            elevation: 0,
            child: SizedBox(
              height: 40,
              child: SizedBox(
                child: TextField(
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Colors.black,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    //InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(left: 15),
                    //focusedBorder: InputBorder.none,
                    //enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "Search Events . . .",
                    hintStyle: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey.shade500,
                    ),
                    suffixIcon: _focusNode.hasFocus
                        ? GestureDetector(
                            onTap: () {
                              setState(() {});
                            },
                            child: Icon(
                              Icons.cancel,
                              size: 15,
                              color: Colors.grey.shade400,
                            ))
                        : GestureDetector(
                            onTap: () {},
                            child: const Icon(Icons.search_rounded)),
                  ),
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      selectedUserID = '';
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        //Search Loading
        _isSearching
            ? LinearProgressIndicator(
                color: Colors.blue.shade100,
              )
            : const SizedBox(
                height: 0,
                width: 0,
              ),

        //Users
        Padding(
          padding:
              const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: SizedBox(
              height: 50,
              //MediaQuery.of(context).size.width*0.9 - 40,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: userIDs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          //as user selected title search turns of and keyboard goes away
                          searchController.text = '';
                          FocusManager.instance.primaryFocus?.unfocus();
                          if(userIDs.indexOf(selectedUserID) == index) {
                            selectedUserID = '';
                          }
                          else {
                            selectedUserID = userIDs[index];
                          }
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => userIDs.indexOf(selectedUserID) == index
                                ? Colors.deepPurple.shade400
                                : Colors.deepPurple.withOpacity(0.08)),
                      ),
                      child: Center(
                          child: Row(
                            children: [

                              //image
                                connection && (userImageUrls[index] != '' || userImageUrls[index].isNotEmpty) ?
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(userImageUrls[index]),
                                ) : const SizedBox(),

                              //normal space
                              connection && (userImageUrls[index] != '' || userImageUrls[index].isNotEmpty) ?
                              const SizedBox(width: 5,) : const SizedBox(),

                              //name
                              Text(
                                userNames[index],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: userIDs.indexOf(selectedUserID) == index
                                        ? Colors.white
                                        : Colors.black),
                              )
                            ],
                          )
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget loadItemFromDatabase() {

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(tripCode)
          .collection('Events').orderBy('time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No Events Yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            );
          }
          else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {

                String docID = snapshot.data!.docs[index].id;
                String title = snapshot.data?.docs[index].get('title');
                String description = snapshot.data?.docs[index].get('description');
                double amount = snapshot.data?.docs[index].get('amount');
                DateTime time = (snapshot.data?.docs[index].get('time')).toDate();
                String addedBy = snapshot.data?.docs[index].get('addedBy');
                String providedBy = snapshot.data?.docs[index].get('providedBy');

                return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('userData')
                      .doc(providedBy)
                      .get(),
                  builder: (context, providerSnapshot) {
                    String providerName = providerSnapshot.data?.get('name') ?? 'null';

                    //Create Event object
                    Event event = Event(
                      id: docID,
                      title: title,
                      description: description,
                      amount: amount,
                      time: time,
                      addedBy: addedBy,
                      providedBy: providedBy,
                      providerName: providerName,
                      action: 'none'
                    );

                    // Save data to Hive
                    HiveApi().saveOrUpdateEvent(event);

                    if (providerSnapshot.hasData) {

                      //when no user selected
                      if (selectedUserID == '') {
                        //search event only when no user is selected
                        //deselect user when searchController changes value
                        //if searchController.text = '' means every title contains that
                        //also removed space for better search
                        if(title.replaceAll(' ', '')
                            .contains(searchController.text.toLowerCase().replaceAll(' ', ''))
                        ){
                          return eventTile(docID, title, description, amount, time, addedBy, providerName);
                        }
                        //if nothing matches show nothing
                        else{
                          return const SizedBox();
                        }

                      }
                      //search when any user selected
                      else {
                        if(selectedUserID == providedBy){
                          return eventTile(docID, title, description, amount, time, addedBy, providerName);
                        }
                        else {
                          return const SizedBox();
                        }
                      }
                    }
                    else if (providerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: LinearProgressIndicator(),
                      );
                    }
                    else {
                      return const Center(
                        child: Text('Error Loading Data'),
                      );
                    }
                  },
                );
              },
            );
          }
        }
        else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LinearProgressIndicator(),
          );
        }
        else {
          return const Center(
            child: Text('Error Loading Data'),
          );
        }
      },
    );
  }

  Widget loadItemFromHive() {
    if (titles.isEmpty) {
      return const Center(
        child: Text(
          'No Events Yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      );
    }
    else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: titles.length,
        itemBuilder: (context, index) {
          if (selectedUserID == '') {
            //search event only when no user is selected
            //deselect user when searchController changes value
            //if searchController.text = '' means every title contains that
            //also removed space for better search
            if(titles[index].replaceAll(' ', '')
                .contains(searchController.text.toLowerCase().replaceAll(' ', ''))
            ){
              return eventTile(docIDs[index], titles[index], descriptions[index],
                  double.parse(amounts[index]), DateTime.parse(times[index]), '', providerNames[index]);
            }
            else{
              return const SizedBox();
            }
          }
          else {
            if(selectedUserID == providerIDs[index]){
              return eventTile(docIDs[index], titles[index], descriptions[index],
                  double.parse(amounts[index]), DateTime.parse(times[index]), '', providerNames[index]);
            }
            else {
              return const SizedBox();
            }
          }
        },
      );
    }
  }

  Widget eventTile(String docID, String title, String description ,
      double amount, DateTime time, String addedBy, String providerName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: ListTile(
        onTap: () {
          Get.to(
                  () => CRUDEvent(
                title: title,
                amount: amount.toString(),
                description: description,
                provider: providerName,
                docID: docID,
                time: time.toString(),
              ),
              transition: Transition.fade);
        },
        //user image
        leading: connection ?
        SizedBox(
          height: 50,
          width: 50,
          child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('userData')
                .doc(addedBy)
                .get(),
            builder: (context, adderSnapshot) {
              //String adderImageUrl = adderSnapshot.data!.get('imageURL') ?? 'PicAlt';
              if (adderSnapshot.hasData) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                      adderSnapshot.data!.get('imageURL')),
                );
              } else if (adderSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return const Center(
                  child: Text('Error Loading Data'),
                );
              }
            },
          ),
        ) :
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: const Icon(Icons.offline_bolt_rounded),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis),
        ),
        //user name
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('hh:mm a, EE, dd MMM,yy')
                  .format(time),
              style: const TextStyle(
                  color: Colors.grey,
                  overflow: TextOverflow.ellipsis),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Provider: '),
                Expanded(
                  child: Text(
                    providerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            )
          ],
        ),
        trailing: Text(
          '${amount.toStringAsFixed(0)}/-',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              overflow: TextOverflow.ellipsis),
        ),
        tileColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
        ),
      ),
    );
  }
}
