import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitshare_v3/API/clear_boxes.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import 'package:splitshare_v3/Widgets/loading.dart';

class CreateTrip extends StatefulWidget {
  const CreateTrip({super.key});

  @override
  State<CreateTrip> createState() => _CreateTripState();
}

class _CreateTripState extends State<CreateTrip> {

  TextEditingController tripNameController = TextEditingController();

  Random random = Random();
  String randomTripCode = '';
  bool _isLoading = false;

  Future<void> createTrip() async {

    await FirebaseFirestore
        .instance
        .collection('trips')
        .doc(randomTripCode)
        .set({
      'tripName': tripNameController.text,
      'date': DateTime.now(),
      'creator': FirebaseAuth.instance.currentUser!.uid,
      'users': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]),
      'lastEdited': DateTime.now()
    });

    //save tripCode into userData
    await FirebaseFirestore
        .instance
        .collection('userData')
        .doc(FirebaseAuth.instance.currentUser!.uid).update({
      'tripCodes': FieldValue.arrayUnion([randomTripCode])
    });
  }

  @override
  Widget build(BuildContext context) {

    Loading loading = Loading();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Trip',
        ),
      ),
      body: _isLoading ?
      loading.central(context)
          :
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textFieldWidget(tripNameController),

              const SizedBox(height: 40,),

              Row(
                children: [
                  Text(
                    'Trip Code: $randomTripCode',
                    style: const TextStyle(
                        fontSize: 25
                    ),
                  ),

                  const SizedBox(width: 10,),

                  GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: randomTripCode));

                      messenger.showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Trip Code Copied'
                              )
                          )
                      );
                    },
                    child: const Icon(Icons.copy),
                  ),
                ],
              ),

              const Text(
                "Other's will join this trip, use this code.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20,),

              //Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    final messenger = ScaffoldMessenger.of(context);

                    await createTrip();

                    await clearAllTheBoxes();

                    //Save to Prefs
                    /*SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString('tripName', tripNameController.text);
                    await prefs.setString('tripCode', randomTripCode);
                    await prefs.setString('date', DateTime.now().toString());
                    await prefs.setString('creator', FirebaseAuth.instance.currentUser!.displayName.toString());
                    await prefs.setString('lastLoaded', DateTime.now().toString());
                    await prefs.setStringList('users', [FirebaseAuth.instance.currentUser!.uid]);*/
                    var box = Hive.box('tripInfo');
                    box.put('tripCode', randomTripCode);
                    await TripInfoManager().loadAndSaveTripInfo(randomTripCode);

                    messenger.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Trip Created'
                            )
                        )
                    );

                    //get to home
                    Get.to(
                            () => BottomBar(bottomIndex: 0),
                        transition: Transition.fade
                    );
                  },
                  child: const Text(
                      'Create'
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textFieldWidget(TextEditingController textEditingController) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide.none
          ),
          enabledBorder:  const OutlineInputBorder(
            borderSide: BorderSide.none
          ),
          prefixIcon: const Icon(
            Icons.short_text_rounded,
            color: Colors.grey,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Enter Trip Name",
        ),
        onChanged: (value) {
          setState(() {
            randomTripCode = (random.nextInt(900000) + 100000).toString();
          });
        },
        cursorColor: Colors.black,
      ),
    );
  }
}
