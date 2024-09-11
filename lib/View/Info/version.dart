import 'package:flutter/material.dart';

Widget version() {
  return const Padding(
    padding: EdgeInsets.only(top: 50),
    child: Center(
      child: Text(
        'Version 6.2.2',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    ),
  );
}