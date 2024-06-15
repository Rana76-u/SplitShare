import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:splitshare_v3/API/auth_service.dart';
import 'package:splitshare_v3/Screens/Home/home.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: SizedBox()),

              //SPLITSHARE
              GestureDetector(
                onTap: () {
                  Get.to(
                      () => const HomePage(),
                  );
                },
                child: const Text(
                  'SPLITSHARE',
                  style: TextStyle(
                    fontFamily: 'Anurati',
                    fontSize: 25,
                    letterSpacing: 3,
                  ),
                ),
              ),

              //Group Expense Tracker
              const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Text(
                  'Group Expense Tracker',
                ),
              ),

              //Space
              const SizedBox(height: 10,),

              //Login Button
              isLoading ? const LinearProgressIndicator():
              SizedBox(
                width: MediaQuery.of(context).size.width*0.55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                  ),
                  onPressed: () async{
                    setState(() {
                      isLoading = true;
                    });

                    AuthService().signInWithGoogle().then((_) {
                      setState(() {
                        isLoading = false;
                        Get.to(
                            () => const MyTrips(),
                          transition: Transition.fade
                        );
                      });
                    })
                        .catchError((error) {
                      // Handle any error that occurred during sign-in
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $error')
                          )
                      );

                      setState(() {
                        isLoading = false;
                      });
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(BoxIcons.bxl_google),
                      Text(
                        'Continue Using Google',
                        style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.bold,
                            fontSize: 13
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
