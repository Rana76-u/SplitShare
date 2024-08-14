


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';
import 'package:splitshare_v3/Services/Utility/check_connection.dart';
import 'package:splitshare_v3/Services/user_api.dart';
import 'package:splitshare_v3/Services/trip_info_manager.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';

import '../../Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_event.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_event.dart';
import '../../Controller/Routes/bottombar_routing.dart';
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
                final bottomBarBloc = context.read<BottomBarBloc>();
                final navigator = Navigator.of(context);
                String? tripCode = await TripInfoManager().getTripCode();

                //generate new user id
                String newUserID = UserApi().generateUID();

                //online
                UserApi().addUser(newUserID, nameController.text, '', [tripCode]);
                //offline
                UserApi().addIntoTripsUserList(tripCode, newUserID);

                navigator.pop();

                //todo: this doesn't work until going to home
                
                bottomBarBloc.add(BottomBarSelectedItem(0));
                navigator.push(
                  BottomBarAnimatedPageRoute(page: const BottomBar()),
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
    return BlocBuilder<HomeBloc, HomeBlocState>(
      builder: (context, state) {
        return SizedBox(
          height: 60,
          width: 200,
          child: FittedBox(
            child: FloatingActionButton.extended(
              onPressed: () async {
                final inputDialogue = _showTextInputDialog(context);
                final message = showMessage(context);
                final homeBloc = context.read<HomeBloc>();

                if(await checkConnection()){
                  inputDialogue;
                }
                else{
                  homeBloc.add(ChangeConnection(false));
                  message;
                }
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
      },
    );
  }
}