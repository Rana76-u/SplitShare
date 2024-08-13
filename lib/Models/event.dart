
class EventModel {
  final String docID;
  final String title;
  final String description;
  final double amount;
  final DateTime time;
  final String adderID;
  final String providerID;
  final String providerName;
  final String action;

  EventModel({
    required this.docID,
    required this.title,
    required this.description,
    required this.amount,
    required this.time,
    required this.adderID,
    required this.providerID,
    required this.providerName,
    required this.action
  });
}