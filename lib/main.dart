import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Services/trip_info_manager.dart';
import 'package:splitshare_v3/View/Login/login.dart';
import 'package:splitshare_v3/View/My%20Trips/my_trips.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import 'package:splitshare_v3/firebase_options.dart';
import 'Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import 'Models/Hive/Event/hive_event_model.dart';
import 'Models/Hive/User/hive_user_model.dart';
import 'Services/Notification/firebase_api.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

        String code = snapshot.data ?? '';

        if (FirebaseAuth.instance.currentUser != null && //!.uid.isNotEmpty
            snapshot.connectionState == ConnectionState.done &&
            code != '') { //isNotEmpty, snapshot.data?.length != 0
          return const BottomBar();//BottomBar(bottomIndex: 0); 
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
    return MultiBlocProvider(
        providers: [
          BlocProvider<BottomBarBloc>(
            create: (context) => BottomBarBloc(),
          ),
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(),
          ),
        ],
        child: Builder(
          builder: (context) {
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
          },
        )
    );
  }
}
