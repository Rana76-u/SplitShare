import 'package:flutter/material.dart';

class Loading{

  Widget central(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width*0.4,
        child: const LinearProgressIndicator(),
      ),
    );
  }

}