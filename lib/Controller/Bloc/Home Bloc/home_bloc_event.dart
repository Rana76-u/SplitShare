
import 'package:flutter/cupertino.dart';

abstract class HomeBlocEvent{}

class InitStateEvent extends HomeBlocEvent {
  final BuildContext context;
  InitStateEvent(this.context);
}

class IsLoading extends HomeBlocEvent {}

class SelectedUserID extends HomeBlocEvent {
  final String userID;
  SelectedUserID(this.userID);
}

class ChangeConnection extends HomeBlocEvent {
  final bool connection;
  ChangeConnection(this.connection);
}

class ChangeSearchControllerText extends HomeBlocEvent {
  final String searchText;
  ChangeSearchControllerText(this.searchText);
}