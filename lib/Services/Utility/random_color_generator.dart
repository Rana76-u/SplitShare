import 'package:flutter/material.dart';

Color getColorFromIndex(int index) {
  // Generate a color based on the index
  final int red = (index * 10) % 256;
  final int green = (index * 20) % 256;
  final int blue = (index * 30) % 256;
  return Color.fromARGB(255, red, green, blue);
}