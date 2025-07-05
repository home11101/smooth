import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Dimensions responsives basées sur la largeur de l'écran
  static double responsiveWidth(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }
  
  // Dimensions responsives basées sur la hauteur de l'écran
  static double responsiveHeight(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }
  
  // Taille de police responsive
  static double responsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return baseSize * 0.8; // Petit écran
    if (screenWidth < 480) return baseSize; // Écran moyen
    return baseSize * 1.2; // Grand écran
  }
  
  // Padding responsive
  static EdgeInsets responsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return const EdgeInsets.all(12);
    if (screenWidth < 480) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }
  
  // Marges responsives
  static EdgeInsets responsiveMargin(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return const EdgeInsets.symmetric(horizontal: 8);
    if (screenWidth < 480) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 24);
  }
  
  // Espacement vertical responsive
  static double responsiveSpacing(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) return 8;
    if (screenHeight < 800) return 12;
    return 16;
  }
  
  // Vérifier si c'est un petit écran
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 320;
  }
  
  // Vérifier si c'est un écran moyen
  static bool isMediumScreen(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width >= 320 && width < 480;
  }
  
  // Vérifier si c'est un grand écran
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 480;
  }
  
  // Obtenir la taille de police adaptée
  static double getAdaptiveFontSize(BuildContext context, {
    double small = 12,
    double medium = 14,
    double large = 16,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }
  
  // Obtenir la hauteur de bouton adaptée
  static double getAdaptiveButtonHeight(BuildContext context) {
    if (isSmallScreen(context)) return 40;
    if (isMediumScreen(context)) return 44;
    return 48;
  }
  
  // Obtenir le padding de bouton adapté
  static EdgeInsets getAdaptiveButtonPadding(BuildContext context) {
    double horizontal = isSmallScreen(context) ? 12 : 16;
    double vertical = isSmallScreen(context) ? 8 : 12;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}
