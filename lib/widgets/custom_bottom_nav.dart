import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveHelper.getAdaptiveButtonHeight(context) + 16,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveWidth(context, 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bouton S pour l'écran 1 (remplacé par une image)
          GestureDetector(
            onTap: () => onTap(0),
            child: Image.asset(
              'assets/images/leSmenu.png',
              height: ResponsiveHelper.responsiveFontSize(context, 32),
              color: currentIndex == 0 ? const Color(0xFF2196F3) : Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),

          // Bouton Chat pour l'écran 2
          GestureDetector(
            onTap: () => onTap(1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: currentIndex == 1
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withAlpha(26),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: currentIndex == 1 ? Color(0xFF2196F3) : Colors.grey[400],
                size: ResponsiveHelper.responsiveFontSize(context, 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}