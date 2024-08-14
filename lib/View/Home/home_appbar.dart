import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';
import 'package:splitshare_v3/Services/Utility/check_connection.dart';
import 'package:splitshare_v3/View/Calculation/total_spending.dart';
import 'package:splitshare_v3/View/Home/search_filter_widget.dart';
import 'package:splitshare_v3/View/Profile/profile.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_event.dart';
import '../../Controller/Routes/general_router.dart';
import '../../Services/Hive/clear_boxes.dart';
import '../My Trips/my_trips.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeBlocState state;
  final String screen;
  final double? total;
  final double? perPerson;
  const HomeAppBar({super.key, required this.state, required this.screen, this.total, this.perPerson});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (
      state.connection && screen == 'Home' ? 100
          :
      state.connection == false && screen == 'Home' ? 110
          :
      screen == 'Calculation' ? 65
          :
          0
    )
  );

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
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          screen == 'Home' ? searchAndFilterWidget(context, state)
              :
          screen == 'Calculation' ? spendingCard(perPerson!, total!)
              :
          const SizedBox(),
        ],
      ),

      actions: [
        GestureDetector(
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: TextButton(
              onPressed: () async {
                final toMyTrip = navigateTo(context, const MyTrips());
                final messenger = ScaffoldMessenger.of(context);
                bool result = await InternetConnectionChecker().hasConnection;

                if(result == true){

                  await clearAllTheBoxes();

                  toMyTrip;
                }
                else{
                  messenger.showSnackBar(
                      const SnackBar(content: Text("You're Not Connected"))
                  );
                }
              },
              child: Text(
                'My Trips',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: state.isLoading && state.connection ?
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
              : state.connection ?
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
                child: !state.connection
                    ?
                GestureDetector(
                    onTap: () {
                      showMessage(context);
                    },
                    child: const Icon(Icons.person))
                    :
                GestureDetector(
                  onTap: () async {
                    final toProfilePage = navigateTo(context, const Profile());
                    final blocProvider = BlocProvider.of<HomeBloc>(context);
                    final initEvent = InitStateEvent(context);

                    if(await checkConnection()){
                      blocProvider.add(ChangeConnection(true));
                      toProfilePage;
                    }
                    else{
                      blocProvider.add(initEvent);
                      if (context.mounted) {
                        showMessage(context);
                      }
                    }
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
