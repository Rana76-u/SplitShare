import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitshare_v3/Screens/Login/login.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import 'package:splitshare_v3/firebase_options.dart';

import 'API/firebase_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget screenNavigator() {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (FirebaseAuth.instance.currentUser != null &&
            snapshot.connectionState == ConnectionState.done &&
            snapshot.data!.getString('tripCode') != null) {
          return BottomBar(bottomIndex: 0); //Fix 0
        } else if (FirebaseAuth.instance.currentUser != null) {
          return const MyTrips();
        } else {
          return const LoginPage();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SplitShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Urbanist',
      ),
      debugShowCheckedModeBanner: false,
      home: screenNavigator(),
    );
  }
}
