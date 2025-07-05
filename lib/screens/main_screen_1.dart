import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../services/cache_service.dart';

import 'package:flutter/material.dart';
import 'enter_text_screen.dart';
import 'pickup_line_screen.dart';
import 'ocr_scan_screen.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui';

class MainScreen1 extends StatefulWidget {
  const MainScreen1({Key? key}) : super(key: key);

  @override
  State<MainScreen1> createState() => _MainScreen1State();
}

class _MainScreen1State extends State<MainScreen1> {
  // Historique des analyses OCR (réponse IA + image)
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
      final cachedHistory = await CacheService.getCachedAnalysisHistory('main_screen_carousel_history');
      if (cachedHistory != null && cachedHistory.isNotEmpty) {
        setState(() {
          _analysisHistory.clear();
          _analysisHistory.addAll(cachedHistory);
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'historique carrousel: $e');
    }
  }

  // Méthode pour sauvegarder l'historique dans le cache
  Future<void> _saveHistoryToCache() async {
    try {
      await CacheService.cacheAnalysisHistory('main_screen_carousel_history', _analysisHistory);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique carrousel: $e');
    }
  }

  Future<void> _navigateToOcrScan(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OptimizedRizzScanner()),
    );
    if (result != null && result is Map<String, dynamic> && result['analysisHistory'] != null) {
      setState(() {
        // Remplacer l'historique au lieu de l'ajouter
        _analysisHistory.clear();
        _analysisHistory.addAll(result['analysisHistory']);
      });
      // Sauvegarder l'historique après mise à jour
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
      final tempFile = File('${tempDir.path}/smooth_ai_ocr_analysis.png');
      await tempFile.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Smooth IA - Analyse OCR');
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image partagée avec succès !')),
        );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }

  // Méthode pour convertir en toute sécurité les données d'image en Uint8List
  Uint8List? _safeGetImageBytes(dynamic imageData) {
    if (imageData == null) return null;
    
    if (imageData is Uint8List) {
      return imageData;
    } else if (imageData is List<dynamic>) {
      // Convertir List<dynamic> en Uint8List
      try {
        return Uint8List.fromList(imageData.cast<int>());
      } catch (e) {
        print('Erreur lors de la conversion List<dynamic> vers Uint8List: $e');
        return null;
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppTheme.buildPickupScreenBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(child: _buildMainImage(context)),
              _buildTitle(context),
              _buildActionButtons(context),
              if (_analysisHistory.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 120,
                  child: SizedBox(
                    height: 320,
                    child: _buildCarousel(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return InfiniteCarousel.builder(
      itemCount: _analysisHistory.length,
      itemExtent: 320,
      center: true,
      loop: false,
      velocityFactor: 0.2,
      onIndexChanged: (index) {},
      itemBuilder: (context, index, realIndex) {
        final item = _analysisHistory[index];
        final heroTag = 'ocr_analysis_$index';
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
                  body: Stack(
                    children: [
                      Center(
                        child: Hero(
                          tag: heroTag,
                          child: SizedBox(
                            width: 440,
                            height: 600,
                            child: _buildOcrAnalysisCard(item, cardKey),
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
            );
          },
          child: Stack(
            children: [
              Hero(
                tag: heroTag,
                child: _buildOcrAnalysisCard(item, null),
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
    );
  }

  Widget _buildOcrAnalysisCard(Map<String, dynamic> item, GlobalKey? cardKey) {
    final imageBytes = _safeGetImageBytes(item['uploadedImageBytes']);
    
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 320,
        height: 520,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withAlpha(64),
              Colors.white.withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withAlpha(102),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(
              children: [
                // Image
                if (imageBytes != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withAlpha(51),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blueAccent.withAlpha(77),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Analyse OCR',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              item['iaResponse'] ?? 'Aucune réponse IA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveHelper.responsiveWidth(context, 6),
          ResponsiveHelper.responsiveHeight(context, 3),
          ResponsiveHelper.responsiveWidth(context, 6),
          0,
        ),
        child: Text(
          'Télécharge une capture\nd\'un chat ou d\'une bio',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 18, medium: 22, large: 26),
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveHelper.responsiveWidth(context, 6),
          0,
          ResponsiveHelper.responsiveWidth(context, 6),
          ResponsiveHelper.responsiveHeight(context, 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: AppTheme.secondaryBlue,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.getAdaptiveButtonHeight(context) / 3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
                shadowColor: Colors.black.withAlpha(102),
              ),
              icon: Icon(Icons.add_photo_alternate_outlined, size: ResponsiveHelper.responsiveFontSize(context, 22)),
              label: Text(
                'Télécharger une capture',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 13, medium: 15, large: 17),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _navigateToOcrScan(context);
              },
            ),
            SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SmoothAIScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getAdaptiveButtonHeight(context) / 3.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: AppTheme.lightBlueBorder, width: 1.5),
                    ),
                    child: Text(
                      'Saisir le texte',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 12, medium: 14, large: 16)),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.responsiveSpacing(context)),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PickupLineScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getAdaptiveButtonHeight(context) / 3.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: AppTheme.lightBlueBorder, width: 1.5),
                    ),
                    child: Text(
                      'Phrase d\'approche',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 12, medium: 14, large: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    double width = ResponsiveHelper.responsiveWidth(context, 80);
    double height = ResponsiveHelper.responsiveHeight(context, 42);
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/capturemilieurscreen1.png',
        fit: BoxFit.contain,
        width: width,
        height: height,
      ),
    );
  }
}
