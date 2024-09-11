import 'package:flutter/material.dart';

import 'package:splitshare_v3/View/CRUD/crud_event.dart';

import '../../Controller/Routes/general_router.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: FittedBox(
        child: FloatingActionButton.extended(
          onPressed: () {
            navigateTo(context, CRUDEvent());
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          label: const Text(
            'Add Expense',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15
            ),
          ),
          icon: const Icon(
              Icons.add_circle
          ),
        ),
      ),
    );
  }
}
