import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/Calculation/calculation_api.dart';
import 'package:splitshare_v3/Screens/Calculation/calculation_floating.dart';
import 'package:splitshare_v3/Screens/Home/home_appbar.dart';
import 'package:splitshare_v3/Widgets/bottom_nav_bar.dart';
import '../../API/check_connection.dart';
import '../../Models/Hive/Event/hive_event_model.dart';


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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: CalculationFloating(
          totalOfIndividuals: totalOfIndividuals,
          total: total,
          perPerson: perPerson,
          splitLogs: splitLogs,
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

                      individualSpending(),

                      const SizedBox(height: 175,),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  //totals
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
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                userDetailRow(index),

                //to pay
                listOfPayers(index),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget userDetailRow(int index) {

    String tempPayReceiveAmount = (totalOfIndividuals.values.elementAt(index) - perPerson).abs().toStringAsFixed(1);
    bool redOrGreen = totalOfIndividuals.values.elementAt(index) >= perPerson;

    return Row(
      children: [
        Visibility(
          visible: connection && userImageUrls.values.elementAt(index) != '' || userImageUrls.values.elementAt(index).isNotEmpty,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              height: 35,
              child: Image.network(userImageUrls.values.elementAt(index)),
            ),
          ),
        ),
        const SizedBox(width: 5,),
        Text(
          userNames.values.elementAt(index),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis),
        ),
        const Spacer(),

        //amounts
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Spent ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  TextSpan(
                    text: '${totalOfIndividuals.values.elementAt(index)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: totalOfIndividuals.values.elementAt(index) >= perPerson ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  const TextSpan(
                    text: ' ',
                  ),
                  TextSpan(
                    text: 'of ${perPerson.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),

            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: redOrGreen ? 'will receive : ' : 'will pay : ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                  TextSpan(
                    text: tempPayReceiveAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: redOrGreen ? Colors.green : Colors.redAccent,
                    ),
                  ),

                  const TextSpan(
                    text: ' Tk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  //run a full check on splitLogs for every user
  Widget listOfPayers(int index) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: splitLogs.length,
      itemBuilder: (context, splitLogIndex) {
        if (splitLogs[splitLogIndex].contains("${userNames.keys.elementAt(index)} will give ")) {

          String userName = userNames[splitLogs[splitLogIndex].substring(39, 67)]!;


          String amount = splitLogs[splitLogIndex]
              .substring(70, splitLogs[splitLogIndex].length);

          return Column(
            children: [
              const Divider(
                thickness: 0.2,
                color: Colors.blueGrey,
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "Pay ",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                  ),

                  Text(
                    amount,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                    ),
                  ),

                  const Text(
                    "to",
                  ),

                  SizedBox(
                    width: 60,
                    child: Text(
                      userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ),

                ],
              )
            ],
          );
        }
        else {
          return const SizedBox();
        }
      },
    );
  }

}