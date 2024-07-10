
class TripReport {
  final TripInfo info;
  final List<UsersList> usersList;

  const TripReport({
    required this.info,
    required this.usersList,
  });
}

class TripInfo {
  final String tripName;
  final String createInfo;
  final double total;
  final double perPerson;

  const TripInfo({
    required this.tripName,
    required this.createInfo,
    required this.total,
    required this.perPerson,
  });
}

class UsersList {
  final String name;
  final double totalSpent;
  final String payOrReceiveAmount;
  final List<PayersList> payers;

  const UsersList({
    required this.name,
    required this.totalSpent,
    required this.payOrReceiveAmount,
    required this.payers,
  });
}

class PayersList {
  final String? payTo;
  final String? amount;

  const PayersList({
    required this.payTo,
    required this.amount,
  });
}
