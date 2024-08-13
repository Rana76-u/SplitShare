import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../CRUD/crud_event.dart';

Widget eventTile(String docID, String title, String description ,
    double amount, DateTime time, String addedBy, String providerName, String providerImageUrl, HomeBlocState state) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: ListTile(
      onTap: () {
        Get.to(
              () => CRUDEvent(
            title: title,
            amount: amount.toString(),
            description: description,
            provider: providerName,
            docID: docID,
            time: time.toString(),
          ),
          //transition: Transition.fade
        );
      },
      //user image
      leading: state.connection && (providerImageUrl != 'null' || providerImageUrl != '') ?
      SizedBox(
        height: 40,
        width: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: /*Image.network(
            providerImageUrl
          )*/ CachedNetworkImage(
            imageUrl: providerImageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ) :
      ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: const Icon(Icons.offline_bolt_rounded),
      ),
      title: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis),
      ),
      //user name
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('hh:mm a, EE, dd MMM,yy')
                .format(time),
            style: const TextStyle(
                color: Colors.grey,
                overflow: TextOverflow.ellipsis),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Provider: '),
              Expanded(
                child: Text(
                  providerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          )
        ],
      ),
      trailing: Text(
        '${amount.toStringAsFixed(0)}/-',
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            overflow: TextOverflow.ellipsis),
      ),
      tileColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
      ),
    ),
  );
}