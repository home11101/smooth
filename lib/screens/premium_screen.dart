import '../utils/app_theme.dart';
import '../services/sound_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/in_app_purchase_service.dart';
import '../services/premium_provider.dart';
import '../services/promo_code_service.dart';
import '../widgets/promo_code_input_widget.dart';
import 'dart:ui';
import 'dart:async';
import '../services/subscription_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final InAppPurchaseService _purchaseService;
  int _featureIndex = 0;
  final FixedExtentScrollController _carouselController = FixedExtentScrollController();

  final PremiumProvider _premiumProvider = PremiumProvider();
  final PromoCodeService _promoCodeService = PromoCodeService();
  
  PromoCodeValidation? _appliedPromoCode;
  bool _showPromoCodeInput = false;

  @override
  void initState() {
    super.initState();
    _purchaseService = Provider.of<InAppPurchaseService>(context, listen: false);
    _purchaseService.initialize(_premiumProvider);
    _loadAppliedPromoCode();
  }

  Future<void> _loadAppliedPromoCode() async {
    final appliedCode = await _promoCodeService.getAppliedPromoCode();
    if (appliedCode != null) {
      setState(() {
        _appliedPromoCode = PromoCodeValidation(
          isValid: true,
          discountType: appliedCode.discountType,
          discountValue: appliedCode.discount,
          description: 'Code promo appliqué: ${appliedCode.code}',
        );
      });
    }
  }

  Future<void> _buyPremium(ProductDetails product) async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    premiumProvider.setProcessing(true);
    
    try {
      final purchaseService = Provider.of<InAppPurchaseService>(context, listen: false);
      await purchaseService.buyProduct(product);
      // La validation du paiement est gérée par InAppPurchaseService via PremiumProvider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achat réussi !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'achat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        premiumProvider.setProcessing(false);
      }
    }
  }

  void _onPromoCodeValidated(PromoCodeValidation validation) {
    setState(() {
      _appliedPromoCode = validation;
    });
  }

  void _onPromoCodeApplied(String code) {
    setState(() {
      _showPromoCodeInput = false;
    });
  }

  void _togglePromoCodeInput() {
    setState(() {
      _showPromoCodeInput = !_showPromoCodeInput;
    });
  }

  Future<void> _restorePurchases() async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    premiumProvider.setProcessing(true);
    
    try {
      final purchaseService = Provider.of<InAppPurchaseService>(context, listen: false);
      await purchaseService.restorePurchases();
      
      if (mounted) {
        await SoundService.playSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achats restaurés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await SoundService.playError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        premiumProvider.setProcessing(false);
      }
    }
  }

  final List<Map<String, dynamic>> _premiumBenefits = [
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'Chat illimité',
      'description': 'Posez autant de questions que vous voulez à l\'IA.'
    },
    {
      'icon': Icons.star_border,
      'title': 'Contenu premium',
      'description': 'Accédez à des fonctionnalités exclusives.'
    },
    {
      'icon': Icons.bolt,
      'title': 'Réponses rapides',
      'description': 'Priorité sur le traitement de vos demandes.'
    },
    {
      'icon': Icons.school,
      'title': 'Smooth Coach IA',
      'description': 'Discutez avec notre chatbot IA Smooth Coach pour des conseils amoureux personnalisés et apprendre sur la vie amoureuse.'
    },
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }
  
  // Méthode utilitaire pour afficher un message d'erreur
  void _showErrorSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InAppPurchaseService, PremiumProvider>(
      builder: (context, purchaseService, premiumProvider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF121F2F),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Container(),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Logo en haut
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Affichage du nombre de jours d'essai restant
                    FutureBuilder<int>(
                      future: SubscriptionService().getTrialDaysRemaining(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 16);
                        }
                        final days = snapshot.data ?? 0;
                        if (days > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Essai gratuit : $days jour${days > 1 ? 's' : ''} restant${days > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(height: 8);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Gestion des erreurs d'achat/validation
                    if (premiumProvider.errorMessage != null && premiumProvider.errorMessage!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(180),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                premiumProvider.errorMessage!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Avantages premium bien mis en avant
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: _buildBenefitCarousel(),
                    ),
                    const SizedBox(height: 16),
                    // Section code promo
                    _buildPromoCodeSection(),
                    const SizedBox(height: 12),
                    // Offres de prix
                    _buildPricingOptions(),
                    const SizedBox(height: 12),
                    // Bouton restaurer visible
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: premiumProvider.isProcessing ? null : _restorePurchases,
                        icon: const Icon(Icons.restore, color: Colors.white, size: 20),
                        label: premiumProvider.isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Restaurer les achats', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mentions légales
                    _buildLegalInfo(),
                    const SizedBox(height: 16, child: SizedBox.expand()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, Colors.white],
              stops: [0.0, 1.0],
            ),
          ),
        ),
        // Blobs glassmorphism
        Positioned(
          top: 80,
          left: -60,
          child: _glassBlob(180, 0.18),
        ),
        Positioned(
          bottom: 120,
          right: -50,
          child: _glassBlob(140, 0.14),
        ),
        Positioned(
          top: 300,
          right: 30,
          child: _glassBlob(90, 0.12),
        ),
      ],
    );
  }

  Widget _glassBlob(double size, double opacity) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: _premiumBenefits.length,
        controller: PageController(viewportFraction: 0.85),
        itemBuilder: (context, index) {
          final benefit = _premiumBenefits[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(benefit['icon'], size: 36, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      benefit['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        benefit['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildFeatureCarousel() {
    return SizedBox(
      height: 260,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final index = _carouselController.selectedItem;
            if (_featureIndex != index) {
              setState(() => _featureIndex = index);
            }
          }
          return false;
        },
        child: ListWheelScrollView.useDelegate(
          controller: _carouselController,
          itemExtent: 180,
          diameterRatio: 2.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => _featureIndex = index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              if (index < 0 || index >= _premiumBenefits.length) return null;
              final feature = _premiumBenefits[index];
              final isSelected = _featureIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: isSelected ? 0 : 12, vertical: isSelected ? 0 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.85) : Colors.blue.shade50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                  ],
                  border: isSelected
                      ? Border.all(color: AppTheme.primaryBlue, width: 2)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(feature['icon'], color: AppTheme.primaryBlue, size: 40),
                      const SizedBox(height: 18),
                      Text(
                        feature['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF1F2024) : Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feature['description'],
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? Colors.black54 : Colors.blue.shade400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Column(
      children: [
        if (_appliedPromoCode != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code promo appliqué !',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      if (_appliedPromoCode!.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _appliedPromoCode!.description!,
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _promoCodeService.clearAppliedPromoCode();
                    setState(() {
                      _appliedPromoCode = null;
                    });
                  },
                  child: Text(
                    'Supprimer',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_showPromoCodeInput) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PromoCodeInputWidget(
              onCodeValidated: _onPromoCodeValidated,
              onCodeApplied: _onPromoCodeApplied,
              context: 'premium_purchase',
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _togglePromoCodeInput,
                  icon: Icon(
                    _showPromoCodeInput ? Icons.remove : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    _showPromoCodeInput ? 'Masquer le code promo' : 'J\'ai un code promo',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingOptions() {
    return Consumer<InAppPurchaseService>(
      builder: (context, purchaseService, _) {
        final products = purchaseService.products;
        
        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Chargement des abonnements...'),
            ),
          );
        }

        final weekly = products.firstWhere(
          (p) => p.id == 'premium_weekly',
          orElse: () => products.first,
        );
        final monthly = products.firstWhere(
          (p) => p.id == 'premium_monthly',
          orElse: () => products.length > 1 ? products[1] : products.first,
        );
        final yearly = products.firstWhere(
          (p) => p.id == 'premium_yearly',
          orElse: () => products.length > 2 ? products[2] : products.first,
        );

        return Column(
          children: [
            _buildPricingCard(
              title: 'Hebdomadaire',
              price: weekly.price,
              period: 'par semaine',
              isPopular: false,
              onTap: () => _buyPremium(weekly),
            ),
            const SizedBox(height: 20),
            _buildPricingCard(
              title: 'Mensuel',
              price: monthly.price,
              period: 'par mois',
              isPopular: false,
              onTap: () => _buyPremium(monthly),
            ),
            const SizedBox(height: 20),
            _buildPricingCard(
              title: 'Annuel',
              price: yearly.price,
              period: 'par an',
              isPopular: true,
              onTap: () => _buyPremium(yearly),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isPopular ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? Colors.blue.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MEILLEURE OFFRE',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2024),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                if (period.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Essai gratuit de 3 jours, puis abonnement selon votre choix. Paiement sécurisé via App Store / Google Play. Résiliable à tout moment.',
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Le paiement sera facturé sur votre compte Google Play/App Store à la confirmation de l\'achat. L\'abonnement se renouvelle automatiquement sauf s\'il est annulé 24 heures avant la fin de la période en cours.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => launchUrlString('https://smooth-pages.vercel.app/privacy.html'),
                child: const Text(
                  'Politique de confidentialité',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => launchUrlString('https://smooth-pages.vercel.app/terms.html'),
                child: const Text(
                  'CGU',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}