import 'package:flutter/material.dart';

class AllTogetherColors {
  // Colors derived from logo/mascot
  static const Color mascotOrange = Color(0xFFFF8C00); // Vibrant orange face
  static const Color breakfastBrown = Color(0xFF8B4513); // Saddle Brown
  static const Color lunchBlue = Color(0xFF1E90FF);    // Dodger Blue
  static const Color dinnerOrange = Color(0xFFFF4500);   // Orange Red
  static const Color snackGreen = Colors.green;        // Existing green

  static Color getMealColor(String type) {
    if (type.toLowerCase().contains('breakfast')) return breakfastBrown;
    if (type.toLowerCase().contains('lunch')) return lunchBlue;
    if (type.toLowerCase().contains('dinner')) return dinnerOrange;
    return snackGreen;
  }
}
