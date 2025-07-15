import '../utils/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart'
    show canLaunchUrl, launchUrl, LaunchMode;

import '../screens/premium_screen.dart';
import '../screens/referral_screen.dart';
import '../widgets/smooth_coin_info_bottom_sheet.dart';

// Classe principale du menu modal
class SmoothModalMenu extends StatelessWidget {
  final VoidCallback? onUpgrade;
  const SmoothModalMenu({Key? key, this.onUpgrade}) : super(key: key);

  // Fonction pour lancer l'application email
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'Contact@smoothai.app',
      query: 'subject=Support%20Smooth%20AI',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode utilitaire pour créer une section de menu
  Widget _buildMenuSection(List<Widget> items) {
    return Column(
      children:
          items.expand((item) => [item, const SizedBox(height: 12)]).toList()
            ..removeLast(),
    );
  }

  // Fonction pour supprimer toutes les données utilisateur
  Future<void> _deleteUserData(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les données'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible et supprimera toutes vos préférences et historiques.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Ici, vous pouvez ajouter la logique pour supprimer les données
      // Par exemple :
      // await _yourDataService.clearAllData();

      if (context.mounted) {
        Navigator.pop(context); // Ferme le menu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes vos données ont été supprimées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Fonction pour ouvrir une URL externe
  Future<void> _launchExternalUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le lien'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour partager l'application
  void _shareApp() {
    Share.share(
      'Découvrez Smooth AI - Votre assistant de séduction intelligent ! Téléchargez l\'application dès maintenant !',
      subject: 'Smooth AI - Application de coaching en séduction',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap:
                  () {}, // Pour éviter la fermeture quand on clique sur le menu
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 24, left: 0, right: 0, bottom: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFF2196F3), size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    // Menu items
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          // Section Contact
                          _buildMenuSection([
                            _SmoothMenuItem(
                              icon: Icons.mail_outline,
                              label: 'Contactez-nous',
                              onTap: () => _launchEmail(context),
                            ),
                          ]),

                          const SizedBox(height: 8),
                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 16,
                              endIndent: 16),
                          const SizedBox(height: 8),

                          // Section Application
                          _buildMenuSection([
                            _SmoothMenuItem(
                              icon: Icons.diamond_outlined,
                              label: 'Mettre à niveau',
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onUpgrade != null) {
                                  Future.delayed(const Duration(milliseconds: 200), onUpgrade!);
                                }
                              },
                            ),
                            _SmoothMenuItem(
                              icon: Icons.card_giftcard,
                              label: 'Parrainage',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReferralScreen(),
                                  ),
                                );
                              },
                            ),
                            _SmoothMenuItem(
                              icon: Icons.monetization_on_outlined,
                              label: 'Smooth Coin',
                              onTap: () async {
                                Navigator.of(context).pop();
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (modalContext) => const SmoothCoinInfoBottomSheet(),
                                );
                              },
                            ),
                            _SmoothMenuItem(
                              icon: Icons.share_outlined,
                              label: "Partager l'application",
                              onTap: () => _shareApp(),
                            ),
                            _SmoothMenuItem(
                              icon: Icons.star_border,
                              label: 'Noter l\'application',
                              onTap: () async {
                                Navigator.of(context).pop(); // Ferme le menu
                                
                                // TODO: Remplacer par les IDs de vos applications
                                const androidAppId = 'com.example.smoothai';
                                const iosAppId = 'id123456789';
                                
                                final url = Platform.isAndroid
                                    ? Uri.parse('https://play.google.com/store/apps/details?id=$androidAppId')
                                    : Uri.parse('https://apps.apple.com/app/id$iosAppId');
                                
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Impossible d\'ouvrir le ${Platform.isAndroid ? 'Play Store' : 'App Store'}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    // Socials
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SmoothSocialIcon(
                            asset: 'assets/images/instagram.png', url: 'https://www.instagram.com/smoothai_app?igsh=MWNjdmlmNDdhdWxtbw%3D%3D&utm_source=qr'),
                        SizedBox(width: 16),
                        _SmoothSocialIcon(
                            asset: 'assets/images/tiktok.png', url: 'https://www.tiktok.com/@smooth.ia?_t=ZN-8xfS0OfT31a&_r=1'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Footer links
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SmoothFooterLink(
                            label: 'Termes',
                            onTap: () => _launchExternalUrl(
                                'https://smoothia.app/terms.html',
                                context),
                          ),
                          const SizedBox(width: 12),
                          _SmoothFooterLink(
                            label: 'Confidentialité',
                            onTap: () => _launchExternalUrl(
                                'https://smoothia.app/privacy.html',
                                context),
                          ),
                          const SizedBox(width: 12),
                          _SmoothFooterLink(
                            label: 'Supprimer vos données',
                            onTap: () => _deleteUserData(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothMenuItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  const _SmoothMenuItem({
    this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: icon != null
                ? Icon(icon, color: AppTheme.primaryBlue, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222B45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothSocialIcon extends StatefulWidget {
  final String asset;
  final String url;
  const _SmoothSocialIcon({required this.asset, required this.url});

  @override
  State<_SmoothSocialIcon> createState() => _SmoothSocialIconState();
}

class _SmoothSocialIconState extends State<_SmoothSocialIcon> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (widget.url.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le lien'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _handleTap,
            child: Image.asset(
              widget.asset,
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
          );
  }
}

class _SmoothFooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmoothFooterLink({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.dividerColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
