import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:splitshare_v3/API/notification_api.dart';
import 'package:splitshare_v3/API/user_api.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/My%20Trips/mytrip_appbar.dart';
import 'package:splitshare_v3/Screens/My%20Trips/mytrip_floatingbutton.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';

class MyTrips extends StatefulWidget {
  const MyTrips({super.key});

  @override
  State<MyTrips> createState() => _MyTripsState();
}

class _MyTripsState extends State<MyTrips> {

  String uid = '';
  bool _isLoading = false;
  final bool _isSearching = false;

  TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> tripNames = [];
  List<dynamic> tripCodes = [];
  List<Timestamp> tripDates = [];

  List<String> matchedTripNames = [];
  List<dynamic> matchedTripCodes = [];
  List<Timestamp> matchedTripDates = [];

  @override
  void initState() {
    _isLoading = true;
    NotificationApi().getToken();
    _checkAndSaveUser();
    loadMyTrips();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  _checkAndSaveUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    uid = user.uid;

    UserApi().addUser(
        uid,
        FirebaseAuth.instance.currentUser!.displayName ?? '',
        FirebaseAuth.instance.currentUser?.photoURL ?? '',
      []
    );

    /*if(mounted){
      setState(() {

      });
    }*/
  }

  void loadMyTrips() async {
    DocumentSnapshot documentSnapshot =
    await FirebaseFirestore
        .instance
        .collection('userData')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    tripCodes = documentSnapshot.get('tripCodes');
    tripNames.clear();
    tripDates.clear();

    for(int i=0; i< tripCodes.length; i++){
      DocumentSnapshot tripCodeSnapshot =
      await FirebaseFirestore
          .instance
          .collection('trips')
          .doc(tripCodes[i])
          .get();
      tripNames.add(tripCodeSnapshot.get('tripName'));
      tripDates.add(tripCodeSnapshot.get('date'));
    }

    if(mounted){
      setState(() {
        matchedTripNames = tripNames;
        matchedTripCodes = tripCodes;
        matchedTripDates = tripDates;
        _isLoading = false;
      });
    }
  }

  void search(String query) {
    setState(
          () {

        matchedTripNames = tripNames.where(
              (item) => item.toLowerCase().contains(
            query.toLowerCase(),
          ),
        ).toList();

      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const MyTripAppBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: const MyTripFloatingActionButton(),
        body: _isLoading ?
        const Center(
          child: CircularProgressIndicator(),
        )
            :
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Search Field
                Card(
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
                          ), //InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(left: 15),
                          //focusedBorder: InputBorder.none,
                          //enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: "Search with Trip Names . . .",
                          hintStyle: TextStyle(
                            fontSize: 13.0,
                            color: Colors.grey.shade500,
                          ),
                          suffixIcon: _focusNode.hasFocus ?
                          GestureDetector(
                              onTap: () {

                              },
                              child: Icon(
                                Icons.cancel,
                                size: 15,
                                color: Colors.grey.shade400,
                              )
                          )
                              :
                          GestureDetector(
                              onTap: () {

                              },
                              child: const Icon(
                                  Icons.search_rounded
                              )
                          ),
                        ),
                        controller: searchController,
                        onChanged: (query) {
                          search(query);
                        },
                      ),
                    ),
                  ),
                ),
                //Search Loading
                _isSearching ? LinearProgressIndicator(
                  color: Colors.blue.shade100,
                )
                    :
                const SizedBox(
                  height: 0,
                  width: 0,
                ),

                //Space
                const SizedBox(height: 15,),

                //My Trips Text
                const Padding(
                  padding: EdgeInsets.only(left: 15, bottom: 7),
                  child: Text(
                    '• My Trips',
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),

                if(matchedTripNames.isNotEmpty)...[
                  myTripItemBuilder()
                ]
                else...[
                  const Center(
                    child: Text(
                      'Nothings Here',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget myTripItemBuilder() {
    return ListView.builder(
      itemCount: matchedTripNames.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
              bottom: 5
          ),
          child: ListTile(
            onTap: () async {

              await TripInfoManager().loadAndSaveTripInfo(tripCodes[tripNames.indexOf(matchedTripNames[index])]);

              var box = Hive.box('tripInfo');
              box.put('tripCode', tripCodes[tripNames.indexOf(matchedTripNames[index])]);

              Get.to(
                      () => BottomBar(bottomIndex: 0),
                  transition: Transition.fade
              );
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: const Icon(Icons.playlist_add_check_circle_rounded),
            ),
            title: Text(
              matchedTripNames[index],
              style: const TextStyle(
                  fontWeight: FontWeight.bold
              ),
            ),
            subtitle: Text(
                DateFormat('EE, dd MMM,yy').format(tripDates[tripNames.indexOf(matchedTripNames[index])].toDate())
            ),
            trailing: const Icon(Icons.arrow_forward),
            tileColor: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
          ),
        );
      },
    );
  }
}
