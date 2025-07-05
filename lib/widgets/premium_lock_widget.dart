import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../screens/premium_screen.dart';
import '../utils/app_theme.dart';

class PremiumLockWidget extends StatelessWidget {
  final String feature;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onUnlock;

  const PremiumLockWidget({
    super.key,
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône verrouillée
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: Colors.grey.shade600,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Bouton débloquer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (onUnlock != null) {
                  onUnlock!();
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
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          
          const SizedBox(height: 12),
          
          // Texte d'information
          Text(
            '3 jours d\'essai gratuit inclus',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FeatureLockOverlay extends StatelessWidget {
  final String feature;
  final Widget child;
  final String? customMessage;

  const FeatureLockOverlay({
    super.key,
    required this.feature,
    required this.child,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SubscriptionService().canAccessFeature(feature),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final hasAccess = snapshot.data ?? false;
        
        if (hasAccess) {
          return child;
        }
        
        return Stack(
          children: [
            // Contenu original avec filtre
            Opacity(
              opacity: 0.3,
              child: child,
            ),
            
            // Overlay de verrouillage
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: PremiumLockWidget(
                  feature: feature,
                  title: _getFeatureTitle(feature),
                  description: customMessage ?? _getFeatureDescription(feature),
                  icon: _getFeatureIcon(feature),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getFeatureTitle(String feature) {
    switch (feature) {
      case 'pickup_lines':
        return 'Générateur de Phrases d\'Accroche';
      case 'chat_analysis':
        return 'Analyse de Conversations';
      case 'screenshot_analysis':
        return 'Analyse de Captures d\'Écran';
      case 'coaching':
        return 'Coaching Personnalisé';
      case 'premium_features':
        return 'Fonctionnalités Premium';
      default:
        return 'Fonctionnalité Premium';
    }
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'pickup_lines':
        return 'Générez des phrases d\'accroche personnalisées et créatives pour maximiser vos chances de succès.';
      case 'chat_analysis':
        return 'Analysez vos conversations pour identifier les points d\'amélioration et optimiser votre approche.';
      case 'screenshot_analysis':
        return 'Analysez vos captures d\'écran de conversations pour recevoir des conseils personnalisés.';
      case 'coaching':
        return 'Recevez des conseils personnalisés et des stratégies adaptées à votre style de séduction.';
      case 'premium_features':
        return 'Accédez à toutes les fonctionnalités avancées pour optimiser votre expérience de séduction.';
      default:
        return 'Cette fonctionnalité nécessite un abonnement premium.';
    }
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature) {
      case 'pickup_lines':
        return Icons.chat_bubble_outline;
      case 'chat_analysis':
        return Icons.analytics_outlined;
      case 'screenshot_analysis':
        return Icons.screenshot_outlined;
      case 'coaching':
        return Icons.psychology_outlined;
      case 'premium_features':
        return Icons.star_outline;
      default:
        return Icons.lock_outline;
    }
  }
} 