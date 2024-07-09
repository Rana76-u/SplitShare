
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/Calculation/calculation_api.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import '../../API/check_connection.dart';
import '../../Models/Hive/Event/hive_event_model.dart';

// Todo
/*The list represents the calculation of the total spending of each participant and
below each participant's list shows how much money that participant will get from others.*/

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key});

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  bool _isLoading = false;
  //bool connection = false;

  double total = 0.0;
  double perPerson = 0.0;

  List<double> amounts = [];
  List<String> providerNames = [];
  List<String> providerIDs = [];




  //uid, uname
  Map<String, String> userNames = {};
  //uid, url
  Map<String, String> userImageUrls = {};
  //uid, amount
  Map<String, double> totalOfIndividuals = {};

  //uid, balance
  Map<String, double> biggestReceivers = {};
  Map<String, double> biggestGivers = {};

  List<String> splitLogs = [];

  @override
  void initState() {
    _isLoading = true;
    setConnection();
    getSavedData();
    super.initState();
  }

  void setConnection() async {
    bool connectionStatus = await checkConnection();
    setState(() {
      connection = connectionStatus;
    });
  }

  Future<void> getSavedData() async {
    List<String> tempUserNames = [];
    List<String> tempUserIDs = [];
    List<String> tempUserImageUrls = [];

    amounts.clear();
    providerIDs.clear();
    providerNames.clear();

    //load all the event data
    final eventBox = Hive.box<Event>('events');
    final events = eventBox.values.toList();
    for (var event in events) {
      if(event.action != 'delete'){
        amounts.add(event.amount);
        providerIDs.add(event.providedBy);
        providerNames.add(event.providerName);
      }
    }

    //load user data from Hive
    tempUserIDs = await TripInfoManager().getTripUserIDs();
    tempUserNames = await TripInfoManager().getUserNames();
    tempUserImageUrls = await TripInfoManager().getUserImageUrls();

    //assign them in MAP
    for(int i=0; i<tempUserIDs.length; i++){
      userNames[tempUserIDs[i]] = tempUserNames[i];
      userImageUrls[tempUserIDs[i]] = tempUserImageUrls[i];
    }


    getTotal();

    setState(() {
      _isLoading = false;
    });
  }

  void getTotal() {
    //total Spending
    for (int i = 0; i < amounts.length; i++) {
      total = total + amounts[i];
    }

    //Per Person
    perPerson = total / userNames.length;

    //total of individual
    double tempTotal = 0.0;
    for (int i = 0; i < userNames.length; i++) {
      for (int j = 0; j < amounts.length; j++) {
        if (userNames.keys.elementAt(i) == providerIDs[j]) {
          tempTotal = tempTotal + amounts[j];
        }
      }
      //totalOfIndividuals.add(tempTotal);
      totalOfIndividuals[userNames.keys.elementAt(i)] = tempTotal;
      if(tempTotal >= perPerson){
        biggestReceivers[userNames.keys.elementAt(i)] = tempTotal;
      }
      else{
        biggestGivers[userNames.keys.elementAt(i)] = tempTotal;
      }
      tempTotal = 0.0;
    }

    //getSplitterLog();
    ///splitCost(totalOfIndividuals);
    biggestTheorem();
  }

  void biggestTheorem() {

    biggestReceivers = CalculationAPI().sortAMap(biggestReceivers, perPerson);
    biggestGivers = CalculationAPI().sortAMap(biggestGivers, perPerson);

    int receiversFlagIndex = 0;
    int giversFlagIndex = 0;

    //until the i is not> the length of the list of biggest Receivers
    while(giversFlagIndex < biggestGivers.keys.length && receiversFlagIndex < biggestReceivers.keys.length){
      double receiverBalance = biggestReceivers.values.elementAt(receiversFlagIndex); //2368
      double giverBalance = biggestGivers.values.elementAt(giversFlagIndex); //2409

      //get uid of receiver and giver
      String receiverUid = biggestReceivers.keys.elementAt(receiversFlagIndex);
      String giverUid = biggestGivers.keys.elementAt(giversFlagIndex);

      double remainingAmount = receiverBalance.floorToDouble() - giverBalance.floorToDouble();

      // > 0 means Receiver still owns money, and biggest giver has giver all his money
      if(remainingAmount > 0){
        //Set Biggest Receiver balance = remaining amount;
        biggestReceivers[receiverUid] = remainingAmount; //2368

        //giver will give receiver it's full balance
        splitLogs.add('$giverUid will give $receiverUid : ${giverBalance.toStringAsFixed(1)} Tk');

        //now, biggest giver has 0 money
        biggestGivers[giverUid] = 0;

        //Shift Biggest Giver to next person
        giversFlagIndex++;
      }
      // < 0 means Receiver money fulfilled, and biggest giver has remaining money
      else{
        //giver will give receiver it's (Givers Original Balance - remaining amount)
        splitLogs.add('$giverUid will give $receiverUid : ${(giverBalance - remainingAmount.abs()).toStringAsFixed(1)} Tk'); //2409 - 41

        biggestReceivers[receiverUid] = 0;
        biggestGivers[giverUid] = remainingAmount.abs(); //41

        receiversFlagIndex++;
      }
    }
  }

/*  void getSplitterLog() {
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
  }*/

 /*void splitCost(List<double> expenses) {
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
          //user1 is in negative and user2 is in positive
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
  }*/

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        Get.to(() => BottomBar(bottomIndex: 0), transition: Transition.fade);
      },
      child: Scaffold(
        appBar: const HomeAppBar(
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
                      const SizedBox(height: 5,),
                      const Text("The list represents the calculation of the total spending of each participant and "
                          "below each participant's list shows how much money that participant will get from others.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 11
                      ),),
                      const SizedBox(height: 5,),
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
                  visible: connection && userImageUrls.values.elementAt(index) != '' || userImageUrls.values.elementAt(index).isNotEmpty,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      height: 35,
                      child: Image.network(userImageUrls.values.elementAt(index)),
                    ),
                  ),
                ),
                title: Text(
                  userNames.values.elementAt(index),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
                trailing: Text(
                  '${totalOfIndividuals.values.elementAt(index)}/-',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      overflow: TextOverflow.ellipsis,
                      color: totalOfIndividuals.values.elementAt(index) >= perPerson
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
                color: const Color(0xFF023047),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: splitLogs.length,
                  itemBuilder: (context, splitLogIndex) {
                    if (splitLogs[splitLogIndex]
                        .contains("will give ${userNames.keys.elementAt(index)}")) {

                      String userName = userNames[splitLogs[splitLogIndex].substring(0, 28)]!;

                      String imageUrl = userImageUrls[splitLogs[splitLogIndex].substring(0, 28)]!;

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
