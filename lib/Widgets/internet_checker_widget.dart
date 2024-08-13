import 'package:flutter/material.dart';
import 'package:splitshare_v3/Controller/Bloc/Home%20Bloc/home_bloc_state.dart';

Widget internetCheckerWidget(HomeBlocState state) {
  if (state.connection == false) {
    return Container(
      color: Colors.red,
      width: double.infinity,
      child: const Text(
        "No Internet, Swipe To Refresh",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }else{
    return const SizedBox();
  }
}