import '../utils/app_theme.dart';

// Page cible pour le bouton "Télécharger une capture d'écran"
// Nettoyage des imports inutilisés
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_analysis_service.dart';
import '../services/openai_service.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import '../models/chat_analysis_report.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/modern_appbar.dart';

class UploadChatAnalysisScreen extends StatefulWidget {
  const UploadChatAnalysisScreen({super.key});

  @override
  State<UploadChatAnalysisScreen> createState() => _UploadChatAnalysisScreenState();
}

class _UploadChatAnalysisScreenState extends State<UploadChatAnalysisScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ChatAnalysisService _chatAnalysisService = ChatAnalysisService(OpenAIService());
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  ChatAnalysisReport? _analysisReport;
  final int maxImages = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppTheme.lightBlue],
          ),
        ),
        child: Column(
          children: [
            ModernAppBar(
              onMenuPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: FutureBuilder<bool>(
                future: _subscriptionService.isPremium(),
                builder: (context, snapshot) {
                  final isPremium = snapshot.data ?? false;
                  
                  if (!isPremium) {
                    return PremiumLockWidget(
                      title: 'Analyse de Chat',
                      description: 'Analysez vos conversations textuelles pour obtenir des insights et des recommandations personnalisées.',
                      icon: Icons.analytics_outlined,
                      feature: 'chat_analysis',
                      onUnlock: () {
                        Navigator.pushNamed(context, '/premium');
                      },
                    );
                  }
                  
                  return _buildMainContent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildUploadSection(),
            const SizedBox(height: 24),
            if (_isAnalyzing) _buildLoadingSection(),
            if (_analysisReport != null) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Analyse de Chat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analysez vos conversations textuelles pour obtenir des insights et des recommandations personnalisées.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Téléchargez vos conversations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sélectionnez les captures d\'écran de vos conversations pour obtenir une analyse détaillée.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Sélectionner des images'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Analyse en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Veuillez patienter pendant que nous analysons vos conversations.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_analysisReport == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Résultats de l\'analyse',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: _shareResults,
                icon: const Icon(Icons.share),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreCard(),
          const SizedBox(height: 16),
          _buildAnalysisText(),
          const SizedBox(height: 16),
          _buildFlagsSection(),
          const SizedBox(height: 16),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score d\'engagement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_analysisReport!.engagementScore}/100',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Note globale',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_analysisReport!.overallRating.toStringAsFixed(1)}/5.0',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse détaillée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _analysisReport!.analysis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drapeaux détectés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFlagCard(
                'Drapeaux verts',
                _analysisReport!.greenFlags,
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFlagCard(
                'Drapeaux rouges',
                _analysisReport!.redFlags,
                Colors.red,
                Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagCard(String title, List<String> flags, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (flags.isEmpty)
            Text(
              'Aucun détecté',
              style: TextStyle(
                fontSize: 12,
                color: color.withAlpha(170),
              ),
            )
          else
            ...flags.take(3).map((flag) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $flag',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            )),
          if (flags.length > 3)
            Text(
              '+${flags.length - 3} autres',
              style: TextStyle(
                fontSize: 12,
                color: color.withAlpha(170),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._analysisReport!.recommendations.map((recommendation) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryBlue.withAlpha(77)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _isAnalyzing = true;
        });

        // Analyser chaque image
        List<ChatAnalysisReport> reports = [];
        for (XFile image in images.take(maxImages)) {
          try {
            File imageFile = File(image.path);
            ChatAnalysisReport report = await _chatAnalysisService.analyzeScreenshot(imageFile);
            reports.add(report);
          } catch (e) {
            print('Erreur lors de l\'analyse de l\'image: $e');
          }
        }

        // Combiner les résultats
        if (reports.isNotEmpty) {
          setState(() {
            _analysisReport = _combineReports(reports);
            _isAnalyzing = false;
          });
        } else {
          setState(() {
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  ChatAnalysisReport _combineReports(List<ChatAnalysisReport> reports) {
    // Combiner tous les messages
    List<ChatMessage> allMessages = [];
    for (var report in reports) {
      allMessages.addAll(report.messages);
    }

    // Calculer les scores moyens
    int totalEngagement = reports.fold(0, (sum, report) => sum + report.engagementScore);
    double totalRating = reports.fold(0.0, (sum, report) => sum + report.overallRating);
    
    // Combiner les drapeaux
    Set<String> allGreenFlags = {};
    Set<String> allRedFlags = {};
    for (var report in reports) {
      allGreenFlags.addAll(report.greenFlags);
      allRedFlags.addAll(report.redFlags);
    }

    // Combiner les recommandations
    Set<String> allRecommendations = {};
    for (var report in reports) {
      allRecommendations.addAll(report.recommendations);
    }

    // Combiner les analyses
    String combinedAnalysis = reports.map((r) => r.analysis).join('\n\n---\n\n');

    return ChatAnalysisReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      messages: allMessages,
      analysis: combinedAnalysis,
      engagementScore: (totalEngagement / reports.length).round(),
      greenFlags: allGreenFlags.toList(),
      redFlags: allRedFlags.toList(),
      recommendations: allRecommendations.toList(),
      overallRating: totalRating / reports.length,
      nombreMessagesVous: 0,
      nombreMessagesEux: 0,
      niveauInteretVous: 0,
      niveauInteretEux: 0,
      motsSignificatifsVous: const [],
      motsSignificatifsEux: const [],
      alertesRouges: const [],
      signauxPositifs: const [],
      styleAttachementVous: '',
      styleAttachementEux: '',
      scoreCompatibilite: 0,
    );
  }

  void _shareResults() {
    if (_analysisReport != null) {
      String shareText = '''
Analyse de conversation Smooth AI

Score d'engagement: ${_analysisReport!.engagementScore}/100
Note globale: ${_analysisReport!.overallRating.toStringAsFixed(1)}/5.0

Drapeaux verts: ${_analysisReport!.greenFlags.length}
Drapeaux rouges: ${_analysisReport!.redFlags.length}

Recommandations principales:
${_analysisReport!.recommendations.take(3).map((r) => '• $r').join('\n')}

Analyse complète disponible dans l'app Smooth AI.
''';

      SharePlus.instance.share(
        ShareParams(text: shareText),
      );
    }
  }

  @override
  void dispose() {
    _chatAnalysisService.dispose();
    super.dispose();
  }
}