import '../utils/app_theme.dart';
// import '../models/chat_analysis_report.dart'; // supprimé car inutilisé
import 'package:image_picker/image_picker.dart'; // supprimé car inutilisé
import '../widgets/flipable_chat_analysis_card.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import '../services/cache_service.dart';

import 'package:flutter/material.dart';
import 'smooth_coaching_screen.dart';
import 'upload_screenshot_screen.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path_provider/path_provider.dart'; // supprimé car inutilisé
// import 'dart:io'; // supprimé car inutilisé
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'package:flutter/rendering.dart';
import 'dart:io';
import '../utils/responsive_helper.dart';
import '../models/chat_analysis_report.dart';

class MainScreen2 extends StatefulWidget {
  const MainScreen2({Key? key}) : super(key: key);

  @override
  State<MainScreen2> createState() => _MainScreen2State();
}

class _MainScreen2State extends State<MainScreen2> {
  // Historique des analyses (rapport + image)
  final List<Map<String, dynamic>> _analysisHistory = [];

  @override
  void initState() {
    super.initState();
    // Charger l'historique depuis le cache au démarrage
    _loadHistoryFromCache();
  }

  // Méthode pour charger l'historique depuis le cache
  Future<void> _loadHistoryFromCache() async {
    try {
      final cachedHistory = await CacheService.getCachedAnalysisHistory('main_screen_2_carousel_history');
      if (cachedHistory != null && cachedHistory.isNotEmpty) {
        setState(() {
          _analysisHistory.clear();
          _analysisHistory.addAll(
            cachedHistory.map((item) {
              final newItem = Map<String, dynamic>.from(item);
              if (newItem['report'] is Map<String, dynamic>) {
                newItem['report'] = ChatAnalysisReport.fromJson(newItem['report']);
              }
              return newItem;
            }),
          );
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'historique carrousel MainScreen2: $e');
    }
  }

  // Méthode pour sauvegarder l'historique dans le cache
  Future<void> _saveHistoryToCache() async {
    try {
      await CacheService.cacheAnalysisHistory('main_screen_2_carousel_history', _analysisHistory);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique carrousel MainScreen2: $e');
    }
  }

  Future<void> _navigateToUpload(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UploadScreenshotScreen()),
    );
    if (result != null && result is Map<String, dynamic> && result['report'] != null) {
      setState(() {
        _analysisHistory.add({
          'report': result['report'],
          'uploadedImageBytes': result['uploadedImageBytes'],
        });
      });
      // Sauvegarder l'historique après ajout
      await _saveHistoryToCache();
    }
  }

  void _removeCard(int index) {
    setState(() {
      _analysisHistory.removeAt(index);
    });
    // Sauvegarder l'historique après suppression
    _saveHistoryToCache();
  }

  void _exportCardAsImage(BuildContext context, GlobalKey cardKey) async {
    try {
      RenderRepaintBoundary boundary = cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Mobile: sauvegarde dans la galerie
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/smooth_ai_analysis.png');
      await tempFile.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Smooth IA - Analyse');
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image partagée avec succès !')),
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: Column(
          children: [
            // Titre en haut
            _buildTitle(),
            SizedBox(height: 8), // petit espace entre le titre et l'image
            // Contenu principal (image ou carrousel)
            Expanded(
              child: Center(
                child: _analysisHistory.isNotEmpty
                    ? _buildCarousel()
                    : _buildMainImage(context),
              ),
            ),
            // Boutons d'action en bas (au-dessus du bottom nav)
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.responsiveWidth(context, 6),
        ResponsiveHelper.responsiveHeight(context, 0.5), // réduit le padding haut
        ResponsiveHelper.responsiveWidth(context, 6),
        ResponsiveHelper.responsiveHeight(context, 0.5), // réduit le padding bas
      ),
      child: Text(
        'Téléverse un chat et\nObtiens une analyse',
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 18, medium: 22, large: 26),
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2024),
          height: 1.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.responsiveWidth(context, 6),
        ResponsiveHelper.responsiveHeight(context, 1), // Espace au-dessus
        ResponsiveHelper.responsiveWidth(context, 6),
        ResponsiveHelper.responsiveHeight(context, 1), // Espace en-dessous (au-dessus du bottom nav)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Télécharge une capture (en haut)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black, // Fond noir
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.black, width: 1.5),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getAdaptiveButtonHeight(context) / 3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 13, medium: 15, large: 17),
                ),
              ),
              onPressed: () => _navigateToUpload(context),
              child: Text(
                'Télécharge une capture',
                style: TextStyle(
                  color: Colors.lightBlue[100], // Bleu ciel léger
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 13, medium: 15, large: 17),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
          // Bouton Smooth Coach (en bas)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white, // Fond blanc
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.white, width: 1.5),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getAdaptiveButtonHeight(context) / 3.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 12, medium: 14, large: 16),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SmoothCoachingScreen()),
                );
              },
              child: Text(
                'Smooth Coach',
                style: TextStyle(
                  color: Colors.black, // Texte noir
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 12, medium: 14, large: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    double width = ResponsiveHelper.responsiveWidth(context, 85);
    double height = ResponsiveHelper.responsiveHeight(context, 45);
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/capturemilieurscreen2.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: ResponsiveHelper.responsiveHeight(context, 45), // Hauteur responsive
      child: InfiniteCarousel.builder(
        itemCount: _analysisHistory.length,
        itemExtent: ResponsiveHelper.responsiveWidth(context, 85), // Largeur responsive
        center: true,
        loop: false,
        velocityFactor: 0.2,
        onIndexChanged: (index) {},
        itemBuilder: (context, index, realIndex) {
          final item = _analysisHistory[index];
          final heroTag = 'analysis_${item['report'].id}';
          return GestureDetector(
            onTap: () async {
              // Simple tap: comportement actuel (rien ou custom)
            },
            onDoubleTap: () async {
              final cardKey = GlobalKey();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black.withAlpha(179),
                    body: Center(
                      child: Stack(
                        children: [
                          Center(
                            child: Hero(
                              tag: heroTag,
                              child: SizedBox(
                                width: 440,
                                height: 600,
                                child: FlipableChatAnalysisCard(
                                  report: item['report'],
                                  uploadedImageBytes: item['uploadedImageBytes'],
                                  repaintBoundaryKey: cardKey,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 24,
                            left: 24,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(38),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withAlpha(77)),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 24,
                            right: 24,
                            child: GestureDetector(
                              onTap: () => _exportCardAsImage(context, cardKey),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(38),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withAlpha(77)),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.download, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: FlipableChatAnalysisCard(
                    report: item['report'],
                    uploadedImageBytes: item['uploadedImageBytes'],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeCard(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(179),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close, size: 18, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}