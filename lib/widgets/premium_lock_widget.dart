import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../screens/premium_screen.dart';
import '../utils/app_theme.dart';
import 'dart:ui';

class PremiumLockOverlay extends StatefulWidget {
  final String feature;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onUnlock;
  final Widget child;

  const PremiumLockOverlay({
    super.key,
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.onUnlock,
  });

  @override
  State<PremiumLockOverlay> createState() => _PremiumLockOverlayState();
}

class _PremiumLockOverlayState extends State<PremiumLockOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _parallaxController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _parallaxAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Animation de slide plus sophistiquée
    _slideAnimation = Tween<double>(
      begin: 150.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    
    // Animation de fade
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    // Animation de scale avec effet élastique
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    // Animation de parallaxe
    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _parallaxController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SubscriptionService().canAccessFeature(widget.feature),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final hasAccess = snapshot.data ?? false;
        
        if (hasAccess) {
          return widget.child;
        }
        
        return Stack(
          children: [
            // Contenu original avec effet glassmorphism et parallaxe
            AnimatedBuilder(
              animation: _parallaxController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _parallaxAnimation.value * 10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
              child: Opacity(
                        opacity: 0.2,
                        child: widget.child,
              ),
                    ),
                  ),
                );
              },
            ),
            
            // Overlay de verrouillage en bas avec animation sophistiquée
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
              child: _buildLockWidget(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          // Effet de bordure lumineuse
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.onUnlock != null) {
                  widget.onUnlock!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Débloquer Premium',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '3 jours d\'essai gratuit inclus',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 