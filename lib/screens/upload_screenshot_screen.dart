import '../utils/app_theme.dart';
import '../utils/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// Supprimé: google_mlkit_text_recognition et flutter_tesseract_ocr
// On utilise Vision API cloud via VisionService
import '../services/openai_service.dart';
import '../services/vision_service.dart';
import '../services/sound_service.dart';
import '../models/chat_analysis_report.dart';
import '../widgets/flipable_chat_analysis_card.dart';
import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';
import 'dart:ui';
import 'dart:convert';

class UploadScreenshotScreen extends StatefulWidget {
  const UploadScreenshotScreen({super.key});

  @override
  _UploadScreenshotScreenState createState() => _UploadScreenshotScreenState();
}

class _UploadScreenshotScreenState extends State<UploadScreenshotScreen>
    with TickerProviderStateMixin {
  // État de l'application
  bool isScanning = false;
  double scanProgress = 0.0;
  double scanLinePosition = -100;
  String detectedText = '';
  int currentEmoji = 0;
  String responseType = 'smooth';
  bool showResult = false;
  bool copied = false;
  double rizzLevel = 0.0;
  int thinkingDots = 0;
  XFile? uploadedImage;
  Uint8List? uploadedImageBytes;
  String? extractedOcrText;
  String? texteRecu;
  String? texteEnvoye;
  String? _errorMessage;
  String? iaResponse;
  ChatAnalysisReport? report;
  bool? _isPremium;

  // Controllers d'animation
  late AnimationController _scanLineController;
  late AnimationController _progressController;
  late AnimationController _rizzController;
  late AnimationController _thinkingController;
  late AnimationController _shimmerController;
  late AnimationController _holographicController;
  late AnimationController _cardAppearController;

  // Animations
  late Animation<double> _scanLineAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _holographicAnimation;
  late Animation<double> _cardAppearAnimation;

  final ImagePicker _picker = ImagePicker();
  
  final List<String> emojis = ['🔥', '😎', '💯', '🚀', '⚡', '🌟', '👑', '💎'];

  final Map<String, Map<String, dynamic>> responseTypes = {
    'sincere': {
      'emoji': '💖',
      'label': 'Sincère',      'colors': [AppTheme.accentPink, const Color(0xFFF43F5E)],
      'rizzLevel': 75.0
    },
    'osee': {
      'emoji': '😈',
      'label': 'Osée',
      'colors': [AppTheme.accentRed, AppTheme.accentOrange],
      'rizzLevel': 95.0
    },
    'smooth': {
      'emoji': '🔥',
      'label': 'Smooth',
      'colors': [AppTheme.accentPurple, AppTheme.accentIndigo],
      'rizzLevel': 90.0
    },
    'cool': {
      'emoji': '😎',
      'label': 'Cool',
      'colors': [AppTheme.accentCyan, const Color(0xFF3B82F6)],
      'rizzLevel': 80.0
    }
  };

  late VisionService visionService;
  late OpenAIService openaiService;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    visionService = VisionService(kGoogleVisionApiKey);
    openaiService = OpenAIService();
    // Vérifier l'accès premium
    SubscriptionService().isPremium().then((value) {
      if (mounted) setState(() => _isPremium = value);
    });
    // Ouvre la galerie dès l'arrivée sur l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('[DEBUG] Appel initial: ouverture galerie');
      await _handleImageUpload();
      if (uploadedImage != null) {
        print('[DEBUG] Image uploadée, démarrage du scan');
        _startScan();
      }
    });
  }

  void _initAnimations() {
    // Animation de la ligne de scan
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(
      begin: -100,
      end: 500,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.linear,
    ));

    // Animation de progression
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    // Animation des points de réflexion
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    // Animation holographique
    _holographicController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _holographicAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _holographicController,
      curve: Curves.easeInOut,
    ));

    // Animation d'apparition de carte 3D
    _cardAppearController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _cardAppearAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardAppearController,
      curve: Curves.easeOut,
    ));

    // Démarrer les animations continues
    _shimmerController.repeat();
    _holographicController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _progressController.dispose();
    _rizzController.dispose();
    _thinkingController.dispose();
    _shimmerController.dispose();
    _holographicController.dispose();
    _cardAppearController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          uploadedImage = image;
          uploadedImageBytes = bytes;
        });
      } else {
        setState(() {
          _errorMessage = "Aucune image sélectionnée.";
          isScanning = false;
        });
        SoundService.playError();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la sélection d'image : $e";
        isScanning = false;
      });
      SoundService.playError();
    }
  }

  Future<void> _scanWithVisionAPIAndAnalyze(File image) async {
    print('[DEBUG] Début analyse OCR/IA');
    if (kIsWeb) {
      print('[DEBUG] Mode web : OCR via Vision API');
      final bytes = await uploadedImage!.readAsBytes();
      final result = await visionService.detectAndSplitMessagesFromBytes(bytes);
      await Future.delayed(const Duration(seconds: 1)); // pour l'animation
      if (result != null) {
        setState(() {
          texteRecu = result['messagesRecus'];
          texteEnvoye = result['messagesEnvoyes'];
          detectedText = (texteRecu ?? '') + '\n' + (texteEnvoye ?? '');
        });
        print('[DEBUG] Texte détecté (web): $detectedText');
        // === Appel IA ===
        try {
          final iaResult = await openaiService.analyzeChat(
            texteRecu: texteRecu ?? '',
            texteEnvoye: texteEnvoye ?? '',
          );
          print('[DEBUG] Réponse IA brute (web): $iaResult');
          ChatAnalysisReport? parsedReport;
          try {
            parsedReport = ChatAnalysisReport.fromJson(jsonDecode(iaResult));
          } catch (e) {
            print('[DEBUG] Erreur parsing rapport IA (web): $e');
            parsedReport = null;
          }
          setState(() {
            iaResponse = iaResult;
            report = parsedReport;
            showResult = true;
            isScanning = false;
          });
          print('[DEBUG] Rapport IA (web): $report, showResult: $showResult, isScanning: $isScanning');
          if (parsedReport != null) {
            SoundService.playSuccess();
          } else {
            SoundService.playError();
          }
        } catch (e) {
          setState(() {
            showResult = true;
            isScanning = false;
          });
          print('[DEBUG] Erreur appel IA (web): $e');
          SoundService.playError();
        }
        // === FIN IA ===
      } else {
        setState(() {
          _errorMessage = "OCR Vision API web : échec ou non supporté.";
          isScanning = false;
        });
        print('[DEBUG] Erreur OCR Vision API web');
        SoundService.playError();
      }
      return;
    }
    // --- Comportement natif mobile/tablette ---
    final result = await visionService.detectAndSplitMessages(image);
    await Future.delayed(const Duration(seconds: 1));
    if (result != null) {
      setState(() {
        texteRecu = result['messagesRecus'];
        texteEnvoye = result['messagesEnvoyes'];
        detectedText = (texteRecu ?? '') + '\n' + (texteEnvoye ?? '');
      });
      print('[DEBUG] Texte détecté: $detectedText');
      // Appel IA automatique
      final iaResult = await openaiService.analyzeChat(
        texteRecu: texteRecu ?? '',
        texteEnvoye: texteEnvoye ?? '',
      );
      print('[DEBUG] Réponse IA brute: $iaResult');
      ChatAnalysisReport? parsedReport;
      try {
        parsedReport = ChatAnalysisReport.fromJson(jsonDecode(iaResult));
      } catch (e) {
        print('[DEBUG] Erreur parsing rapport IA: $e');
        parsedReport = null;
      }
      setState(() {
        iaResponse = iaResult;
        report = parsedReport;
        showResult = true;
        isScanning = false;
      });
      print('[DEBUG] Rapport IA: $report, showResult: $showResult, isScanning: $isScanning');
      if (parsedReport != null) {
        SoundService.playSuccess();
      } else {
        SoundService.playError();
      }
    } else {
      setState(() {
        _errorMessage = 'Erreur lors de l\'analyse OCR avec Google Vision API.';
        isScanning = false;
      });
      print('[DEBUG] Erreur analyse OCR: $_errorMessage');
      SoundService.playError();
    }
  }

  Future<void> _startScan() async {
    print('[DEBUG] _startScan appelé');
    if (uploadedImage == null) {
      print('[DEBUG] Pas d\'image uploadée, appel _handleImageUpload');
      await _handleImageUpload();
      if (uploadedImage == null) return;
    }
    setState(() {
      isScanning = true;
      scanProgress = 0.0;
      rizzLevel = 0.0;
      detectedText = '';
      showResult = false;
      copied = false;
      extractedOcrText = null;
      texteRecu = null;
      texteEnvoye = null;
      iaResponse = null;
      _errorMessage = null;
    });
    print('[DEBUG] Animation scan démarrée');
    _scanLineController.reset();
    _scanLineController.repeat(); // Démarre l'animation de scan
    await Future.delayed(const Duration(seconds: 1));
    try {
      await _scanWithVisionAPIAndAnalyze(File(uploadedImage!.path));
      print('[DEBUG] Analyse terminée, arrêt animation scan');
    } catch (e) {
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        _errorMessage = 'Erreur lors de l\'analyse OCR: ' + e.toString();
        isScanning = false;
      });
      print('[DEBUG] Exception attrapée dans _startScan: $e');
      _scanLineController.stop();
      SoundService.playError();
      return;
    }
    _scanLineController.stop();
    print('[DEBUG] Animation scan stoppée');
    // L'animation s'arrête uniquement quand la réponse IA commence à s'afficher (géré dans _scanWithVisionAPIAndAnalyze)
  }

  void _handleRefresh() {
    setState(() {
      currentEmoji = (currentEmoji + 1) % emojis.length;
      List<String> types = responseTypes.keys.toList();
      int currentIndex = types.indexOf(responseType);
      responseType = types[(currentIndex + 1) % types.length];
      rizzLevel = 0.0;
    });
    _rizzController.reset();
  }

  void _handleCardDoubleClick() {
    // _handleCardDoubleClick supprimé
  }

  void _goBack() {
    if (report != null && uploadedImageBytes != null) {
      Navigator.of(context).pop({
        'report': report,
        'uploadedImageBytes': uploadedImageBytes,
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isPremium == false) {
      return PremiumLockOverlay(
        feature: 'upload_screenshot',
        title: 'Analyse de Screenshots',
        description: 'Analysez vos captures d\'écran de conversations pour recevoir des conseils personnalisés.',
        icon: Icons.image_search,
        child: Scaffold(
          body: AppTheme.buildPickupScreenBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScanArea(MediaQuery.of(context).size.width),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: AppTheme.buildPickupScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header avec bouton retour et logo
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                        // Zone de scan
                        _buildScanArea(screenWidth),
                        const SizedBox(height: 24),
                        // Affichage des erreurs si pas de résultat
                        if (showResult && detectedText.isEmpty && _errorMessage != null && _errorMessage!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.errorColor.withAlpha(77),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppTheme.errorColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Erreur de traitement',
                                      style: TextStyle(
                                        color: AppTheme.errorColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // PAS de boutons de contrôle ni d'indicateur de mode après la réponse IA
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

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Bouton de retour
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 40,
                height: 40,
      decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white.withAlpha(204),
                  size: 20,
                ),
              ),
            ),
          ),

          // Logo centré
          Center(
            child: AnimatedBuilder(
              animation: _holographicAnimation,
              builder: (context, child) {
                return Container(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanArea(double screenWidth) {
    print('[DEBUG][buildScanArea] isScanning=$isScanning, showResult=$showResult, report=${report != null}, detectedText="$detectedText", _errorMessage="${_errorMessage}"');
    return Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 300),
              child: AspectRatio(
                aspectRatio: 9 / 17,
        child: uploadedImage == null
            ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                      Icons.image_outlined,
                      size: 64,
                                                        color: Colors.white.withAlpha(153),
                                                      ),
                    const SizedBox(height: 16),
                                                      Text(
                      'Cliquez sur "Générer" pour\nsélectionner une image',
                      textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white.withAlpha(153),
                        fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
              )
            : FutureBuilder<Uint8List>(
                future: kIsWeb ? uploadedImage!.readAsBytes() : null,
                builder: (context, snapshot) {
                  final imageWidget = kIsWeb
                      ? (snapshot.hasData
                          ? Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            )
                          : Center(child: CircularProgressIndicator()))
                      : Image.file(
                          File(uploadedImage!.path),
                          fit: BoxFit.cover,
                        );
                  return AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      // --- Glassmorphism & Glow ---
                      final scanLineY = _scanLineAnimation.value;
                      final particles = List.generate(6, (i) {
                        final offset = (i - 2.5) * 30.0;
                        return Positioned(
                          left: 60.0 + i * 30.0 + (scanLineY % 20),
                          top: scanLineY + offset,
                          child: AnimatedOpacity(
                            opacity: isScanning ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: 7,
                              height: 7,
                                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.cyanAccent.withAlpha(179),
                                    Colors.blueAccent.withAlpha(51),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withAlpha(128),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                                    ),
                                ],
                              ),
                                              ),
                                            ),
                                          );
                      });
                      return Stack(
                        children: [
                          // Image uploadée (toujours visible)
                          Positioned.fill(child: imageWidget),

                          // Glassmorphism overlay
                          if (isScanning)
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  color: Colors.white.withAlpha(26),
                                            ),
                                          ),
                            ),

                          // Border glow
                          if (isScanning)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                          decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withAlpha(46),
                                        blurRadius: 32,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.blueAccent.withAlpha(26),
                                        blurRadius: 64,
                                        spreadRadius: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                    ),
                            ),

                          // Ligne de scan moderne
                            if (isScanning)
                              Positioned(
                              left: 0,
                              right: 0,
                              top: scanLineY,
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0x8000E5FF),
                                        Color(0x337C4DFF),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x8000E5FF),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Color(0x337C4DFF),
                                        blurRadius: 32,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Particules animées
                          if (isScanning) ...particles,

                          // Résultat IA
                          if (showResult && report != null)
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                color: Colors.black.withAlpha(77),
                                child: Center(
                                  child: SizedBox(
                                    width: 440,
                                    height: 600,
                                    child: FlipableChatAnalysisCard(
                                      report: report!,
                                      uploadedImageBytes: uploadedImageBytes,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Résultat OCR simple (web ou fallback)
                          if (showResult && report == null && detectedText.isNotEmpty)
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                color: Colors.black.withAlpha(77),
                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(230),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        detectedText,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Erreur
                          if (showResult && detectedText.isEmpty && _errorMessage != null && _errorMessage!.isNotEmpty)
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                color: Colors.black.withAlpha(77),
                                child: Center(
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.errorColor.withAlpha(77),
                                        width: 1,
                                      ),
                                    ),
                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                    children: [
                      Icon(
                                              Icons.error_outline,
                                              color: AppTheme.errorColor,
                                              size: 18,
                      ),
                                            const SizedBox(width: 8),
                      Text(
                                              'Erreur de traitement',
                        style: TextStyle(
                                                color: AppTheme.errorColor,
                                                fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildProgressBar() {
    return const SizedBox.shrink();
  }

  Widget _buildIAResultCard(Map<String, dynamic> currentResponseType) {
    return const SizedBox.shrink();
  }
}

