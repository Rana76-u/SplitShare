import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';

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

  List<String> titles = [];
  List<String> descriptions = [];
  List<String> amounts = [];
  List<String> times = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];
  List<String> docIDs = [];
  List<String> isChanged = [];
  List<String> userNames = [];
  List<String> userIDs = [];
  List<int> searchIndexes = [];

  List<double> totalOfIndividuals = [];
  List<String> splitLogs = [];

  @override
  void initState() {
    _isLoading = true;
    checkConnection();
    getDataFromSharedPreferences();
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

  Future<void> getDataFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    userNames = prefs.getStringList('userNames')!;
    userIDs = prefs.getStringList('userIDs')!;
    providerNames = prefs.getStringList('providerNames')!;
    isChanged = prefs.getStringList('isChanged')!;

    titles = prefs.getStringList('titles')!;
    descriptions = prefs.getStringList('descriptions')!;
    amounts = prefs.getStringList('amounts')!;
    times = prefs.getStringList('times')!;
    providerIDs = prefs.getStringList('providerIDs')!;
    docIDs = prefs.getStringList('docIDs')!;

// Create a list of Map entries to associate each item with its time
    List<Map<String, dynamic>> itemsWithTimes = [];

    for (int i = 0; i < times.length; i++) {
      itemsWithTimes.add({
        'title': titles[i],
        'description': descriptions[i],
        'amount': amounts[i],
        'time': DateTime.parse(times[i]),
        'providerName': providerNames[i],
        'providerID': providerIDs[i],
        'docID': docIDs[i],
        'isChanged': isChanged[i],
      });
    }

// Sort the list by time
    itemsWithTimes.sort((a, b) => b['time'].compareTo(a['time']));

// Update the lists with sorted data
    titles = itemsWithTimes.map((item) => item['title'].toString()).toList();
    descriptions =
        itemsWithTimes.map((item) => item['description'].toString()).toList();
    amounts = itemsWithTimes.map((item) => item['amount'].toString()).toList();
    times = itemsWithTimes.map((item) => item['time'].toString()).toList();
    providerNames =
        itemsWithTimes.map((item) => item['providerName'].toString()).toList();
    providerIDs =
        itemsWithTimes.map((item) => item['providerID'].toString()).toList();
    docIDs = itemsWithTimes.map((item) => item['docID'].toString()).toList();
    isChanged =
        itemsWithTimes.map((item) => item['isChanged'].toString()).toList();

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
      for (int j = 0; j < titles.length; j++) {
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
                onTap: () {
                  /*Get.to(
                      () => CRUDEvent(
                    title: titles[index],
                    amount: amounts[index].toString(),
                    description: descriptions[index],
                    provider: providerNames[index],
                    docID: docIDs[index],
                  ),
                  transition: Transition.fade
              );*/
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: const Icon(Icons.person),
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

                      String amount = splitLogs[splitLogIndex]
                          .substring(68, splitLogs[splitLogIndex].length);

                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$userName will give : $amount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.clip),
                            )
                          ],
                        ),
                      );
                    } else {
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
