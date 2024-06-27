
import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMessage(BuildContext context) {
  return ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 3),
      content: Text("You're Offline"))
  );
}