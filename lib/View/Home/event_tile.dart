import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../../Controller/Routes/general_router.dart';
import '../CRUD/crud_event.dart';

Widget eventTile(String docID, String title, String description ,
    double amount, DateTime time, String addedBy, String providerName,
    String providerImageUrl, HomeBlocState state,BuildContext context ) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: ListTile(
      onTap: () {
        navigateTo(
            context,
            CRUDEvent(
              title: title,
              amount: amount.toString(),
              description: description,
              provider: providerName,
              docID: docID,
              time: time.toString(),
            ));
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
      subtitle: Text(
        DateFormat('hh:mm a, EE, dd MMM,yy')
            .format(time),
        style: const TextStyle(
            color: Colors.grey,
            overflow: TextOverflow.ellipsis),
      ),
      trailing: Text(
        amount.toStringAsFixed(0),
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            overflow: TextOverflow.ellipsis),
      ),
      dense: true,
      tileColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
      ),
    ),
  );
}