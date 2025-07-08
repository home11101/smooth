import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/referral_service.dart';

class ReferralSuccessDialog extends StatefulWidget {
  final String? referralCode;
  final VoidCallback? onClose;

  const ReferralSuccessDialog({
    Key? key,
    this.referralCode,
    this.onClose,
  }) : super(key: key);

  @override
  State<ReferralSuccessDialog> createState() => _ReferralSuccessDialogState();
}

class _ReferralSuccessDialogState extends State<ReferralSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String? _referralCode;
  bool _isLoading = true;
  Map<String, dynamic>? _referralStats;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeReferralCode();
  }

  Future<void> _initializeReferralCode() async {
    try {
      final referralService = ReferralService();
      
      // Si un code est fourni, l'utiliser, sinon en générer un nouveau
      if (widget.referralCode != null) {
        _referralCode = widget.referralCode;
      } else {
        _referralCode = await referralService.generateReferralCodeForCurrentUser();
      }

      // Récupérer les statistiques de parrainage
      _referralStats = await referralService.getCurrentUserReferralStats();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
        _confettiController.forward();
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du code de parrainage: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    if (_referralCode != null) {
      await Clipboard.setData(ClipboardData(text: _referralCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copié dans le presse-papiers !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareCode() {
    if (_referralCode != null) {
      Share.share(
        '🎁 J\'ai un code de parrainage pour Smooth AI !\n\n'
        'Utilisez mon code : $_referralCode\n\n'
        '💡 Comment ça marche :\n'
        '• Partagez votre code\n'
        '• 1 ami premium = 1 point\n'
        '• 5 points = 5% de réduction\n\n'
        'Téléchargez l\'app : [Lien de téléchargement]',
        subject: 'Mon code de parrainage Smooth AI',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Confetti animation
                          AnimatedBuilder(
                            animation: _confettiController,
                            builder: (context, child) {
                              return Stack(
                                children: List.generate(10, (index) {
                                  return Positioned(
                                    left: (index * 30.0) % 300,
                                    top: (_confettiController.value * 200) - (index * 20),
                                    child: Transform.rotate(
                                      angle: _confettiController.value * 6.28,
                                      child: Icon(
                                        [Icons.celebration, Icons.star, Icons.card_giftcard, Icons.diamond, Icons.favorite][index % 5],
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          
                          // Titre principal
                          const Text(
                            '🎉 Félicitations !',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vous êtes maintenant premium !',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Code de parrainage
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🎁 Votre code de parrainage :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _referralCode ?? 'Génération...',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Boutons d'action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _copyToClipboard,
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: const Text('Copier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF1E3A8A),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _shareCode,
                                      icon: const Icon(Icons.share, size: 18),
                                      label: const Text('Partager'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Statistiques de parrainage
                          if (_referralStats != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    '📊 Points',
                                    '${_referralStats!['available_points'] ?? 0}/5',
                                  ),
                                  _buildStatItem(
                                    '👥 Parrainages',
                                    '${_referralStats!['total_referrals'] ?? 0}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Comment ça marche :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Partagez votre code avec vos amis\n'
                                  '• Quand ils deviennent premium, vous gagnez 1 point\n'
                                  '• À 5 points, vous obtenez 5% de réduction\n'
                                  '• Les réductions s\'appliquent sur votre prochain abonnement',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Bouton fermer
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onClose?.call();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E3A8A),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Compris !',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
} 