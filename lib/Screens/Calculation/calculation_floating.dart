import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitshare_v3/API/PDF/pdf_invoice_api.dart';
import 'package:splitshare_v3/Models/pdf/invoice.dart';
import 'package:splitshare_v3/Models/trip_info_manager.dart';
import 'package:splitshare_v3/Screens/Calculation/viewpdf.dart';

class CalculationFloating extends StatefulWidget {
  final Map<String, double> totalOfIndividuals;
  final double total;
  final double perPerson;
  final List<String> splitLogs;

  const CalculationFloating({
    super.key,
    required this.totalOfIndividuals,
    required this.total,
    required this.perPerson,
    required this.splitLogs,
  });

  @override
  State<CalculationFloating> createState() => _CalculationFloatingState();
}

class _CalculationFloatingState extends State<CalculationFloating> {

  String parseTimestampString(String timestampString) {
    int seconds =
    int.parse(timestampString.split('seconds=')[1].split(',').first.trim());
    int nanoseconds = int.parse(
        timestampString.split('nanoseconds=')[1].split(')').first.trim());

    DateTime tempDateTime = DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + nanoseconds ~/ 1000000,
    );
    return DateFormat('hh:mm a EE, dd MMM, yyyy').format(tempDateTime).toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: FittedBox(
        child: FloatingActionButton.extended(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);

            String tripDate = parseTimestampString(await TripInfoManager().getTripDate());

            List userNames = await TripInfoManager().getUserNames();
            List userIds = await TripInfoManager().getTripUserIDs();

            String tripCreator = userNames[
              userIds.indexOf(await TripInfoManager().getTripCreator())
            ];

            final tripReport = TripReport(
              info: TripInfo(
                  tripName: await TripInfoManager().getTripName(),
                  createInfo: "Created by $tripCreator at $tripDate",
                  total: widget.total,
                  perPerson: widget.perPerson
              ),
              usersList: List.generate(
                  userNames.length,
                      (index) {

                    bool payOrReceive = widget.totalOfIndividuals.values.elementAt(index) >= widget.perPerson;
                    String tempPayReceiveAmount = (widget.totalOfIndividuals.values.elementAt(index) - widget.perPerson).abs().toStringAsFixed(1);

                    return UsersList(
                        name: userNames[index],
                        totalSpent: widget.totalOfIndividuals[userIds[index]]!,
                        payOrReceiveAmount: payOrReceive ?
                        'will receive : $tempPayReceiveAmount' :
                        'will pay : $tempPayReceiveAmount',
                        payers: List.generate(
                            widget.splitLogs.length,
                                (splitLogIndex) {
                                  if (widget.splitLogs[splitLogIndex].contains("${userIds[index]} will give ")) {
                                    String userName = userNames[userIds.indexOf(widget.splitLogs[splitLogIndex].substring(39, 67))]!;

                                    String amount = widget.splitLogs[splitLogIndex]
                                        .substring(70, widget.splitLogs[splitLogIndex].length);

                                    return PayersList(
                                        payTo: userName,
                                        amount: amount
                                    );
                                  }
                                  else{
                                    return const PayersList(
                                        payTo: '',
                                        amount: ''
                                    );
                                  }
                                }
                        )
                    );
                  }
              ),
            );

            final pdfFile = await PdfTripReportApi.generate(tripReport, await TripInfoManager().getTripName());

            messenger.showSnackBar(
                SnackBar(
                    content: Text("Report Is Saved Into Downloads Folder. Named '${await TripInfoManager().getTripName()}.pdf'")
                )
            );

            Get.to( () => ViewPDF(pdf: pdfFile),
                transition: Transition.fade
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: const Text(
            'Generate PDF Report',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15
            ),
          ),
          icon: const Icon(
              Icons.document_scanner_rounded
          ),
        ),
      ),
    );
  }
}
