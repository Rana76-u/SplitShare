import 'package:hive/hive.dart';
import '../Models/Hive/Event/hive_event_model.dart';

class HiveApi {
  Future<void> saveOrUpdateEvent(Event event) async {
    final box = Hive.box<Event>('events');
    box.put(event.id, event); // The id is used as the key
  }

  Future<Event?> getEvent(String id) async {
    var box = await Hive.box<Event>('events');

    // Find the event with the specified ID
    Event? event = box.values.firstWhere((event) => event.id == id);
    return event;
  }

  updateAnEvent(Event event, String title, String description, double amount,
      DateTime time, String addedBy, String providerID, String providerName,
      String docID, String action) async {

      // Update the event's fields
    Event event = Event(id: docID, title: title, description: description,
        amount: amount, time: time, addedBy: addedBy,
        providedBy: providerID, providerName: providerName, action: action);

      // Save the updated event back to the box
      //await event.save();
    saveOrUpdateEvent(event);
  }
}