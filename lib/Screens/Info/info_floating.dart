import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitshare_v3/API/user_api.dart';

import '../../Widgets/bottom_nav_bar.dart';

class InfoFloatingActionButton extends StatefulWidget {
  const InfoFloatingActionButton({super.key});

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
                final prefs = await SharedPreferences.getInstance();
                String? tripCode = prefs.getString('tripCode');

                //update saved name list
                /*List<String> userNames = prefs.getStringList('userNames')!;
                userNames.add(nameController.text);
                await prefs.setStringList('userNames', userNames);*/

                //generate new user id
                String newUserID = UserApi().generateUID();

                //update saved id list
                /*List<String> userIDs = prefs.getStringList('userIDs')!;
                userNames.add(newUserID);
                prefs.setStringList('userIDs', userIDs);*/

                //save new user into new id inside userData database
                UserApi().addUser(newUserID, nameController.text, '', [tripCode]);
                //update users list in trip
                UserApi().addIntoTripsUserList(tripCode!, newUserID);

                navigator.pop();

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
            _showTextInputDialog(context);
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