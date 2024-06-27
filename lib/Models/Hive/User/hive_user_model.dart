import 'package:hive/hive.dart';

part 'hive_user_model.g.dart';

@HiveType(typeId: 1, adapterName: 'UserAdapter')
class UserClass extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String imageUrl;

  UserClass({
    required this.uid,
    required this.name,
    required this.imageUrl,
  });
}
