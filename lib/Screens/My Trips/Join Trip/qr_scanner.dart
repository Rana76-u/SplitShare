import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';

const bgColor = Color(0xFFFafafa);

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {

  bool isScanCompleted = false;
  bool _isLoading = false;
  String tripCode = '';

  Future<void> joinTrip() async {
    final messenger = ScaffoldMessenger.of(context);

    if(await InternetConnectionChecker().hasConnection){
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
        TripInfoManager().saveTripInfo(tripCode);

        Get.to(
                () => BottomBar(bottomIndex: 0),
            transition: Transition.fade
        );
      }
      else{
        setState(() {
          _isLoading = false;
        });

        messenger.showSnackBar(
            const SnackBar(content: Text("Trip Code Isn't Correct"))
        );
      }
    }
    else{
      messenger.showSnackBar(
        const SnackBar(
            content: Text('You are not connected to the internet.')
        )
      );
    }
  }

  void closeScreen() {
    isScanCompleted = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "QR Scanner",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1
          ),
        ),
      ),
      body: _isLoading
      ? const Center(child: CircularProgressIndicator(),)
      : Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      "Place the QR code in the area",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1
                    ),
                  ),

                  SizedBox(height: 10,),

                  Text(
                      "Scanning will be started automatically",
                    style: TextStyle(
                        fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  MobileScanner(
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          setState(() {
                            tripCode = barcode.rawValue!;
                            _isLoading = true;
                          });

                          await joinTrip();
                          break;
                        }
                      }),
                  QRScannerOverlay(
                    overlayColor: bgColor,
                    borderColor: Colors.blue,
                  )
                ],
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  "Scanning...",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
