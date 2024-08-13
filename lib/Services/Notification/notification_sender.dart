import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotification {
  //START FROM HERE---------------------------------------------------------------------------------------------------

  static Future<void> toSpecific(String title, String body, String token, String screen) async{
    try{
      await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=AAAAsHpy7ew:APA91bF-N6OoXioXIS8bU3QU8bBVinY-uMJ8sSnZOVAGzb85949jiTxfo5gEoAAMT1PG-UnIyqUBKGGubH7mOiawx8JUKcp2bdMn9MEMCDfurphhc87sX2D3H3edhayK1sXVDudKBwA7'
          },
          body: jsonEncode(
              <String, dynamic> {
                'priority': 'high',
                'data': <String, dynamic>{
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'status': 'done',
                  'body': body,
                  'title': title,
                  'screen': screen,
                },
                'notification': <String, dynamic>{
                  'body': body,
                  'title': title,
                  'android_channel_id': 'splitshare'
                },
                'to': token,
              }
          )
      );
    }catch(e) {
      if(kDebugMode) {
        print('Error in Push Notification');
      }
    }
  }

  static Future<void> toAll(String title, String body, String screen) async{
    CollectionReference collectionReference =
    FirebaseFirestore
        .instance
        .collection('/userTokens');

    final snapshot = await collectionReference.get();
    for (int i=0; i < snapshot.size; i++) {
      String token = snapshot.docs[i].get('token');
      toSpecific(title, body, token, screen);
    }
  }
//---------------------------------------------------------------------------------------------------
}