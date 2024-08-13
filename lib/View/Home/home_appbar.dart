import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';
import 'package:splitshare_v3/Services/Utility/check_connection.dart';
import 'package:splitshare_v3/View/Home/search_filter_widget.dart';
import 'package:splitshare_v3/View/Profile/profile.dart';
import 'package:splitshare_v3/Widgets/snack_bar.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_event.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeBlocState state;
  const HomeAppBar({super.key, required this.state});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (state.connection ? 100 : 110) );

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
          searchAndFilterWidget(context, state),
        ],
      ),
      actions: [
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
                    final blocProvider = BlocProvider.of<HomeBloc>(context);

                    if(await checkConnection()){
                      blocProvider.add(ChangeConnection(true));
                      Get.to(() => const Profile(),);
                    }
                    else{
                      blocProvider.add(InitStateEvent());
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
