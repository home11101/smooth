import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryPurple = Color(0xFF8E44AD);
  static const Color secondaryBlue = Color(0xFF29B6F6);
  static const Color lightBlue = Color(0xFFD4EFFB);
  static const Color lightBlueBorder = Color(0xFFBFE6FB);
  static const Color darkBlue = Color(0xFF2F6DF2);
  static const Color lightCyan = Color(0xFF62CEF5);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color textPrimary = Color(0xFF4A4A4A);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color backgroundLight = Color(0xFFF2F6FA);
  static const Color dividerColor = Color(0xFFB0B0B0);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color accentColor = Color(0xFF3498DB);
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );
  
  // Dégradé de fond principal (identique à PickupLineScreen)
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFf5f7fa),
      Color(0xFFc3cfe2),
    ],
  );
  
  // Effets de lumière colorés pour le fond (composants réutilisables)
  static const Gradient lightEffect1 = RadialGradient(
    center: Alignment(-0.6, 0),
    radius: 1.0,
    colors: [
      Color(0x4D7877C6),
      Colors.transparent,
    ],
  );
  
  static const Gradient lightEffect2 = RadialGradient(
    center: Alignment(0.6, -0.6),
    radius: 1.0,
    colors: [
      Color(0x33FF77C6),
      Colors.transparent,
    ],
  );
  
  static const Gradient lightEffect3 = RadialGradient(
    center: Alignment(-0.2, 0.6),
    radius: 1.0,
    colors: [
      Color(0x3378DBFF),
      Colors.transparent,
    ],
  );
  
  // Stack complet du fond (prêt à l'emploi)
  static List<Widget> get backgroundEffects => [
        Positioned.fill(
          child: Container(decoration: BoxDecoration(gradient: mainBackgroundGradient)),
        ),
        Positioned.fill(
          child: Container(decoration: BoxDecoration(gradient: lightEffect1)),
        ),
        Positioned.fill(
          child: Container(decoration: BoxDecoration(gradient: lightEffect2)),
        ),
        Positioned.fill(
          child: Container(decoration: BoxDecoration(gradient: lightEffect3)),
        ),
      ];
      
  static const BoxDecoration pickupScreenDecoration = BoxDecoration(
    gradient: mainBackgroundGradient,
  );
  
  static Widget buildPickupScreenBackground({Widget? child}) {
    return Stack(
      children: [
        ...backgroundEffects,
        if (child != null) child,
      ],
    );
  }

  // Dégradés supplémentaires
  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF4CAF50)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorColor, Color(0xFFFF5252)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningColor, Color(0xFFFFA000)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );

  // Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'SF Pro Display',
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFE4EC),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    
    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Cartes
    cardTheme: CardTheme(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withAlpha(26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );

  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'SF Pro Display',
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFE4EC),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    
    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Cartes
    cardTheme: CardTheme(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(77),
      color: Colors.white.withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withAlpha(26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}