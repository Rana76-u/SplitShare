import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/Login/login.dart';
import 'package:splitshare_v3/Screens/My%20Trips/my_trips.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import 'package:splitshare_v3/firebase_options.dart';
import 'API/firebase_api.dart';
import 'Models/Hive/Event/hive_event_model.dart';
import 'Models/Hive/User/hive_user_model.dart';


void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  await FirebaseApi().initNotifications();

  await Hive.initFlutter();
  // Check if the box is already open before opening it
  //Hive.registerAdapter(EventAdapter());
  if (!Hive.isBoxOpen('events')) {
    Hive.registerAdapter(EventAdapter());
    await Hive.openBox<Event>('events');
  }

  if (!Hive.isBoxOpen('users')) {
    Hive.registerAdapter(UserAdapter());
    await Hive.openBox<UserClass>('users');
  }

  if (!Hive.isBoxOpen('tripInfo')) {
    await Hive.openBox('tripInfo');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget screenNavigator(){
    return FutureBuilder(
      future: TripInfoManager().getTripCode(),
      builder: (context, snapshot) {
        if (FirebaseAuth.instance.currentUser != null && //!.uid.isNotEmpty
            snapshot.connectionState == ConnectionState.done &&
            snapshot.data?.length != 0) { //isNotEmpty ?.length != 0
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
