import 'package:hive/hive.dart';

part 'hive_event_model.g.dart';

@HiveType(typeId: 0, adapterName: 'EventAdapter')
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime time;

  @HiveField(5)
  String addedBy;

  @HiveField(6)
  String providedBy;

  @HiveField(7)
  String providerName;

  @HiveField(8)
  String action; //save update or delete actions
  //none, update, delete

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.time,
    required this.addedBy,
    required this.providedBy,
    required this.providerName,
    required this.action
  });
}
