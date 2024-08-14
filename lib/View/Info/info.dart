import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splitshare_v3/Controller/Routes/general_router.dart';
import 'package:splitshare_v3/View/Home/home_appbar.dart';
import 'package:splitshare_v3/View/Info/info_floating.dart';
import 'package:splitshare_v3/View/Info/version.dart';
import 'package:splitshare_v3/View/My%20Trips/my_trips.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_event.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../../Services/Utility/check_connection.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_event.dart';
import '../../Controller/Routes/bottombar_routing.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
import '../../Models/Hive/User/hive_user_model.dart';
import '../../Services/trip_info_manager.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  bool _isLoading = false;

  String tripCreator = '';
  String tripDate = '';
  String tripName = '';
  String tripCode = '';
  List<String> userIDs = [];
  List<String> userNames = [];
  List<String> userImageUrls = [];
  List<String> providerIDs = [];

  @override
  void initState() {
    _isLoading = true;
    setConnection();
    loadInfo();
    super.initState();
  }

  void setConnection() async {
    final ctx = context.read<HomeBloc>();
    bool connectionStatus = await checkConnection();
    ctx.add(ChangeConnection(connectionStatus));
  }

  void loadInfo() async {

    //providerIDs = prefs.getStringList('providerIDs')!;

    final tripBox = Hive.box('tripInfo');
    tripCreator = tripBox.get('tripCreator');
    tripDate = tripBox.get('tripDate');
    tripName = tripBox.get('tripName');
    tripCode = tripBox.get('tripCode');

    /*final userBox = Hive.box<UserClass>('users');
    userIDs = userBox.keys.cast<String>().toList();
    userNames = userBox.values.map((user) => user.name).toList();*/
    userIDs = await TripInfoManager().getTripUserIDs();
    userNames = await TripInfoManager().getUserNames();
    userImageUrls = await TripInfoManager().getUserImageUrls();

    providerIDs.clear();
    final eventBox = Hive.box<Event>('events');
    final events = eventBox.values; // Retrieve all events from the Hive box
    for (var event in events) {
      if(event.action != 'delete'){
        providerIDs.add(event.providedBy);
      }
    }

    parseTimestampString(tripDate);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    context.read<BottomBarBloc>().add(BottomBarSelectedItem(0));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const BottomBar(); // Return the BottomBar widget directly
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // You can add custom transitions here if needed
        },
      ),
    );

    // Simulate a delay for the refresh indicator
    await Future.delayed(const Duration(seconds: 1));
  }

  void parseTimestampString(String timestampString) {
    int seconds =
        int.parse(timestampString.split('seconds=')[1].split(',').first.trim());
    int nanoseconds = int.parse(
        timestampString.split('nanoseconds=')[1].split(')').first.trim());

    DateTime tempDateTime = DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + nanoseconds ~/ 1000000,
    );
    tripDate = DateFormat('hh:mm a EE, dd MMM, yyyy').format(tempDateTime).toString();
  }

  void _generateQR() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('QR Code'),
            ),
            body: Center(
              child: RepaintBoundary(
                child: QrImageView(
                  data: tripCode,
                  version: 1,
                  size: 320,
                  gapless: true,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        'Uh oh! Something went wrong...',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void deleteUser(int index) async {
    final toMyTrip = navigateTo(context, const MyTrips());
    final messenger = ScaffoldMessenger.of(context);

    // Dismiss the dialog
    if (mounted) {
      Navigator.pop(context);
    }

    //Internet connection needed for deletion
    if (await InternetConnectionChecker().hasConnection) {

      //can't remove tripCreator
      if (userIDs[index] == tripCreator) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Can not remove trip creator')));
      }
      else {
        //checks if theres any contribution remains for the user to delete
        if(providerIDs.contains(userIDs[index])){
          messenger.showSnackBar(const SnackBar(
            duration: Duration(seconds: 3),
              content: Text('This person has contributions in this trip remove/edit them first, then try again.'))
          );
          /*showDialog(
            context: infoContext,
            builder: (context) {
              return AlertDialog(
                title: const Text("Deletion Failed"),
                content: const Text('This person has contributions in this trip remove/edit them first, then try again.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Dismiss the dialog
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              );
            },
          );*/
        }
        else{
          setState(() {
            _isLoading = true;
          });

          //Delete from trip
          FirebaseFirestore.instance.collection('trips').doc(tripCode).update({
            'users': FieldValue.arrayRemove([userIDs[index]]),
          });

          //Delete from userData
          FirebaseFirestore.instance
              .collection('userData')
              .doc(userIDs[index])
              .update({
            'tripCodes': FieldValue.arrayRemove([tripCode])
          });


          //If removes person himself
          if (userIDs[index] == FirebaseAuth.instance.currentUser!.uid) {
            messenger
                .showSnackBar(const SnackBar(content: Text('You left the trip')));

            toMyTrip;
          }
          else {
            //Delete from Save
            final box = Hive.box<UserClass>('users');
            await box.delete(userIDs[index]);

            //Delete from lists
            userIDs.removeAt(index);
            userNames.removeAt(index);

            messenger.showSnackBar(const SnackBar(content: Text('User Removed')));
          }

          setState(() {
            _isLoading = false;
          });
        }

      }

    }
    else {
      messenger.showSnackBar(const SnackBar(
          content: Text('Internet Connection Required To Perform Deletion')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeBlocState>(
        builder: (context, state) {
          return PopScope(
            onPopInvoked: (didPop) {
              context.read<BottomBarBloc>().add(BottomBarSelectedItem(0));
              Navigator.of(context).push(
                BottomBarAnimatedPageRoute(page: const BottomBar()),
              );
            },
            child: Scaffold(
              appBar: HomeAppBar(state: state, screen: 'Trip',),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: const InfoFloatingActionButton(),
              body: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trip Name",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      Row(
                        children: [
                          Text(
                            tripName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Colors.purple),
                          ),

                          editTripWidget(state)
                        ],
                      ),

                      //Trip info & TripCode
                      _tripInfoWidget(),

                      const SizedBox(
                        height: 15,
                      ),

                      //users
                      Text('Total ${userIDs.length} Person'),
                      const SizedBox(
                        height: 10,
                      ),
                      userBuilder(state),

                      //version
                      version(),

                      const SizedBox(height: 150,)
                    ],
                  ),
                ),
              ),
            ),
          );
        },
    );
  }

  Widget editTripWidget(HomeBlocState state) {
    return IconButton(
      onPressed: () async {
        final ctx = context.read<HomeBloc>();
        if(await checkConnection()){
          ctx.add(ChangeConnection(true));
          if(mounted){
            showDialog(
              context: context,
              builder: (BuildContext context) {
                TextEditingController tripNameController = TextEditingController();
                tripNameController.text = tripName;

                return AlertDialog(
                  title: const Text('Edit Trip'),
                  content: TextField(
                    controller: tripNameController,
                    decoration: const InputDecoration(hintText: "Enter trip details"),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await FirebaseFirestore.instance.collection('trips')
                            .doc(tripCode)
                            .update({
                          'tripName': tripNameController.text
                        });

                        final tripBox = Hive.box('tripInfo');
                        await tripBox.put('tripName', tripNameController.text);

                        // Dismiss the dialogue
                        navigator.pop();

                        // updates the page
                        _handleRefresh();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                );
              },
            );
          }
        }
        else{
          ctx.add(ChangeConnection(false));

          if(mounted){
            showMessage(context);
          }
        }



      },
      icon: const Icon(Icons.edit),
      color: Colors.deepPurple,
    );
  }

  Widget _tripInfoWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Trip Info
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5 - 30,
          child: Text.rich(
              TextSpan(
                  text: 'Created by ',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  children: [
                    TextSpan(
                        text: userNames[userIDs.indexOf(tripCreator)],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.clip,
                            color: Colors.black,
                            fontSize: 15)),
                    const TextSpan(
                        text: " at ",
                        style: TextStyle(
                            overflow: TextOverflow.clip,
                            color: Colors.grey,
                            fontSize: 12)),
                    TextSpan(
                        text: tripDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.clip,
                            color: Colors.black,
                            fontSize: 14)),
                  ]
              )
          ),
        ),

        //Space
        const SizedBox(
          width: 15,
        ),

        //Trip Code
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "#Access Code",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            SelectableText(tripCode,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.clip,
                    fontSize: 40)),
            Row(
              children: [
                //copy
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip Code Copied')));
                    Clipboard.setData(ClipboardData(text: tripCode));
                  },
                  child: Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.copy,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                //QR Code
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR Code Generated')));
                    _generateQR();
                  },
                  child: Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.qr_code_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                //Share Code
                GestureDetector(
                  onTap: () async {
                    await Share.share(
                        'SplitShare: ( $tripName) Trip Joining Code: $tripCode');
                  },
                  child: Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget userBuilder(HomeBlocState state) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userIDs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: state.connection && userImageUrls[index] != '' || userImageUrls[index].isNotEmpty ?
                SizedBox(
                  height: 32.5,
                  child: CachedNetworkImage(
                    imageUrl: userImageUrls[index],
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                )
                    :
                const Icon(Icons.person),
              ),
              title: Text(
                userNames[index],
                style: const TextStyle(overflow: TextOverflow.clip),
              ),
              tileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              trailing: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Dismiss the dialog
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Perform the delete action
                              deleteUser(index = index);
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const SizedBox(
                  height: 37,
                  width: 37,
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              )
          ),
        );
      },
    );
  }


}
