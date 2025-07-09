import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../services/promo_code_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/promo_code_input_widget.dart';
import '../main_navigation_screen.dart';

class TrialOnboardingScreen extends StatefulWidget {
  const TrialOnboardingScreen({super.key});

  @override
  State<TrialOnboardingScreen> createState() => _TrialOnboardingScreenState();
}

class _TrialOnboardingScreenState extends State<TrialOnboardingScreen> {
  final PromoCodeService _promoCodeService = PromoCodeService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  PromoCodeValidation? _appliedPromoCode;
  bool _showPromoCodeInput = false;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _startTrial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _subscriptionService.initialize();
      
      // Marquer que l'onboarding a été vu
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      print('✅ DEBUG: Onboarding marqué comme vu');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du démarrage de l\'essai : ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage de l\'essai: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipPromoCode() {
    setState(() {
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121F2F),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _currentStep == 0 
                      ? _buildPromoCodeStep()
                      : _buildWelcomeStep(),
                  const SizedBox(height: 40),
                  _buildBottomSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
        const SizedBox(height: 20),
        Text(
          _currentStep == 0 ? 'Code promo' : 'Bienvenue !',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: Colors.white.withAlpha(230),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _currentStep == 0 
              ? 'Avez-vous un code promo pour votre essai gratuit ?'
              : 'Votre essai gratuit de 3 jours commence maintenant !',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: Colors.white.withAlpha(204),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPromoCodeStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(51),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard,
                size: 48,
                color: Colors.white.withAlpha(204),
              ),
              const SizedBox(height: 16),
              Text(
                'Réductions exclusives',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.white.withAlpha(230),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez votre code promo pour obtenir des réductions spéciales sur votre abonnement premium.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white.withAlpha(204),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_appliedPromoCode != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade300, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code promo appliqué !',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
                        ),
                      ),
                      if (_appliedPromoCode!.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _appliedPromoCode!.description!,
                          style: TextStyle(
                            color: Colors.green.shade200,
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
                      color: Colors.green.shade300,
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
          PromoCodeInputWidget(
            onCodeValidated: _onPromoCodeValidated,
            onCodeApplied: _onPromoCodeApplied,
            context: 'trial_onboarding',
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _togglePromoCodeInput,
                icon: Icon(
                  _showPromoCodeInput ? Icons.remove : Icons.add,
                  size: 18,
                ),
                label: Text(
                  _showPromoCodeInput ? 'Masquer' : 'J\'ai un code promo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white.withAlpha(230),
                  side: BorderSide(color: Colors.white.withAlpha(77)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(51),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.celebration,
                size: 48,
                color: Colors.white.withAlpha(204),
              ),
              const SizedBox(height: 16),
              Text(
                'Essai gratuit de 3 jours',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.white.withAlpha(230),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Découvrez toutes les fonctionnalités premium de Smooth AI pendant 3 jours, sans engagement.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white.withAlpha(204),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildFeatureList(),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.chat_bubble, 'title': 'Analyse de conversations', 'desc': 'Analysez vos échanges pour améliorer votre communication'},
      {'icon': Icons.camera_alt, 'title': 'Analyse de captures d\'écran', 'desc': 'Analysez vos conversations via des captures d\'écran'},
      {'icon': Icons.favorite, 'title': 'Générateur de phrases d\'accroche', 'desc': 'Générez des phrases d\'accroche personnalisées'},
      {'icon': Icons.school, 'title': 'Coaching personnalisé', 'desc': 'Recevez des conseils personnalisés pour vos rencontres'},
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Row(
          children: [
            Icon(
              feature['icon'] as IconData,
              color: Colors.white.withAlpha(204),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['desc'] as String,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        if (_currentStep == 0) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _skipPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(51),
                foregroundColor: Colors.white.withAlpha(230),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Passer cette étape',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _startTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white.withAlpha(230),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xE6FFFFFF)),
                    ),
                  )
                : Text(
                    _currentStep == 0 ? 'Continuer' : 'Commencer l\'essai',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
} 