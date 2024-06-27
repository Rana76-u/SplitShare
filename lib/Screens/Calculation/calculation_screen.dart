import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import '../../Models/Hive/Event/hive_event_model.dart';

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key});

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  bool _isLoading = false;
  bool connection = false;

  double total = 0.0;
  double perPerson = 0.0;

  List<String> amounts = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];

  List<String> userNames = [];
  List<String> userIDs = [];
  List<String> userImageUrls = [];

  List<double> totalOfIndividuals = [];
  List<String> splitLogs = [];

  @override
  void initState() {
    _isLoading = true;
    checkConnection();
    getSavedData();
    super.initState();
  }

  Future<void> checkConnection() async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (hasConnection != connection) {
      // The connection status has changed.
      setState(() {
        connection = hasConnection;
      });
    }
  }

  Future<void> getSavedData() async {
    amounts.clear();
    providerIDs.clear();
    providerNames.clear();

    //load all the event data
    final eventBox = Hive.box<Event>('events');
    final events = eventBox.values.toList();
    for (var event in events) {
      if(event.action != 'delete'){
        amounts.add(event.amount.toString());
        providerIDs.add(event.providedBy);
        providerNames.add(event.providerName);
      }
    }

    //load user data
    userIDs = await TripInfoManager().getTripUserIDs();
    userNames = await TripInfoManager().getUserNames();
    userImageUrls = await TripInfoManager().getUserImageUrls();

    getTotal();

    setState(() {
      _isLoading = false;
    });
  }

  void getTotal() {
    //total Spending
    for (int i = 0; i < amounts.length; i++) {
      total = total + double.parse(amounts[i]);
    }

    //Per Person
    perPerson = total / userNames.length;

    //total of individual
    double tempTotal = 0.0;
    for (int i = 0; i < userNames.length; i++) {
      for (int j = 0; j < amounts.length; j++) {
        if (userIDs[i] == providerIDs[j]) {
          tempTotal = tempTotal + double.parse(amounts[j]);
        }
      }
      totalOfIndividuals.add(tempTotal);
      tempTotal = 0.0;
    }

    //getSplitterLog();
    splitCost(totalOfIndividuals);
  }

  void getSplitterLog() {
    List<double> differences = [];

    //Extracts the differences between individual total and per person cost
    for (int i = 0; i < totalOfIndividuals.length; i++) {
      double difference = totalOfIndividuals[i] - perPerson;
      differences.add(difference);
    }

    // Check if all items are equal to 0
    /*while(differences.every((element) => element == 0) == false){
      for(int i=0; i<userIDs!.length; i++){
        for(int j=0; j<differences.length; j++){
          //not self and positive number
          if(i != j && differences[j] > 0){
            if(-differences[i] <= differences[j]){
              double remaining = differences[j] + differences[i];
              print("${userNames[i]} will give ${userNames[j]} ${differences[i]} Tk");
              splitLogs.add("${userIDs![i]} will give ${userIDs![j]} ${differences[i]} Tk");
              differences[j] = remaining;
              differences[i] = 0;
            }
            else{
              double remaining = differences[j] + differences[i];
              print("${userNames[i]} will give ${userNames[j]} ${differences[j]} Tk");
              splitLogs.add("${userIDs![i]} will give ${userIDs![j]} ${differences[j]} Tk");
              differences[j] = 0;
              differences[i] = remaining;
            }
          }
        }
      }
    }*/
  }

  void splitCost(List<double> expenses) {
    // Initialize a list to track the balance for each person
    List<double> balance = List.filled(expenses.length, 0);

    // Calculate the differences between individual total and per person cost
    for (int i = 0; i < expenses.length; i++) {
      balance[i] = expenses[i] - perPerson;
    }

    // Determine who owes and who receives
    for (int i = 0; i < expenses.length; i++) {
      for (int j = 0; j < expenses.length; j++) {
        if (i != j) {
          if (balance[i] < 0 && balance[j] > 0) {
            double amount =
                balance[i].abs() < balance[j] ? balance[i].abs() : balance[j];
            //print('Person ${i + 1} owes Person ${j + 1}: \$${amount.toStringAsFixed(2)}');
            splitLogs.add(
                '${userIDs[i]} will give ${userIDs[j]} ${amount.toStringAsFixed(1)} Tk');
            balance[i] += amount;
            balance[j] -= amount;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        Get.to(() => BottomBar(bottomIndex: 0), transition: Transition.fade);
      },
      child: Scaffold(
        appBar: HomeAppBar(
          connected: connection,
          isLoading: false,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      spendingCard(),
                      const SizedBox(
                        height: 10,
                      ),
                      individualSpending()
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget spendingCard() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Total Spending',
                    style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  Text(
                    'Per Person: ${perPerson.toStringAsFixed(2)}/-',
                    style: const TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
              Text(
                '$total/-',
                style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.bold,
                    fontSize: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget individualSpending() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userNames.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            children: [
              ListTile(
                leading: Visibility(
                  visible: connection && userImageUrls[index] != '' || userImageUrls[index].isNotEmpty,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      height: 35,
                      child: Image.network(userImageUrls[index]),
                    ),
                  ),
                ),
                title: Text(
                  userNames[index],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
                trailing: Text(
                  '${totalOfIndividuals[index]}/-',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      overflow: TextOverflow.ellipsis,
                      color: totalOfIndividuals[index] >= perPerson
                          ? Colors.green
                          : Colors.redAccent),
                ),
                tileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),

              Card(
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                ),
                color: Colors.blueGrey.shade300,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: splitLogs.length,
                  itemBuilder: (context, splitLogIndex) {
                    if (splitLogs[splitLogIndex]
                        .contains("will give ${userIDs[index]}")) {
                      //index of userId from splitLogs(list of givers text which contains userId)
                      int indexOfUserID = userIDs
                          .indexOf(splitLogs[splitLogIndex].substring(0, 28));

                      String userName = userNames[indexOfUserID];
                      String imageUrl = userImageUrls[indexOfUserID];

                      String amount = splitLogs[splitLogIndex]
                          .substring(68, splitLogs[splitLogIndex].length);

                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            Visibility(
                              visible: true,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: SizedBox(
                                  height: 17.5,
                                  child: connection && imageUrl != '' || imageUrl.isNotEmpty ?
                                  Image.network(imageUrl)
                                      :
                                  Icon(
                                    Icons.person,
                                    color: Colors.white.withOpacity(0.6),
                                  )
                                ),
                              ),
                            ),

                            const SizedBox(width: 5,),


                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "$userName ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: "will give ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ": $amount",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )

                          ],
                        ),
                      );
                    }
                    else {
                      return const SizedBox();
                    }
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
