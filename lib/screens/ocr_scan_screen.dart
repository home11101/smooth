import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/responsive_helper.dart';
import '../services/cache_service.dart';

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

import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';
import 'dart:ui';

class OptimizedRizzScanner extends StatefulWidget {
  const OptimizedRizzScanner({super.key});

  @override
  _OptimizedRizzScannerState createState() => _OptimizedRizzScannerState();
}

class _OptimizedRizzScannerState extends State<OptimizedRizzScanner>
    with TickerProviderStateMixin {
  // État de l'application
  bool isScanning = false;
  double scanProgress = 0.0;
  double scanLinePosition = -100;
  String detectedText = '';
  int currentEmoji = 0;
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

  // Controllers d'animation
  late AnimationController _scanLineController;
  late AnimationController _progressController;
  late AnimationController _rizzController;

  late AnimationController _thinkingController;
  late AnimationController _shimmerController;
  late AnimationController _holographicController;
  late AnimationController _quantumBorderController;
  late AnimationController _cardAppearController;

  // Animations
  late Animation<double> _scanLineAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _rizzAnimation;

  late Animation<double> _shimmerAnimation;
  late Animation<double> _holographicAnimation;
  late Animation<double> _quantumBorderAnimation;
  late Animation<double> _cardAppearAnimation;

  final ImagePicker _picker = ImagePicker();

  final List<String> emojis = ['🔥', '😎', '💯', '🚀', '⚡', '🌟', '👑', '💎'];

  final Map<String, Map<String, dynamic>> responseTypes = {
    'smooth': {
      'emoji': '🔥',
      'label': 'Smooth',
      'color': Color(0xFF7C4DFF),
    },
    'sincere': {
      'emoji': '💖',
      'label': 'Sincère',
      'color': Color(0xFFF43F5E),
    },
    'sexy': {
      'emoji': '😈',
      'label': 'Sexy',
      'color': Color(0xFFFF9800),
    },
    'drole': {
      'emoji': '😂',
      'label': 'Drôle',
      'color': Color(0xFF00B8D4),
    },
    'intelligent': {
      'emoji': '🧠',
      'label': 'Intelligent',
      'color': Color(0xFF4CAF50),
    },
  };

  late VisionService visionService;
  late OpenAIService openaiService;
  String? iaResponse;

  // Historique des analyses (réponse IA + image + rapport structuré si dispo)
  final List<Map<String, dynamic>> _analysisHistory = [];
  
  // Nouveau : État pour gérer les régénérations
  bool _hasFirstResponse = false;
  bool _isGenerating = false;

  bool? _isPremium;

  final List<String> _responseTypeKeys = ['smooth', 'sincere', 'sexy', 'drole', 'intelligent'];
  int _responseTypeIndex = 0;
  String get responseType => _responseTypeKeys[_responseTypeIndex];

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
    
    // Charger l'historique depuis le cache
    _loadHistoryFromCache();
    
    // Ouvre la galerie dès l'arrivée sur l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleImageUpload();
      if (uploadedImage != null) {
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

    

    // Animation du niveau de Rizz
    _rizzController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rizzAnimation = Tween<double>(
      begin: 0,
      end: 90.0, // Valeur par défaut pour smooth
    ).animate(CurvedAnimation(
      parent: _rizzController,
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

    // Animation bordure quantique
    _quantumBorderController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _quantumBorderAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _quantumBorderController,
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
    _quantumBorderController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _progressController.dispose();
    _rizzController.dispose();
    _thinkingController.dispose();
    _shimmerController.dispose();
    _holographicController.dispose();
    _quantumBorderController.dispose();
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
          isScanning = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _errorMessage = "Aucune image sélectionnée.";
          isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        isScanning = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _errorMessage = "Erreur lors de la sélection d'image : $e";
        isScanning = false;
      });
    }
  }

  Future<void> _scanWithVisionAPIAndAnalyze(File image) async {
    final result = kIsWeb
        ? await visionService.detectAndSplitMessagesFromBytes(await uploadedImage!.readAsBytes())
        : await visionService.detectAndSplitMessages(image);
    if (result != null) {
      setState(() {
        texteRecu = result['messagesRecus'];
        texteEnvoye = result['messagesEnvoyes'];
        detectedText = (texteRecu ?? '') + '\n' + (texteEnvoye ?? '');
      });
      // Appel IA spécifique à cet écran : analyzeConversation
      final iaResult = await openaiService.analyzeConversation(
        texteRecu: texteRecu ?? '',
        texteEnvoye: texteEnvoye ?? '',
        typeReponse: responseType,
      );
      setState(() {
        iaResponse = iaResult;
        showResult = true;
        isScanning = false;
        _hasFirstResponse = true;
        _analysisHistory.add({
          'iaResponse': iaResult,
          'uploadedImageBytes': uploadedImageBytes,
          'responseType': responseType,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      // Sauvegarder l'historique
      await _saveHistoryToCache();
    } else {
      setState(() {
        _errorMessage = 'Erreur lors de l\'analyse OCR avec Google Vision API.';
        isScanning = false;
      });
    }
  }

  Future<void> _startScan() async {
    if (uploadedImage == null) {
      await _handleImageUpload();
      return;
    }
    
    // Si on a déjà une première réponse, on ne fait plus de scan
    if (_hasFirstResponse) {
      await _regenerateResponse();
      return;
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
    _scanLineController.reset();
    _scanLineController.repeat(); // Démarre l'animation de scan
    await Future.delayed(const Duration(seconds: 1));
    try {
      await _scanWithVisionAPIAndAnalyze(File(uploadedImage!.path));
    } catch (e) {
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        _errorMessage = 'Erreur lors de l\'analyse OCR: ' + e.toString();
            isScanning = false;
          });
          _scanLineController.stop();
      return;
    }
    _scanLineController.stop();
    // L'animation s'arrête uniquement quand la réponse IA commence à s'afficher (géré dans _scanWithVisionAPIAndAnalyze)
  }

  void _handleRefresh() {
    setState(() {
      currentEmoji = (currentEmoji + 1) % emojis.length;
      List<String> types = responseTypes.keys.toList();
      int currentIndex = types.indexOf(responseType);
      _responseTypeIndex = (currentIndex + 1) % types.length;
      rizzLevel = 0.0;
    });
    _rizzController.reset();
  }

  void _handleCardDoubleClick() {
    // _handleCardDoubleClick supprimé
  }

  void _goBack() {
    if (_analysisHistory.isNotEmpty) {
      Navigator.of(context).pop({
        'analysisHistory': _analysisHistory,
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _removeCard(int index) {
    setState(() {
      _analysisHistory.removeAt(index);
    });
    // Sauvegarder l'historique après suppression
    _saveHistoryToCache();
  }

  // Nouvelle méthode pour régénérer une réponse sans nouveau scan
  Future<void> _regenerateResponse() async {
    if (texteRecu == null || texteEnvoye == null) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final iaResult = await openaiService.analyzeConversation(
        texteRecu: texteRecu!,
        texteEnvoye: texteEnvoye!,
        typeReponse: responseType,
      );
      
      setState(() {
        _isGenerating = false;
        _analysisHistory.add({
          'iaResponse': iaResult,
          'uploadedImageBytes': uploadedImageBytes,
          'responseType': responseType,
          'timestamp': DateTime.now().toIso8601String(),
          'isRegeneration': true, // Marquer comme régénération
        });
      });
      
      // Sauvegarder l'historique
      await _saveHistoryToCache();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Erreur lors de la régénération: $e';
      });
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
        feature: 'ocr_scan',
        title: 'Scan OCR de Documents',
        description: 'Analysez vos documents et captures d\'écran pour extraire du texte et recevoir des conseils.',
        icon: Icons.document_scanner,
        child: Scaffold(
          body: AppTheme.buildPickupScreenBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                    _buildScanArea(),
                    SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 1.5),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      body: AppTheme.buildPickupScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 2),
                _buildScanArea(),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context) * 1.5),
                
                // Affichage de l'historique des réponses
                if (_analysisHistory.isNotEmpty) ...[
                  _buildHistorySection(),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                ],
                
                // Affichage de la réponse en cours de génération
                if (_isGenerating)
                  _buildGeneratingIndicator(),
                
                // Affichage du résultat principal (première réponse)
                if (showResult && iaResponse != null && !_hasFirstResponse)
                  _buildMainResultCard(),
                
                // Boutons de contrôle
                if (_hasFirstResponse)
                  _buildControlButtons(),
                
                // Affichage des erreurs
                if (_errorMessage != null)
                  _buildErrorMessage(),
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

  Widget _buildScanArea() {
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
                      color: Colors.white.withAlpha(64),
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
            : Stack(
                children: [
                  // Image principale
                  Positioned.fill(
                    child: kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: uploadedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          )
                        : Image.file(
                            File(uploadedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                  
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
                  
                  // Ligne de scan moderne avec effets
                  if (isScanning)
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
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
                            // Ligne de scan moderne
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
                            ...particles,
                          ],
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  // Nouvelle méthode pour charger l'historique depuis le cache
  Future<void> _loadHistoryFromCache() async {
    try {
      final cachedHistory = await CacheService.getCachedAnalysisHistory('ocr_scan_history');
      if (cachedHistory != null && cachedHistory.isNotEmpty) {
        setState(() {
          _analysisHistory.clear();
          _analysisHistory.addAll(cachedHistory);
          _hasFirstResponse = _analysisHistory.isNotEmpty;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'historique: $e');
    }
  }

  // Nouvelle méthode pour sauvegarder l'historique dans le cache
  Future<void> _saveHistoryToCache() async {
    try {
      await CacheService.cacheAnalysisHistory('ocr_scan_history', _analysisHistory);
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'historique: $e');
    }
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des analyses',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200, // Hauteur fixe au lieu d'Expanded
          child: ListView.builder(
            itemCount: _analysisHistory.length,
            itemBuilder: (context, index) {
              final item = _analysisHistory[index];
              final isRegeneration = item['isRegeneration'] == true;
              return _buildHistoryCard(item, index, isRegeneration);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingIndicator() {
    return Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'IA en réflexion...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
    );
  }

  Widget _buildMainResultCard() {
    return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withAlpha(25),
                              Colors.white.withAlpha(10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(40),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analyse IA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ModernTypingCard(text: iaResponse!),
                          ],
                        ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
                        children: [
                          GestureDetector(
                            onTap: isScanning
                                ? null
                                : () {
                                    setState(() {
                                      _responseTypeIndex = (_responseTypeIndex + 1) % _responseTypeKeys.length;
                                    });
                                  },
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent.withAlpha(46),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  responseTypes[responseType]!['emoji'],
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isScanning ? null : _startScan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                elevation: 6,
                                shadowColor: Colors.blueAccent.withOpacity(0.18),
                              ),
                              child: Text('Générer une réponse ${responseTypes[responseType]!['label']}'),
                            ),
                          ),
                        ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Erreur : aucune réponse IA reçue.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Nouvelle méthode pour construire une carte d'historique
  Widget _buildHistoryCard(Map<String, dynamic> item, int index, bool isRegeneration) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.responsiveSpacing(context)),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveHelper.responsiveSpacing(context) * 1.5),
                decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRegeneration 
                  ? [
                      Colors.white.withAlpha(15),
                      Colors.white.withAlpha(5),
                    ]
                  : [
                      Colors.white.withAlpha(25),
                      Colors.white.withAlpha(10),
                    ],
              ),
              borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveSpacing(context)),
                  border: Border.all(
                color: Colors.white.withAlpha(30),
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: isRegeneration ? 10 : 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
          ),
        ],
      ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.responsiveSpacing(context),
                        vertical: ResponsiveHelper.responsiveSpacing(context) * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: responseTypes[item['responseType'] ?? 'smooth']?['color']?.withAlpha(51) ?? Colors.blue.withAlpha(51),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveSpacing(context)),
                      ),
                      child: Text(
                        '${responseTypes[item['responseType'] ?? 'smooth']?['emoji']} ${responseTypes[item['responseType'] ?? 'smooth']?['label']}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 12, medium: 14, large: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isRegeneration) ...[
                      SizedBox(width: ResponsiveHelper.responsiveSpacing(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.responsiveSpacing(context),
                          vertical: ResponsiveHelper.responsiveSpacing(context) * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(51),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveSpacing(context)),
                        ),
                        child: Text(
                          'Régénération',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, small: 10, medium: 12, large: 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context)),
                ModernTypingCard(
                  text: item['iaResponse'] ?? '',
                  duration: Duration(milliseconds: isRegeneration ? 20 : 30),
                ),
              ],
            ),
          ),
          // Bouton de suppression
                            Positioned(
            top: ResponsiveHelper.responsiveSpacing(context),
            right: ResponsiveHelper.responsiveSpacing(context),
            child: GestureDetector(
              onTap: () => _removeCard(index),
                                child: Container(
                width: ResponsiveHelper.getAdaptiveButtonHeight(context) * 0.6,
                height: ResponsiveHelper.getAdaptiveButtonHeight(context) * 0.6,
                                  decoration: BoxDecoration(
                  color: Colors.red.withAlpha(51),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getAdaptiveButtonHeight(context) * 0.3),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: ResponsiveHelper.getAdaptiveFontSize(context, small: 14, medium: 16, large: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget principal pour l'app
class RizzScannerApp extends StatelessWidget {
  const RizzScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rizz Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: OptimizedRizzScanner(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Dépendances nécessaires dans pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
*/

// TODO: Configuration additionnelle nécessaire:
// 1. Ajouter les permissions dans android/app/src/main/AndroidManifest.xml:
//    <uses-permission android:name="android.permission.INTERNET" />
//    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
//    <uses-permission android:name="android.permission.CAMERA" />

// 2. Pour iOS, ajouter dans ios/Runner/Info.plist:
//    <key>NSCameraUsageDescription</key>
//    <string>Cette app a besoin d'accéder à la caméra pour prendre des photos</string>
//    <key>NSPhotoLibraryUsageDescription</key>
//    <string>Cette app a besoin d'accéder aux photos pour sélectionner des images</string>

// 3. Configurer votre URL de backend dans la méthode _callBackendAPI
// 4. Adapter la structure de réponse JSON selon votre API
// 5. Ajouter une gestion d'erreur plus sophistiquée selon vos besoins
// 6. Implémenter l'authentification si nécessaire
// 7. Ajouter le logo dans assets/images/logo.png

class ModernTypingCard extends StatefulWidget {
  final String text;
  final Duration duration;
  const ModernTypingCard({Key? key, required this.text, this.duration = const Duration(milliseconds: 30)}) : super(key: key);

  @override
  State<ModernTypingCard> createState() => _ModernTypingCardState();
}

class _ModernTypingCardState extends State<ModernTypingCard> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _displayed = '';
    _index = 0;
    _timer?.cancel();
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayed += widget.text[_index];
          _index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ModernTypingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        _displayed,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}
