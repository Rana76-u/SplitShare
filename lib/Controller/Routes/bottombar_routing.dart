import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Bloc/BottomBar Bloc/bottombar_bloc.dart';

class BottomBarAnimatedPageRoute extends PageRouteBuilder {
  final Widget page;

  BottomBarAnimatedPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
      create: (_) => BottomBarBloc(),
      child: page,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Slide from right to left
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}
