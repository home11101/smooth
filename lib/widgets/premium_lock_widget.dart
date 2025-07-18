import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/subscription_service.dart';
import '../services/in_app_purchase_service.dart';
import '../utils/app_theme.dart';

class PremiumLockOverlay extends StatefulWidget {
  final String feature;
  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  const PremiumLockOverlay({
    super.key,
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
  });

  @override
  State<PremiumLockOverlay> createState() => _PremiumLockOverlayState();
}

class _PremiumLockOverlayState extends State<PremiumLockOverlay> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _parallaxController;
  late final AnimationController _pulseController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _parallaxAnimation;
  late final Animation<double> _pulseAnimation;
  bool _loading = false;

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _slideAnimation = Tween<double>(
      begin: 150.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeInOut,
    ));
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _parallaxController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _parallaxController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onBuyPressed() async {
    setState(() => _loading = true);
    final purchaseService = InAppPurchaseService();
    if (purchaseService.products.isEmpty) {
      await purchaseService.loadProducts();
    }
    String feedbackMsg = '';
    bool success = false;
    if (purchaseService.products.isNotEmpty) {
      final product = purchaseService.products.first;
      try {
        await purchaseService.buyProduct(product);
        feedbackMsg = 'Achat réussi ! Vous êtes maintenant premium.';
        success = true;
      } catch (e) {
        feedbackMsg = 'Erreur lors de l\'achat : $e';
      }
    } else {
      feedbackMsg = 'Aucun abonnement disponible.';
    }
    setState(() => _loading = false);
    if (mounted && feedbackMsg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMsg),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onRestorePressed() async {
    setState(() => _loading = true);
    final purchaseService = InAppPurchaseService();
    String feedbackMsg = '';
    bool success = false;
    try {
      await purchaseService.restorePurchases();
      feedbackMsg = 'Achats restaurés avec succès !';
      success = true;
    } catch (e) {
      feedbackMsg = 'Erreur lors de la restauration : $e';
    }
    setState(() => _loading = false);
    if (mounted && feedbackMsg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMsg),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
            // Contenu original (widget.child)
            widget.child,
            // Fond flouté dismissible
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: AnimatedBuilder(
                animation: _parallaxController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _parallaxAnimation.value * 10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Lock widget animé en bas
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
    final double cardWidth = MediaQuery.of(context).size.width * 0.88;
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                // Bouton de fermeture
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xB0FFFFFF),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Carte centrale premium
                Center(
                  child: Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.25),
                          blurRadius: 60,
                          spreadRadius: 12,
                        ),
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.18),
                          blurRadius: 90,
                          spreadRadius: 32,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3), // épaisseur de la "bordure"
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(41),
                        color: Colors.black,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Badge animé
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.lightBlue, AppTheme.secondaryBlue],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(0.22),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.flash_on, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Smooth God',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Titre premium (fixe)
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.lightBlue, AppTheme.secondaryBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Envoyer la réponse parfaite',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bouton principal animé (fixe)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: cardWidth * 0.8, // 70% de la largeur de la carte
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: AppTheme.primaryGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withOpacity(0.28),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _onBuyPressed,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.lock_open, size: 20, color: Colors.white),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "S'abonner",
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w700,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Texte d'information sous le bouton
                          const Text(
                            'essai sans risque, puis 7,99€/semaine',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Liens et restauration (SUPPRIMÉ D'ICI)
                          // ... existing code ...
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Liens et restauration (sous la carte)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => launchUrlString('https://smoothia.app/contact.html'),
                  child: const Text(
                    'Contact',
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                GestureDetector(
                  onTap: () => launchUrlString('https://smoothia.app/terms.html'),
                  child: const Text(
                    'Termes',
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                GestureDetector(
                  onTap: () => launchUrlString('https://smoothia.app/privacy.html'),
                  child: const Text(
                    'Confidentialité',
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                GestureDetector(
                  onTap: _loading ? null : _onRestorePressed,
                  child: const Text(
                    'Restaurer',
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}