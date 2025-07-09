import 'package:flutter/material.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final double height;

  const ModernAppBar({
    super.key,
    this.onMenuPressed,
    this.actions,
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu, color: Colors.black, size: 24),
        ),
        onPressed: onMenuPressed,
      ),
      centerTitle: true,
      title: SizedBox(
        width: 120, // Largeur réduite
        child: Image.asset(
          'assets/images/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
