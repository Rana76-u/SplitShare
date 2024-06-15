import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Screens/Profile/profile.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool connected;
  final bool isLoading;

  const HomeAppBar({
    super.key,
    required this.connected,
    required this.isLoading,
  });

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
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: isLoading && connected ?
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Backup In Progress')
                  )
              );
            },
            child: const SizedBox(
              width: 50,
              child: LinearProgressIndicator(),
            ),
          )
              : connected ?
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All Data Backup Successfully')
                )
              );
            },
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Colors.green,
            ),
          )
              :
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Backup Is Pending')
                  )
              );
            },
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Colors.grey,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              height: 35,
              width: 35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: !connected
                    ?
                    /*Lottie.asset(
                    'assets/lottie/profile.json'
                )*/
                    const Icon(Icons.person)
                    : GestureDetector(
                        onTap: () {
                          Get.to(() => const Profile(),
                              transition: Transition.fade);
                        },
                        child: Image.network(
                          FirebaseAuth.instance.currentUser!.photoURL ?? '',
                        ),
                      ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
