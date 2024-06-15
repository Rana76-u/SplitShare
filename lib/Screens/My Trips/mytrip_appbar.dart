import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Screens/Profile/profile.dart';

import 'Join Trip/join_trip.dart';

class MyTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyTripAppBar({super.key,});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'SPLITSHARE',
        style: TextStyle(
          fontFamily: 'Anurati',
          fontSize: 25,
          letterSpacing: 3,
        ),
      ),
      actions: [
        //join button
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ElevatedButton(
            onPressed: () {
              Get.to(
                  () => const JoinTrip(),
                  transition: Transition.fade
              );
            },
            child: const Text(
                'Join',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1
              ),
            ),
          ),
        ),

        //Profile Image
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Get.to(
                  () => const Profile(),
                transition: Transition.fade
              );
            },
            child: SizedBox(
              height: 35,
              width: 35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: FirebaseAuth.instance.currentUser!.photoURL == null
                    ? Container(
                  color: Colors.grey,
                )
                    : Image.network(
                  FirebaseAuth.instance.currentUser!.photoURL ?? '',
                ),
              ),
            ),
          ),
        ),


      ],
    );
  }
}
