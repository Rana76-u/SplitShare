import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';
import 'package:splitshare_v3/Services/Hive/hive_api.dart';
import 'package:splitshare_v3/View/Home/home_appbar.dart';
import 'package:splitshare_v3/View/Home/home_floating.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_event.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
import '../../Services/Data/backup_data.dart';
import '../../Widgets/bottom_nav_bar.dart';
import 'event_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleRefresh(BuildContext context, HomeBlocState state) async {
    context.read<BottomBarBloc>().add(BottomBarSelectedItem(0));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const BottomBar(); // Return the BottomBar widget directly
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // You can add custom transitions here if needed
        },
      ),
    );



    await backupData(state);

    // Simulate a delay for the refresh indicator
    await Future.delayed(const Duration(seconds: 1));

    // Reload the same page by pushing a new instance onto the stack
    navigator;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeBlocState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: HomeAppBar(state: state,),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: const HomeFloatingActionButton(),
            body: RefreshIndicator(
              onRefresh: () {
                _handleRefresh(context, state);
                return Future.delayed(const Duration(seconds: 1));
              },
              child: state.isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  :
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 7.5,),

                          // Events Online/Offline
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: state.connection
                                  ? loadItemFromDatabase(state) // Load from Firebase when online
                                  : loadItemFromHive(state) // Load from Hive when offline
                          ),

                          const SizedBox(height: 150,),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget loadItemFromDatabase(HomeBlocState state) {

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(state.tripCode)
          .collection('Events').orderBy('time', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No Events Yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            );
          }
          else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {

                String docID = snapshot.data!.docs[index].id;
                String title = snapshot.data?.docs[index].get('title');
                String description = snapshot.data?.docs[index].get('description');
                double amount = snapshot.data?.docs[index].get('amount');
                DateTime time = (snapshot.data?.docs[index].get('time')).toDate();
                String addedBy = snapshot.data?.docs[index].get('addedBy');
                String providedBy = snapshot.data?.docs[index].get('providedBy');

                return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('userData')
                      .doc(providedBy)
                      .get(),
                  builder: (context, providerSnapshot) {
                    String providerName = providerSnapshot.data?.get('name') ?? 'null';
                    String providerImageUrl = providerSnapshot.data?.get('imageURL') ?? 'null';

                    //Create Event object
                    Event event = Event(
                        id: docID,
                        title: title,
                        description: description,
                        amount: amount,
                        time: time,
                        addedBy: addedBy,
                        providedBy: providedBy,
                        providerName: providerName,
                        action: 'none'
                    );

                    // Save data to Hive
                    HiveApi().saveOrUpdateEvent(event);

                    if (providerSnapshot.hasData) {

                      //when no user selected
                      if (state.selectedUserID == '') {
                        //search event only when no user is selected
                        //deselect user when searchController changes value
                        //if searchController.text = '' means every title contains that
                        //also removed space for better search
                        if(title.replaceAll(' ', '')
                            .contains(state.searchController.text.toLowerCase().replaceAll(' ', ''))
                        ){
                          return eventTile(docID, title, description, amount,
                              time, addedBy, providerName, providerImageUrl, state);
                        }
                        //if nothing matches show nothing
                        else{
                          return const SizedBox();
                        }

                      }
                      //search when any user selected
                      else {
                        if(state.selectedUserID == providedBy){
                          return eventTile(docID, title, description, amount, time,
                              addedBy, providerName, providerImageUrl, state);
                        }
                        else {
                          return const SizedBox();
                        }
                      }
                    }
                    else if (providerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: LinearProgressIndicator(),
                      );
                    }
                    else {
                      return const Center(
                        child: Text('Error Loading Data'),
                      );
                    }
                  },
                );
              },
            );
          }
        }
        else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LinearProgressIndicator(),
          );
        }
        else {
          return const Center(
            child: Text('Error Loading Data'),
          );
        }
      },
    );
  }

  Widget loadItemFromHive(HomeBlocState state) {
    if (state.titles.isEmpty) {
      return const Center(
        child: Text(
          'No Events Yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      );
    }
    else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.titles.length,
        itemBuilder: (context, index) {
          if (state.selectedUserID == '') {
            //search event only when no user is selected
            //deselect user when searchController changes value
            //if searchController.text = '' means every title contains that
            //also removed space for better search
            if(state.titles[index].replaceAll(' ', '')
                .contains(state.searchController.text.toLowerCase().replaceAll(' ', ''))
            ){
              return eventTile(state.docIDs[index], state.titles[index], state.descriptions[index],
                  double.parse(state.amounts[index]), DateTime.parse(state.times[index]), '',
                  state.providerNames[index], 'null', state);
            }
            else{
              return const SizedBox();
            }
          }
          else {
            if(state.selectedUserID == state.providerIDs[index]){
              return eventTile(state.docIDs[index], state.titles[index], state.descriptions[index],
                  double.parse(state.amounts[index]), DateTime.parse(state.times[index]),
                  '', state.providerNames[index], 'null', state);
            }
            else {
              return const SizedBox();
            }
          }
        },
      );
    }
  }

}

