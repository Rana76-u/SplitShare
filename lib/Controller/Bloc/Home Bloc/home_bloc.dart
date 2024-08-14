import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_event.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';
import 'package:splitshare_v3/Models/event.dart';
import 'package:splitshare_v3/Models/user.dart';
import 'package:splitshare_v3/Services/Data/offline_data_handler.dart';

import '../../../Services/Utility/check_connection.dart';

class HomeBloc extends Bloc<HomeBlocEvent, HomeBlocState> {
  HomeBloc() : super(HomeBlocState(
    isSearching: false,
    isLoading: true,
    isBackupInProgress: false,
    connection: false,
    selectedUserID: '',
    tripCode: '',
    titles: [],
    descriptions: [],
    amounts: [],
    times: [],
    providerNames: [],
    providerIDs: [],
    docIDs: [],
    userNames: [],
    userImageUrls: [],
    userIDs: [],
    searchController: TextEditingController(text: ''),
    totalOfSelectedPerson: 0
  )) {
    on<InitStateEvent>((event, emit) async {
      bool connection = await checkConnection();
      String tripCode = await OfflineDataHandler().getTripCode();
      List<EventModel> eventList = await OfflineDataHandler().getAllSaveEventsData();

      /*if(connection == false) {
        eventList = await OfflineDataHandler().getAllSaveEventsData();
      }*/

      List<UserModel> userList = await OfflineDataHandler().getUserInfo(tripCode, event.context);

      emit(state.copyWith(
          connection: connection,
          tripCode: tripCode,
          isLoading: false,
          docIDs: eventList.map((e) => e.docID).toList(),
          titles: eventList.map((e) => e.title).toList(),
          descriptions: eventList.map((e) => e.description).toList(),
          amounts: eventList.map((e) => e.amount.toString()).toList(),
          times: eventList.map((e) => e.time.toString()).toList(),
          providerNames: eventList.map((e) => e.providerName).toList(),
          providerIDs: eventList.map((e) => e.providerID).toList(),
          userNames: userList.map((e) => e.name).toList(),
          userIDs: userList.map((e) => e.userId).toList(),
          userImageUrls: userList.map((e) => e.imageUrl).toList(),
      ));
    });

    on<SelectedUserID>((event, emit) {
      double tempTotal = 0;

      for(int i=0; i<state.amounts.length; i++){
        if(event.userID == state.providerIDs[i]){
          tempTotal = tempTotal + double.parse(state.amounts[i]);
        }
      }

      emit(state.copyWith(
        selectedUserID: event.userID,
        totalOfSelectedPerson: tempTotal
      ));
    } );

    on<ChangeConnection>((event, emit) => emit(state.copyWith(connection: event.connection)));

    on<ChangeSearchControllerText>((event, emit) => emit(state.copyWith(
        searchController: TextEditingController(text: event.searchText))));
  }
}