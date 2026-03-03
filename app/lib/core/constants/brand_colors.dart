import 'package:flutter/material.dart';

class AllTogetherColors {
  // Colors derived from logo/mascot
  static const Color mascotOrange = Color(0xFFFF7F27); // From logo face
  static const Color mascotBlue = Color(0xFF4D6FFF);   // From logo eyes/mouth
  static const Color mascotGrey = Color(0xFF555555);   // From logo pupils
  
  static const Color breakfastBrown = Color(0xFF704214); // Sepia/Brown
  static const Color lunchBlue = Color(0xFF4D6FFF);      // Matching mascot eyes
  static const Color dinnerOrange = Color(0xFFFF7F27);   // Matching mascot face
  static const Color snackGreen = Color(0xFF4CAF50);     // Material Green

  static Color getMealColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('breakfast') || t.contains('_b')) return breakfastBrown;
    if (t.contains('lunch') || t.contains('_l')) return lunchBlue;
    if (t.contains('dinner') || t.contains('_d')) return dinnerOrange;
    return snackGreen;
  }
}
