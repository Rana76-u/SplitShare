import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitshare_v3/Controller/Bloc/BottomBar%20Bloc/bottombar_event.dart';
import 'package:splitshare_v3/Controller/Bloc/BottomBar%20Bloc/bottombar_state.dart';

class BottomBarBloc extends Bloc<BottomBarEvent, BottomBarState> {
  BottomBarBloc() : super(BottomBarState(index: 0)) {
    on<BottomBarSelectedItem>((event, emit) {
      emit(BottomBarState(index: event.index));
    });
  }
}