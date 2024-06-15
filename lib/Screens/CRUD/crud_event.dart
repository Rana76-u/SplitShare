import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitshare_v3/API/notification_sender.dart';
import 'package:splitshare_v3/Models/manage_crud_operations.dart';
import 'package:splitshare_v3/Widgets/loading.dart';

import '../../Widgets/bottom_nav_bar.dart';

// ignore: must_be_immutable
class CRUDEvent extends StatefulWidget {
  String? title;
  String? amount;
  String? description;
  String? provider;
  String? docID;
  String? time;

  CRUDEvent(
      {super.key,
      this.title,
      this.amount,
      this.description,
      this.provider,
      this.docID,
      this.time});

  @override
  State<CRUDEvent> createState() => _CRUDEventState();
}

class _CRUDEventState extends State<CRUDEvent> {
  bool _isLoading = false;
  bool amountFLag = false;
  bool providerFlag = false;

  int selectedProviderFlag = -1;

  String? tripCode;
  String tripName = '';

  String selectedUserID = '';
  String selectedUserName = '';
  List<String>? userNames = [];
  List<String>? userIDs = [];

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    _isLoading = true;
    loadUsers();
    super.initState();
  }

  void loadUsers() async {
    final prefs = await SharedPreferences.getInstance();

    userNames = prefs.getStringList('userNames');
    userIDs = prefs.getStringList('userIDs');
    tripCode = prefs.getString('tripCode');
    tripName = prefs.getString('tripName')!;

    if (widget.title != null) {
      titleController.text = widget.title!;
      descriptionController.text = widget.description!;
      amountController.text = widget.amount!;

      selectedProviderFlag = userNames!.indexOf(widget.provider!);
      selectedUserID = userIDs![selectedProviderFlag];
      selectedUserName = userNames![selectedProviderFlag];
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> uploadInfo() async {
    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    //final prefs = await SharedPreferences.getInstance();

    //String? tripCode = prefs.getString('tripCode');

    if (amountController.text.isEmpty) {
      setState(() {
        amountFLag = true;
      });

      messenger.showSnackBar(const SnackBar(content: Text('Input Amount*')));
    } else if (selectedUserID == '') {
      setState(() {
        providerFlag = true;
      });

      messenger.showSnackBar(
          const SnackBar(content: Text('Please Select A Provider')));
    } else {
      await ManageCRUDOperations().uploadInfo(
          titleController.text,
          descriptionController.text,
          double.parse(amountController.text),
          selectedUserID,
          userNames![selectedProviderFlag],
          widget.docID ?? 'new',
          tripCode!);

      //Send Notification
      if (await InternetConnectionChecker().hasConnection) {
        String token = '';

        for (int i = 0; i < userIDs!.length; i++) {
          final tokenSnapshot = await FirebaseFirestore.instance
              .collection('userTokens')
              .doc(userIDs![i])
              .get();

          token = tokenSnapshot.get('token');

          await SendNotification.toSpecific(
              "${userNames![selectedProviderFlag]} To $tripName",
              titleController.text,
              token,
              "HomePage");
        }
      }

      //upload Data to Firebase
      /*if(await InternetConnectionChecker().hasConnection){
          await FirebaseFirestore
              .instance
              .collection('trips')
              .doc(tripCode)
              .collection('Events')
              .doc()
              .set({
            'title': titleController.text,
            'description': descriptionController.text,
            'amount': double.parse(amountController.text),
            'time': DateTime.now(),
            'addedBy': FirebaseAuth.instance.currentUser!.uid,
            'providedBy': selectedUserID,
          });

          Get.to(
              () => BottomBar(bottomIndex: 0),
            transition: Transition.fade
          );
      }
      else{

      }*/
      //------------------- ELSE WHAT ------------------------------
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Loading loading = Loading();

    return PopScope(
      onPopInvoked: (didPop) {
        Get.to(() => BottomBar(bottomIndex: 0), transition: Transition.fade);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            //Save Button
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ElevatedButton(
                onPressed: () async {
                  await uploadInfo();
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith(
                        (states) => const Color(0xFF8F00FF))),
                child: const Text(
                  'Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            //3Dot Icon
            popUpMenu()
          ],
        ),
        body: SingleChildScrollView(
          child: _isLoading
              ? loading.central(context)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      //title
                      textFieldWidget(titleController, 'Title'),

                      const SizedBox(
                        height: 5,
                      ),

                      //Amount
                      SizedBox(
                        height: 60,
                        child: TextField(
                          controller: amountController,
                          onChanged: (value) {
                            setState(() {
                              amountFLag = false;
                            });
                          },
                          decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            prefixIcon: const Icon(
                              Icons.onetwothree,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: amountFLag
                                ? Colors.red.shade50
                                : Colors.grey[100],
                            hintText: 'Amount',
                          ),
                          cursorColor: Colors.black,
                          keyboardType: TextInputType.number,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text('Provider'),

                      const SizedBox(
                        height: 5,
                      ),

                      //Provider Name
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color:
                              providerFlag ? Colors.red.shade50 : Colors.white,
                        ),
                        child: SizedBox(
                          height: 50,
                          //MediaQuery.of(context).size.width*0.9 - 40,
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: userNames?.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedProviderFlag = index;

                                      providerFlag = false;
                                      selectedUserID = userIDs![index];
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateColor.resolveWith(
                                            (states) =>
                                                selectedProviderFlag == index
                                                    ? Colors.deepPurple
                                                    : Colors.deepPurple
                                                        .withOpacity(0.08)),
                                  ),
                                  child: Center(
                                      child: Text(
                                    userNames![index],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedProviderFlag == index
                                            ? Colors.white
                                            : Colors.black),
                                  )),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      //Description
                      Container(
                        constraints: const BoxConstraints(
                            minHeight: 135, //135
                            maxHeight: 300),
                        child: TextField(
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          controller: descriptionController,
                          style: const TextStyle(overflow: TextOverflow.clip),
                          decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            prefixIcon: const Icon(
                              Icons.short_text_rounded,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            hintText: 'Description',
                          ),
                          cursorColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget popUpMenu() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: PopupMenuButton(
        initialValue: "Delete",
        onSelected: (String value) {
          // Handle the selected value here
          if (value == "Delete") {
            // Add your delete logic here
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem(
            value: "Delete",
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Delete"),
                    content: const Text("Are you sure you want to delete?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Dismiss the dialog
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          // Perform the delete action
                          if (await InternetConnectionChecker().hasConnection) {
                            ManageCRUDOperations()
                                .deleteEvent(widget.docID ?? "new", tripCode!);
                          } else {
                            messenger.showSnackBar(const SnackBar(
                                content: Text(
                                    "Internet Connection Required to 'Delete'")));
                          }
                          // Dismiss the dialog
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Row(
              children: [
                Icon(Icons.delete),
                Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ],
        child: const SizedBox(
          height: 35,
          width: 35,
          child: Icon(Icons.more_horiz_rounded),
        ),
      ),
    );
  }

  Widget textFieldWidget(
      TextEditingController textEditingController, String hint) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: textEditingController,
        autofocus: true,
        decoration: InputDecoration(
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          prefixIcon: const Icon(
            Icons.short_text_rounded,
            color: Colors.grey,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          hintText: hint,
        ),
        cursorColor: Colors.black,
      ),
    );
  }
}
