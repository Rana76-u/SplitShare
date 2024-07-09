import 'package:internet_connection_checker/internet_connection_checker.dart';

bool connection = false;

Future<bool> checkConnection() async {
  return await InternetConnectionChecker().hasConnection;
}