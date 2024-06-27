import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/My%20Trips/Join%20Trip/qr_scanner.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';

class JoinTrip extends StatefulWidget {
  const JoinTrip({super.key});

  @override
  State<JoinTrip> createState() => _JoinTripState();
}

class _JoinTripState extends State<JoinTrip> {

  bool _isLoading = false;
  bool wrongCode = false;

  TextEditingController tripCode1Controller = TextEditingController();
  TextEditingController tripCode2Controller = TextEditingController();
  TextEditingController tripCode3Controller = TextEditingController();
  TextEditingController tripCode4Controller = TextEditingController();
  TextEditingController tripCode5Controller = TextEditingController();
  TextEditingController tripCode6Controller = TextEditingController();

  Future<void> joinTrip() async {
    final messenger = ScaffoldMessenger.of(context);

    String tripCode = '';
    //Prepare tripCode
    setState(() {
      tripCode =
          tripCode1Controller.text +
              tripCode2Controller.text +
              tripCode3Controller.text +
              tripCode4Controller.text +
              tripCode5Controller.text +
              tripCode6Controller.text;
    });

    //Check if tripCode Exists
    QuerySnapshot snapshot =
    await FirebaseFirestore
        .instance
        .collection('trips')
        .where(FieldPath.documentId, isEqualTo: tripCode)
        .get();
    if(snapshot.docs.isNotEmpty){

      //save tripCode into userData
      await FirebaseFirestore
          .instance
          .collection('userData')
          .doc(FirebaseAuth.instance.currentUser!.uid).update({
        'tripCodes': FieldValue.arrayUnion([tripCode])
      });
      //save userID into trip's users list
      await FirebaseFirestore
          .instance
          .collection('trips')
          .doc(tripCode).update({
        'users': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid])
      });

      //Save to Prefs
      var box = Hive.box('tripInfo');
      box.put('tripCode', tripCode);
      TripInfoManager().loadAndSaveTripInfo(tripCode);

      Get.to(
          () => BottomBar(bottomIndex: 0),
        transition: Transition.fade
      );
    }
    else{
      setState(() {
        wrongCode = true;
        _isLoading = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text("Trip Code Isn't Correct"))
      );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _isLoading ?
      const Center(
        child: CircularProgressIndicator(),
      )
          :
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Expanded(child: SizedBox()),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Enter Trip Code: ",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                ),
              ),
            ),

            //OTP Text Fields
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 15, left: 10, right: 10),
              child: Form(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    textFieldWidget(tripCode1Controller,'1'),
                    textFieldWidget(tripCode2Controller,'2'),
                    textFieldWidget(tripCode3Controller,'3'),
                    textFieldWidget(tripCode4Controller,'4'),
                    textFieldWidget(tripCode5Controller,'5'),
                    textFieldWidget(tripCode6Controller,'6'),
                  ],
                ),
              ),
            ),

            //Join Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () async {

                  setState(() {
                    _isLoading = true;
                  });

                  await joinTrip();
                },
                child: const Text(
                  "Join",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            //or
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text('or')
              ),
            ),

            //QR CODE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(
                      () => const QRScanner(),
                    transition: Transition.fade
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateColor.resolveWith((states) => Colors.deepPurple),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10,),
                    Text(
                      'SCAN QR CODE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),

            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget textFieldWidget(TextEditingController controller, String hintText) {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width/6 - 10,
      child: TextFormField(
        onChanged: (value){
          if(value.length == 1){
            FocusScope.of(context).nextFocus();
          }
        },
        onSaved: (otp1) {},
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide.none,

            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold
          ),
        ),
        style: wrongCode ? const TextStyle(
            color: Colors.red,
          fontWeight: FontWeight.bold
        )
            :
        Theme.of(context).textTheme.titleLarge,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
 }