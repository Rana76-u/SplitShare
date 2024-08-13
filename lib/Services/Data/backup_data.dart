import 'package:hive/hive.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
import '../manage_crud_operations.dart';

Future<void> backupData(HomeBlocState state) async {
  //get all the offline event and check if the action says 'update' or not
  final box = Hive.box<Event>('events');
  List<Event> events = box.values.toList();

  for (var event in events) {
    if (event.action == 'update') {
      await ManageCRUDOperations().uploadInfo(
        event.title,
        event.description,
        event.amount,
        event.providedBy,
        event.providerName,
        event.id,
        state.tripCode,
      );

      /*if(event.id.contains('new')){
          await FirebaseFirestore
              .instance
              .collection('trips')
              .doc(tripCode)
              .collection('Events')
              .doc()
              .set({
            'title': event.title,
            'description': event.description,
            'amount': event.amount,
            'time': DateTime.now(),
            'addedBy': FirebaseAuth.instance.currentUser!.uid,
            'providedBy': event.providedBy,
          });
        }
        else{
          await FirebaseFirestore
              .instance
              .collection('trips')
              .doc(tripCode)
              .collection('Events')
              .doc(event.id)
              .update({
            'title': event.title,
            'description': event.description,
            'amount': event.amount,
            'providedBy': event.providedBy,
          });
        }*/

      //event.action = 'none';

      //await HiveApi().saveOrUpdateEvent(event);
      await ManageCRUDOperations().deleteFromSave(event.id);

    }
    else if(event.action == 'delete'){
      //means only saved in hive not DB
      if(event.id.contains('new')){
        ManageCRUDOperations().deleteFromSave(event.id);
      }
      else{
        ManageCRUDOperations().deleteEventFromDB(event.id, state.tripCode);
        ManageCRUDOperations().deleteFromSave(event.id);
      }
    }
  }
}