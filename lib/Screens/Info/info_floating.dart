import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/API/user_api.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';

import '../../Widgets/bottom_nav_bar.dart';

class InfoFloatingActionButton extends StatefulWidget {
  final bool connection;
  const InfoFloatingActionButton({super.key, required this.connection});

  @override
  State<InfoFloatingActionButton> createState() => _InfoFloatingActionButtonState();
}

class _InfoFloatingActionButtonState extends State<InfoFloatingActionButton> {

  Future<void> _showTextInputDialog(BuildContext context) async {
    TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Participant Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Type name here"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                String? tripCode = await TripInfoManager().getTripCode();

                //generate new user id
                String newUserID = UserApi().generateUID();

                //online
                UserApi().addUser(newUserID, nameController.text, '', [tripCode]);
                //offline
                UserApi().addIntoTripsUserList(tripCode, newUserID);

                navigator.pop();

                //doesn't work until going to home
                Get.offAll(
                        () => BottomBar(bottomIndex: 0),
                    transition: Transition.fade
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: FittedBox(
        child: FloatingActionButton.extended(
          onPressed: () {
            widget.connection ?
            _showTextInputDialog(context)
              :
            showMessage(context);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: const Text(
            'Add Participant',
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