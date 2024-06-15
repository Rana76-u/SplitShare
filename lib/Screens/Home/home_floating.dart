import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Screens/CRUD/crud_event.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: FittedBox(
        child: FloatingActionButton.extended(
          onPressed: () {
            Get.to(
              () => CRUDEvent(),
              transition: Transition.fade,
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: const Text(
            'Add Event',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15
            ),
          ),
          icon: const Icon(
              Icons.add_circle
          ),
        ),
      ),
    );
  }
}
