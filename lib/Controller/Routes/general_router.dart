import 'package:flutter/material.dart';

void navigateTo(BuildContext context, Widget page, {TransitionType type = TransitionType.slide}) {
  Navigator.of(context).push(_createRoute(page, type: type));
}

Route _createRoute(Widget page, {TransitionType type = TransitionType.slide}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case TransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
        case TransitionType.scale:
          return ScaleTransition(scale: animation, child: child);
        case TransitionType.rotation:
          return RotationTransition(turns: animation, child: child);
        case TransitionType.slide:
        default:
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
      }
    },
  );
}

enum TransitionType {
  fade,
  scale,
  rotation,
  slide,
}