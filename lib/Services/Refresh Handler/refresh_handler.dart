import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_bloc.dart';
import '../../Controller/Bloc/BottomBar Bloc/bottombar_event.dart';
import '../../Controller/Bloc/Home Bloc/home_bloc_state.dart';
import '../../Widgets/bottom_nav_bar.dart';
import '../Data/backup_data.dart';

Future<void> homeRefreshHandle(BuildContext context, HomeBlocState state) async {
  context.read<BottomBarBloc>().add(BottomBarSelectedItem(0));

  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const BottomBar(); // Return the BottomBar widget directly
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child; // You can add custom transitions here if needed
      },
    ),
  );

  await backupData(state);

  // Simulate a delay for the refresh indicator
  await Future.delayed(const Duration(seconds: 1));
}


Future<void> calculationRefreshHandle(BuildContext context, HomeBlocState state) async {
  context.read<BottomBarBloc>().add(BottomBarSelectedItem(1));

  /*Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const BottomBar(); // Return the BottomBar widget directly
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child; // You can add custom transitions here if needed
      },
    ),
  );*/

  // Simulate a delay for the refresh indicator
  await Future.delayed(const Duration(seconds: 1));
}