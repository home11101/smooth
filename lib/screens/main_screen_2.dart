import '../utils/app_theme.dart';
// import '../models/chat_analysis_report.dart'; // supprimé car inutilisé
import 'package:image_picker/image_picker.dart'; // supprimé car inutilisé
import '../widgets/flipable_chat_analysis_card.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

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

class MainScreen2 extends StatefulWidget {
  const MainScreen2({Key? key}) : super(key: key);

  @override
  State<MainScreen2> createState() => _MainScreen2State();
}

class _MainScreen2State extends State<MainScreen2> {
  // Historique des analyses (rapport + image)
  final List<Map<String, dynamic>> _analysisHistory = [];

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
    }
  }

  void _removeCard(int index) {
    setState(() {
      _analysisHistory.removeAt(index);
    });
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
        child: SafeArea(
          child: Stack(
            children: [
              Center(child: _buildMainImage(context)),
              _buildTitle(),
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

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          color: Colors.transparent,
          child: const Text(
            'Téléverse un chat\nPour obtenir une analyse',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2024),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(color: AppTheme.primaryBlue.withAlpha(51), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                icon: const Icon(Icons.file_upload, color: Color(0xFF87CEFA), size: 20),
                label: Text(
                  'Télécharge une capture',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () => _navigateToUpload(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(color: AppTheme.primaryBlue.withAlpha(51), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                icon: const Icon(Icons.auto_awesome, color: Color(0xFF87CEFA), size: 20),
                label: Text(
                  'Smooth Coach',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SmoothCoachingScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.86;  // Augmenté de 0.85 à 0.86
    double height = MediaQuery.of(context).size.height * 0.45; // Augmenté de 0.40 à 0.45
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/capturemilieurscreen2.png',
        fit: BoxFit.contain,
        width: width,
        height: height,
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
    );
  }
}