import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitshare_v3/Models/global_variables.dart';
import 'package:splitshare_v3/Screens/CRUD/crud_event.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Screens/Home/home_floating.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';
import '../../Widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? connectionTimer;

  bool isFirstTimeLoading = true;

  bool connection = true;
  final bool _isSearching = false;
  bool _isLoading = false;
  bool isBackupInProgress = false;
  bool providerFlag = false;
  int selectedProviderFlag = -1;
  String selectedUserID = '';

  String tripCode = '';
  DateTime lastEdited = DateTime.now();

  List<String> titles = [];
  List<String> descriptions = [];
  List<String> amounts = [];
  List<String> times = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];
  List<String> docIDs = [];
  List<String> isChanged = [];
  List<String> userNames = [];
  List<String> userIDs = [];
  List<int> searchIndexes = [];

  TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  initState() {
    _isLoading = true;
    startConnectionCheckTimer();
    loadTripInfo();
    super.initState();
    /////startConnectionCheckTimer();
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed to prevent memory leaks.
    connectionTimer?.cancel();
  }

  void startConnectionCheckTimer() {
    // Create a timer that checks the connection status every 5 seconds.
    connectionTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        checkConnection();
      }
    });
  }

  Future<void> checkConnection() async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (mounted) {
      if (hasConnection != connection) {
        // The connection status has changed.
        setState(() {
          connection = hasConnection;
        });

        if (hasConnection) {
          if (!isBackupInProgress) {
            isBackupInProgress = true;
            backupData().then((_) {
              isBackupInProgress = false;
            });
          }
        } else {
          getDataFromSharedPreferences();
        }
      }
    }
  }
  
  Future<void> loadTripInfo() async {
    
    if (connection) {
      List<dynamic> loadTripInfoUserIDs = [];
      List<dynamic> loadTripInfoUserNames = [];

      final prefs = await SharedPreferences.getInstance();

      if (firstLoadTripCode != '') {
        //setState(() {
        tripCode = firstLoadTripCode;
        //});
      } else {
        //setState(() {
        tripCode = prefs.getString('tripCode') ?? '';
        //});
      }

      /*setState(() {
        tripCode = prefs.getString('tripCode') ?? '';
        print(tripCode);
      });*/

      //This was inside backupData
      if (prefs.containsKey('titles')) {
        titles = prefs.getStringList('titles') ?? [];
        descriptions = prefs.getStringList('descriptions') ?? [];
        amounts = prefs.getStringList('amounts') ?? [];
        times = prefs.getStringList('times') ?? [];
        providerNames = prefs.getStringList('providerNames') ?? [];
        providerIDs = prefs.getStringList('providerIDs') ?? [];
        docIDs = prefs.getStringList('docIDs') ?? [];
        isChanged = prefs.getStringList('isChanged') ?? [];

        for (int i = 0; i < titles.length; i++) {
          searchIndexes.add(i);
        }
      }

      if (prefs.containsKey('userNames')) {
        userNames = prefs.getStringList('userNames') ?? [];
        userIDs = prefs.getStringList('userIDs') ?? [];
      }

      //Loads all trip info
      DocumentSnapshot tripCodeSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripCode)
          .get();
      await prefs.setString('tripCreator', tripCodeSnapshot.get('creator'));

      loadTripInfoUserIDs = tripCodeSnapshot.get('users');
      
      if(loadTripInfoUserIDs.contains(FirebaseAuth.instance.currentUser!.uid)){
        List<String> stringUserIdsList =
        loadTripInfoUserIDs.map((item) => item.toString()).toList();
        await prefs.setStringList('userIDs', stringUserIdsList);

        //loads and save all usernames
        for (int i = 0; i < loadTripInfoUserIDs.length; i++) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('userData')
              .doc(loadTripInfoUserIDs[i])
              .get();

          loadTripInfoUserNames.add(userSnapshot.get('name'));
        }
        List<String> stringUserNamesList =
        loadTripInfoUserNames.map((item) => item.toString()).toList();
        await prefs.setStringList('userNames', stringUserNamesList);
        //lastEdited = DateTime.parse(prefs.getString('lastEdited') ?? '');

        userIDs = stringUserIdsList;
        userNames = stringUserNamesList;

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
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> backupData() async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();

    messenger.showSnackBar(const SnackBar(
        duration: Duration(milliseconds: 500),
        content: Text('Backing up content.')));

    if (isChanged.isNotEmpty) {
      for (int index = 0; index < isChanged.length; index++) {
        if (index < isChanged.length && isChanged[index] == 'changed') {
          //&& tripCode != ''

          /*ManageCRUDOperations().uploadInfo(
                titles[index],
                descriptions[index],
                double.parse(amounts[index]),
                providerIDs[index],
                providerNames[index],
                docIDs[index],
                tripCode
            );*/
          FirebaseFirestore.instance
              .collection('trips')
              .doc(tripCode)
              .collection('Events')
              .doc()
              .set({
            'title': titles[index],
            'description': descriptions[index],
            'amount': double.parse(amounts[index]),
            'time': DateTime.now(),
            'addedBy': FirebaseAuth.instance.currentUser!.uid,
            'providedBy': providerIDs[index],
          });

          if (mounted) {
            setState(() async {
              if (index < isChanged.length) {
                isChanged[index] = 'notChanged';
                //Also Save new isChanged lists into prefs
                await prefs.setStringList('isChanged', isChanged);
              }
            });
          }
        }
      }

      /*//Also Save new isChanged lists into prefs
      await prefs.setStringList('isChanged', isChanged);*/
    }

    messenger.showSnackBar(const SnackBar(
        duration: Duration(milliseconds: 500),
        content: Text('Backup Complete')));
  }

  Future<void> saveDataToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('titles', titles);
    await prefs.setStringList('descriptions', descriptions);
    await prefs.setStringList('amounts', amounts);
    await prefs.setStringList('times', times);
    await prefs.setStringList('providerNames', providerNames);
    await prefs.setStringList('providerIDs', providerIDs);
    await prefs.setStringList('docIDs', docIDs);
    await prefs.setStringList('isChanged', isChanged);
  }

  Future<void> getDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    providerNames = prefs.getStringList('providerNames')!;
    isChanged = prefs.getStringList('isChanged')!;

    titles = prefs.getStringList('titles')!;
    descriptions = prefs.getStringList('descriptions')!;
    amounts = prefs.getStringList('amounts')!;
    times = prefs.getStringList('times')!;
    providerIDs = prefs.getStringList('providerIDs')!;
    docIDs = prefs.getStringList('docIDs')!;

// Create a list of Map entries to associate each item with its time
    List<Map<String, dynamic>> itemsWithTimes = [];

    for (int i = 0; i < times.length; i++) {
      itemsWithTimes.add({
        'title': titles[i],
        'description': descriptions[i],
        'amount': amounts[i],
        'time': DateTime.parse(times[i]),
        'providerName': providerNames[i],
        'providerID': providerIDs[i],
        'docID': docIDs[i],
        'isChanged': isChanged[i],
      });
    }

// Sort the list by time
    itemsWithTimes.sort((a, b) => b['time'].compareTo(a['time']));

// Update the lists with sorted data
    titles = itemsWithTimes.map((item) => item['title'].toString()).toList();
    descriptions =
        itemsWithTimes.map((item) => item['description'].toString()).toList();
    amounts = itemsWithTimes.map((item) => item['amount'].toString()).toList();
    times = itemsWithTimes.map((item) => item['time'].toString()).toList();
    providerNames =
        itemsWithTimes.map((item) => item['providerName'].toString()).toList();
    providerIDs =
        itemsWithTimes.map((item) => item['providerID'].toString()).toList();
    docIDs = itemsWithTimes.map((item) => item['docID'].toString()).toList();
    isChanged =
        itemsWithTimes.map((item) => item['isChanged'].toString()).toList();

    setState(() {
      _isLoading = false;
    });
  }

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
  }

  void performSearch() {
    setState(() {
      searchIndexes.clear();

      if (searchController.text == '') {
        for (int i = 0; i < titles.length; i++) {
          searchIndexes.add(i);
        }
      } else {
        for (int i = 0; i < titles.length; i++) {
          if (titles[i]
              .toLowerCase()
              .contains(searchController.text.toLowerCase())) {
            searchIndexes.add(i);
          }
        }
      }
    });
  }

  void performProviderSearch(int index) {
    if (index != -1) {
      searchIndexes.clear();

      for (int i = 0; i < providerNames.length; i++) {
        if (userNames[index].toLowerCase() == providerNames[i].toLowerCase()) {
          searchIndexes.add(i);
        }
      }
    } else {
      for (int i = 0; i < titles.length; i++) {
        searchIndexes.add(i);
      }
    }
  }

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
                      if (!connection) ...[
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

                      searchFilterWidget(),

                      if (connection) ...[
                        SingleChildScrollView(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: loadItemFromFutureBuilder()),
                        )
                      ] else ...[
                        //Show From Prefs
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: loadItemFromPrefs())
                      ],

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

  Widget searchFilterWidget() {
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
                      //necessary for search
                      //selectedProviderFlag = -1;
                      performProviderSearch(-1);
                      performSearch();
                    });
                    // Start the search when the user enters a value in the text field
                    // Perform the search
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

        //User names
        Padding(
          padding:
              const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: providerFlag ? Colors.red.shade50 : Colors.white,
            ),
            child: SizedBox(
              height: 50,
              //MediaQuery.of(context).size.width*0.9 - 40,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: userNames.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (selectedProviderFlag == index) {
                            selectedProviderFlag = -1;
                            searchController.text = '';
                            performProviderSearch(-1);
                            //performSearch();
                          } else {
                            searchController.text = '';
                            selectedProviderFlag = index;

                            providerFlag = false;
                            selectedUserID = userIDs[index];
                            //performSearch();
                            performProviderSearch(index);
                          }
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => selectedProviderFlag == index
                                ? Colors.deepPurple
                                : Colors.deepPurple.withOpacity(0.08)),
                      ),
                      child: Center(
                          child: Text(
                        userNames[index],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedProviderFlag == index
                                ? Colors.white
                                : Colors.black),
                      )),
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

  Widget loadItemFromFutureBuilder() {
    titles.clear();
    descriptions.clear();
    amounts.clear();
    times.clear();
    providerNames.clear();
    providerIDs.clear();
    docIDs.clear();
    isChanged.clear();

    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('trips')
          .doc(tripCode)
          .collection('Events')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            //Saves Data Locally
            saveDataToSharedPreferences();
            return const Center(
              child: Text(
                'No Events Yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            );
          } else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                // Sort the documents by timestamp and reverse the list
                final sortedDocs = snapshot.data!.docs
                    .map((doc) => {
                          'doc': doc,
                          'time': (doc.get('time')).toDate(),
                        })
                    .toList()
                  ..sort((a, b) => b['time']!.compareTo(a['time']));

                final sortedDoc = sortedDocs[index];
                String docID = sortedDoc['doc'].id ?? 'null';
                String title = sortedDoc['doc'].get('title') ?? 'null';
                String description =
                    sortedDoc['doc'].get('description') ?? 'null';
                double amount = sortedDoc['doc'].get('amount') ?? 0.0;
                DateTime time = sortedDoc['time'] ?? DateTime.now();
                String addedBy = sortedDoc['doc'].get('addedBy') ?? 'null';
                String providedBy =
                    sortedDoc['doc'].get('providedBy') ?? 'null';

                /*String docID = snapshot.data!.docs[index].id;
              String title = snapshot.data?.docs[index].get('title');
              String description = snapshot.data?.docs[index].get('description');
              double amount = snapshot.data?.docs[index].get('amount');
              DateTime time = (snapshot.data?.docs[index].get('time')).toDate();
              String addedBy = snapshot.data?.docs[index].get('addedBy');
              String providedBy = snapshot.data?.docs[index].get('providedBy');*/

                return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('userData')
                      .doc(providedBy)
                      .get(),
                  builder: (context, providerSnapshot) {
                    String providerName =
                        providerSnapshot.data?.get('name') ?? 'null';

                    if (providerName != 'null') {
                      titles.add(title);
                      descriptions.add(description);
                      amounts.add(amount.toString());
                      times.add(time.toString());
                      providerNames.add(providerName);
                      providerIDs.add(providedBy);
                      docIDs.add(docID);
                      isChanged.add('notChanged');

                      if (selectedProviderFlag == -1) {
                        searchIndexes.add(index);
                      }
                    }

                    if (providerSnapshot.hasData) {
                      //Saves Data Locally
                      saveDataToSharedPreferences();

                      if (searchIndexes.contains(index)) {
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
                            leading: SizedBox(
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
                                  } else if (snapshot.connectionState ==
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
                      } else {
                        return const SizedBox();
                      }
                    } else if (providerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: LinearProgressIndicator(),
                      );
                    } else {
                      return const Center(
                        child: Text('Error Loading Data'),
                      );
                    }
                  },
                );
              },
            );
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LinearProgressIndicator(),
          );
        } else {
          return const Center(
            child: Text('Error Loading Data'),
          );
        }
      },
    );
  }

  Widget loadItemFromPrefs() {
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
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: titles.length,
        itemBuilder: (context, index) {
          if (searchIndexes.contains(index)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ListTile(
                onTap: () {
                  Get.to(
                      () => CRUDEvent(
                            title: titles[index],
                            amount: amounts[index].toString(),
                            description: descriptions[index],
                            provider: providerNames[index],
                            docID: docIDs[index],
                            time: times[index],
                          ),
                      transition: Transition.fade);
                },
                //user image
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: const Icon(Icons.offline_bolt_rounded),
                ),
                title: Text(
                  titles[index],
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
                          .format(DateTime.parse(times[index])),
                      style: const TextStyle(
                          color: Colors.grey, overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text('Provider: '),
                        Expanded(
                          child: Text(
                            providerNames[index],
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
                  '${amounts[index]}/-',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      overflow: TextOverflow.ellipsis),
                ),
                tileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      );
    }
  }
}
