import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitshare_v3/API/auth_service.dart';
import 'package:splitshare_v3/Models/Hive/User/hive_user_model.dart';
import 'package:splitshare_v3/Models/screensize.dart';
import 'package:splitshare_v3/Screens/Login/login.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';

import '../../Models/Hive/Event/hive_event_model.dart';

class ProfileFloatingActionButton extends StatelessWidget {
  const ProfileFloatingActionButton({super.key});

  void clearAllTheBoxes() async {
    var eventBox = Hive.box<Event>('events');
    await eventBox.clear();

    var userBox = Hive.box<UserClass>('users');
    await userBox.clear();

    var tripBox = Hive.box('tripInfo');
    await tripBox.clear();
  }

  @override
  Widget build(BuildContext context) {

    ScreenSize screenSize = ScreenSize();

    return Padding(
      padding: EdgeInsets.only(bottom: screenSize.height(context)*0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          //MyList
          SizedBox(
            width: 120,
            child: FittedBox(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                heroTag: 'Btn1',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  bool result = await InternetConnectionChecker().hasConnection;

                  if(result == true){

                    clearAllTheBoxes();

                    Get.to(
                      () => const MyTrips(),
                      transition: Transition.fade,
                    );
                  }
                  else{
                    messenger.showSnackBar(
                      const SnackBar(content: Text("You're Not Connected"))
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                label: const Text(
                  'My Trips',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15
                  ),
                ),
                icon: const Icon(
                    Icons.list_alt
                ),
              ),
            ),
          ),

          const SizedBox(width: 10,),

          //Logout
          SizedBox(
            width: 110,
            child: FittedBox(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                heroTag: 'Btn2',
                onPressed: () async {
                  var showOfflineMessage = showMessage(context);

                  if(await InternetConnectionChecker().hasConnection){
                    clearAllTheBoxes();

                    AuthService().signOut();

                    Get.to(
                            () => const LoginPage(),
                        transition: Transition.fade
                    );
                  }
                  else{
                    showOfflineMessage;
                  }

                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15
                  ),
                ),
                icon: const Icon(
                    Icons.logout_rounded
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
