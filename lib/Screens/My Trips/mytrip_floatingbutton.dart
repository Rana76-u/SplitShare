import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Screens/My%20Trips/Create%20Trip/create_trip.dart';

class MyTripFloatingActionButton extends StatelessWidget {
  const MyTripFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: FittedBox(
        child: FloatingActionButton.extended(
          onPressed: () {
            Get.to(
              () => const CreateTrip(),
              transition: Transition.fade,
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: const Text(
            'Create Trip',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15
            ),
          ),
          icon: const Icon(
              Icons.document_scanner
          ),
        ),
      ),
    );
  }
}
