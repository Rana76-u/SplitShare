import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitshare_v3/View/Profile/profile_floating.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const ProfileFloatingActionButton(),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [

              const SizedBox(height: 20,),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //image
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: FirebaseAuth.instance.currentUser!.photoURL != null ?
                      Image.network(
                          FirebaseAuth.instance.currentUser!.photoURL.toString()
                      )
                          :
                      const Icon(Icons.person),
                    ),
                  ),

                  const SizedBox(width: 10,),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //name
                        Text(
                          FirebaseAuth.instance.currentUser!.displayName.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 27,
                            overflow: TextOverflow.clip
                          ),
                        ),
                        //email
                        Text(
                          FirebaseAuth.instance.currentUser!.email.toString(),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
