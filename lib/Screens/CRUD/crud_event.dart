import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitshare_v3/API/check_connection.dart';
import 'package:splitshare_v3/API/hive_api.dart';
import 'package:splitshare_v3/API/notification_sender.dart';
import 'package:splitshare_v3/Models/manage_crud_operations.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Widgets/loading.dart';

import '../../API/user_api.dart';
import '../../Models/Hive/Event/hive_event_model.dart';
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
  //bool connection = false;

  int selectedProviderFlag = -1;

  String? tripCode;
  String tripName = '';

  String selectedUserID = '';
  String selectedUserName = '';
  List<String>? userNames = [];
  List<String>? userImageURLs = [];
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
    connection = await checkConnection();

    userNames = await TripInfoManager().getUserNames();
    userImageURLs = await TripInfoManager().getUserImageUrls();
    userIDs = await TripInfoManager().getTripUserIDs();
    tripCode = await TripInfoManager().getTripCode();
    tripName = await TripInfoManager().getTripName();

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

    String newID = UserApi().generateUID();

    final messenger = ScaffoldMessenger.of(context);
    //final prefs = await SharedPreferences.getInstance();

    //String? tripCode = prefs.getString('tripCode');

    if (amountController.text.isEmpty) {
      setState(() {
        amountFLag = true;
      });

      messenger.showSnackBar(const SnackBar(content: Text('Input Amount*')));
    }
    else if (selectedUserID == '') {
      setState(() {
        providerFlag = true;
      });

      messenger.showSnackBar(
          const SnackBar(content: Text('Please Select A Provider')));
    }
    else {
      if(await InternetConnectionChecker().hasConnection) {
        await ManageCRUDOperations().uploadInfo(
            titleController.text,
            descriptionController.text,
            double.parse(amountController.text),
            selectedUserID,
            userNames![selectedProviderFlag],
            widget.docID ?? 'new - $newID',
            tripCode!);
      }
      else{
        await ManageCRUDOperations().saveOffline(
            titleController.text,
            descriptionController.text,
            double.parse(amountController.text),
            selectedUserID,
            userNames![selectedProviderFlag],
            widget.docID ?? 'new - $newID',
            tripCode!);
      }

      // Send Notification
      if (await InternetConnectionChecker().hasConnection) {
        String token = '';

        for (int i = 0; i < userIDs!.length; i++) {
          try {
            final tokenSnapshot = await FirebaseFirestore.instance
                .collection('userTokens')
                .doc(userIDs![i])
                .get();

            // Check if the document exists
            if (tokenSnapshot.exists) {
              token = tokenSnapshot.get('token');

              await SendNotification.toSpecific(
                  "${userNames![selectedProviderFlag]} To $tripName",
                  titleController.text,
                  token,
                  "HomePage"
              );
            }
          } catch (e) {
            // Handle the exception if needed
            if (kDebugMode) {
              print('User ID ${userIDs![i]} does not exist in userTokens collection');
            }
          }
        }
      }

    }

    setState(() {
      _isLoading = false;
    });

    Get.to(() => BottomBar(bottomIndex: 0), transition: Transition.fade);
  }

  @override
  Widget build(BuildContext context) {
    Loading loading = Loading();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Get.to(() => BottomBar(bottomIndex: 0), transition: Transition.fade);
            },
              child: const Icon(Icons.arrow_back)
          ),
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
                                      child: Row(
                                        children: [
                                          //image
                                          connection && (userImageURLs![index] != '' || userImageURLs![index].isNotEmpty) ?
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(50),
                                            child: Image.network(userImageURLs![index]),
                                          ) : const SizedBox(),

                                          //normal space
                                          connection && (userImageURLs![index] != '' || userImageURLs![index].isNotEmpty) ?
                                          const SizedBox(width: 5,) : const SizedBox(),

                                          //name
                                          Text(
                                            userNames![index],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: selectedProviderFlag == index
                                                    ? Colors.white
                                                    : Colors.black
                                            ),
                                          )
                                        ],
                                      )
                                  ),
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
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem(
            value: "Delete",
            onTap: () {
              //if you creating new post, you can't delete
              if(widget.docID != null){
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
                            final navigator = Navigator.pop(context);
                            setState(() {
                              _isLoading = true;
                            });
                            // Dismiss the dialog
                            if (mounted) {
                              navigator;
                            }
                            // Perform the delete action
                            if (await InternetConnectionChecker().hasConnection) {
                              await ManageCRUDOperations().deleteEventFromDB(widget.docID!, tripCode!);
                              await ManageCRUDOperations().deleteFromSave(widget.docID!);
                            }
                            else {
                              Event? event = await HiveApi().getEvent(widget.docID!);
                              await HiveApi().updateAnEvent(
                                  event!, event.title, event.description, event.amount, event.time,
                                  event.addedBy, event.providedBy, event.providerName, event.id, 'delete');
                            }

                            setState(() {
                              _isLoading = false;
                            });
                            //to home
                            Get.to(
                                    () => BottomBar(bottomIndex: 0),
                                transition: Transition.fade
                            );
                          },
                          child: const Text("Delete"),
                        ),
                      ],
                    );
                  },
                );
              }
              //if the docId is null that means creating new post
              else{
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    duration: Duration(seconds: 3),
                    content: Text("The post hasn't been created yet"))
                );
              }
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
