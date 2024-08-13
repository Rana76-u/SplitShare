
abstract class HomeBlocEvent{}

class InitStateEvent extends HomeBlocEvent {}

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