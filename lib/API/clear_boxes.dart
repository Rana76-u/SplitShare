import 'package:hive/hive.dart';
import '../Models/Hive/Event/hive_event_model.dart';
import '../Models/Hive/User/hive_user_model.dart';

Future<void> clearAllTheBoxes() async {
  var eventBox = Hive.box<Event>('events');
  await eventBox.clear();

  var userBox = Hive.box<UserClass>('users');
  await userBox.clear();

  var tripBox = Hive.box('tripInfo');
  await tripBox.clear();
}