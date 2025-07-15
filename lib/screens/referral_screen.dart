import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/referral_service.dart';
import '../utils/app_theme.dart';
import 'dart:ui';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  Map<String, dynamic>? _referralStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralStats();
  }

  Future<void> _loadReferralStats() async {
    try {
      final stats = await _referralService.getCurrentUserReferralStats();
      setState(() {
        _referralStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des stats de parrainage: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
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

  void _shareCode(String code) {
    final referralLink = 'https://smoothai.com/invite/$code';
    Share.share(
      '🎁 J\'ai un lien de parrainage pour Smooth AI !\n\n'
      'Utilisez mon lien : $referralLink\n\n'
      '💡 Comment ça marche :\n'
      '• Partagez votre lien\n'
      '• 1 ami qui installe l\'app = 1 point\n'
      '• 5 points = 5% de réduction\n\n'
      'Téléchargez l\'app via ce lien pour que je gagne des points !',
      subject: 'Mon lien de parrainage Smooth AI',
    );
  }

  int _getLotteryEntries(int coins) {
    return coins ~/ 30;
  }

  void _showLotteryInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tirage au sort mensuel'),
        content: const Text(
          'À chaque palier de 30 Smooth Coin, vous obtenez une participation au tirage au sort mensuel !\n\n'
          'Chaque mois, des lots sont à gagner : cash, cartes cadeaux, surprises...\n\n'
          'Plus vous parrainez, plus vous avez de chances de gagner !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLotterySection() {
    final availableCoins = _referralStats!['available_points'] ?? 0;
    final entries = _getLotteryEntries(availableCoins);
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tirage au sort mensuel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[200],
                  ),
                ),
              ),
              TextButton(
                onPressed: _showLotteryInfoDialog,
                child: const Text('En savoir plus'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Chaque palier de 30 Smooth Coin = 1 participation au tirage au sort du mois !',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.confirmation_num, color: Colors.amber, size: 22),
              const SizedBox(width: 6),
              Text(
                'Participations ce mois-ci : ',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              Text(
                '$entries',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '🎁 Parrainage',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadReferralStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fond noir profond + blur léger
          Container(
            color: const Color(0xFF0A0A0A),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _referralStats == null
                  ? _buildNoReferralData()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlassyHeader(),
                          const SizedBox(height: 24),
                          _buildGlassyStatsCards(),
                          const SizedBox(height: 28),
                          _buildGlassyReferralCode(),
                          const SizedBox(height: 32),
                          _buildHowItWorks(),
                          const SizedBox(height: 24),
                          _buildRewardsInfo(),
                          _buildLotterySection(),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildNoReferralData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.card_giftcard,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun code de parrainage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous recevrez votre code de parrainage\ndès votre premier achat premium',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Devenir Premium',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyHeader() {
    return Center(
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, size: 54, color: Colors.white),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFF0ED2F7), Color(0xFF8B5CF6)],
              ).createShader(rect),
              child: const Text(
                'Programme de parrainage',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gagnez des points en parrainant vos amis !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassyStatsCards() {
    final availableCoins = _referralStats!['available_points'] ?? 0;
    final totalReferrals = _referralStats!['total_referrals'] ?? 0;
    final coinsToBonus = 30 - (availableCoins > 30 ? 30 : availableCoins);
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.stars, color: Colors.amber.shade300, size: 32),
                const SizedBox(height: 8),
                Text('$availableCoins', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Smooth Coin', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.people, color: Colors.greenAccent.shade100, size: 32),
                const SizedBox(height: 8),
                Text('$totalReferrals', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Parrainages', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Icon(Icons.card_giftcard, color: Colors.blue.shade200, size: 32),
                const SizedBox(height: 8),
                Text(coinsToBonus > 0 ? '$coinsToBonus' : 'Atteint', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Prochain bonus', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassyReferralCode() {
    final referralCode = _referralStats!['referral_code'];
    if (referralCode == null) return const SizedBox.shrink();
    final referralLink = 'https://smoothai.com/invite/$referralCode';
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre lien de parrainage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  referralLink,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassButton(
                icon: Icons.copy,
                onTap: () => _copyToClipboard(referralLink),
                tooltip: 'Copier',
              ),
              const SizedBox(width: 8),
              GlassButton(
                icon: Icons.share,
                onTap: () => _shareCode(referralCode),
                tooltip: 'Partager',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Programme de parrainage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gagnez des points en parrainant vos amis !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final availableCoins = _referralStats!['available_points'] ?? 0;
    final totalReferrals = _referralStats!['total_referrals'] ?? 0;
    final coinsToBonus = 30 - (availableCoins > 30 ? 30 : availableCoins);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Smooth Coin',
            '$availableCoins',
            'Disponibles',
            Icons.stars,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Parrainages',
            '$totalReferrals',
            'Total',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Prochain bonus',
            coinsToBonus > 0 ? '$coinsToBonus' : 'Atteint',
            'Smooth Coin',
            Icons.card_giftcard,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCode() {
    final referralCode = _referralStats!['referral_code'];
    if (referralCode == null) return const SizedBox.shrink();

    final referralLink = 'https://smoothai.com/invite/$referralCode';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre lien de parrainage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralLink,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(referralLink),
                  icon: const Icon(
                    Icons.copy,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareCode(referralCode),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager le lien'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Comment ça marche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(1, '1 téléchargement via votre lien', 'Vous recevez 1 Smooth Coin'),
          _buildStep(2, '1 utilisateur devient premium', 'Vous recevez 5 Smooth Coin'),
          _buildStep(3, 'Atteignez 30 Smooth Coin', 'Recevez un bonus spécial !'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }

  Widget _buildRewardsInfo() {
    final availableCoins = _referralStats!['available_points'] ?? 0;
    final coinsToBonus = 30 - (availableCoins > 30 ? 30 : availableCoins);
    final hasBonus = availableCoins >= 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasBonus ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBonus ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasBonus ? Icons.card_giftcard : Icons.lock,
                color: hasBonus ? Colors.green : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasBonus ? 'Bonus spécial disponible !' : 'Prochain bonus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasBonus ? Colors.green : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasBonus) ...[
            const Text(
              '🎉 Félicitations ! Vous avez atteint 30 Smooth Coin et débloqué un bonus spécial. Contactez-nous pour en profiter !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ] else ...[
            Text(
              'Il vous manque $coinsToBonus Smooth Coin pour débloquer votre bonus spécial.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: availableCoins / 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              '$availableCoins/30 Smooth Coin',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Ajout des widgets glassmorphism
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  const GlassContainer({super.key, required this.child, this.padding, this.margin, this.borderRadius});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: borderRadius ?? BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const GlassButton({super.key, required this.icon, required this.onTap, this.tooltip});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
} 