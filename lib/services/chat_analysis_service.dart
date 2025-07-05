import 'dart:io';
import '../models/chat_message.dart';
import '../models/chat_analysis_report.dart';
import '../parsers/chat_parsers.dart' as parsers;
import 'openai_service.dart';

class ChatAnalysisService {
  final OpenAIService _openaiService;

  ChatAnalysisService(this._openaiService);

  // Méthodes pour identifier les drapeaux verts et rouges
  List<String> _identifyGreenFlags(List<ChatMessage> messages) {
    List<String> greenFlags = [];
    
    for (var message in messages) {
      String content = message.content.content.toLowerCase();
      
      // Drapeaux verts
      if (content.contains('merci') || content.contains('thanks')) {
        greenFlags.add('Politesse et gratitude');
      }
      if (content.contains('comment ça va') || content.contains('how are you')) {
        greenFlags.add('Intérêt pour le bien-être');
      }
      if (content.contains('félicitations') || content.contains('congratulations')) {
        greenFlags.add('Support et encouragement');
      }
      if (content.contains('je comprends') || content.contains('i understand')) {
        greenFlags.add('Empathie et compréhension');
      }
      if (content.contains('super') || content.contains('great') || content.contains('awesome')) {
        greenFlags.add('Positivité et enthousiasme');
      }
    }
    
    return greenFlags.toSet().toList(); // Éliminer les doublons
  }

  List<String> _identifyRedFlags(List<ChatMessage> messages) {
    List<String> redFlags = [];
    
    for (var message in messages) {
      String content = message.content.content.toLowerCase();
      
      // Drapeaux rouges
      if (content.contains('salope') || content.contains('bitch') || content.contains('pute')) {
        redFlags.add('Langage irrespectueux');
      }
      if (content.contains('nudes') || content.contains('photo nue') || content.contains('sexy')) {
        redFlags.add('Demandes inappropriées');
      }
      if (content.contains('ex') || content.contains('ancien') || content.contains('former')) {
        redFlags.add('Références aux ex');
      }
      if (content.contains('argent') || content.contains('money') || content.contains('riche')) {
        redFlags.add('Intérêt pour l\'argent');
      }
      if (content.contains('mariage') || content.contains('bébé') || content.contains('baby')) {
        redFlags.add('Attentes trop rapides');
      }
    }
    
    return redFlags.toSet().toList(); // Éliminer les doublons
  }

  // Méthode pour générer des recommandations
  List<String> _generateRecommendations(List<ChatMessage> messages, String analysis) {
    List<String> recommendations = [];
    
    // Recommandations basées sur l'analyse
    if (analysis.contains('trop formel')) {
      recommendations.add('Essayez d\'être plus décontracté et naturel');
    }
    if (analysis.contains('trop court')) {
      recommendations.add('Développez vos réponses pour montrer plus d\'intérêt');
    }
    if (analysis.contains('trop direct')) {
      recommendations.add('Soyez plus subtil et romantique');
    }
    if (analysis.contains('pas assez d\'émotion')) {
      recommendations.add('Ajoutez plus d\'émotion et de personnalité');
    }
    
    // Recommandations générales
    recommendations.add('Posez des questions ouvertes pour encourager la conversation');
    recommendations.add('Partagez des anecdotes personnelles pour créer un lien');
    recommendations.add('Utilisez des emojis pour ajouter de la chaleur');
    recommendations.add('Répondez dans un délai raisonnable (pas trop rapide, pas trop lent)');
    
    return recommendations;
  }

  Future<List<ChatMessage>> parseChatText(String text) async {
    try {
      // Utiliser le parser existant
      return parsers.parseChatText(text);
    } catch (e) {
      print('Erreur lors du parsing du chat: $e');
      throw Exception('Impossible de parser le texte du chat');
    }
  }

  Future<ChatAnalysisReport> analyzeChat(List<ChatMessage> messages) async {
    try {
      print('Début de l\'analyse du chat avec ${messages.length} messages');
      
      // Préparer le contexte pour OpenAI
      String conversationContext = messages.map((msg) {
        String role = msg.isUser ? 'User' : 'Other';
        return '$role: ${msg.content.content}';
      }).join('\n');
      
      // Analyser avec OpenAI
      String analysisPrompt = '''
Analysez cette conversation de séduction et fournissez une évaluation détaillée :

$conversationContext

Veuillez analyser :
1. Le ton général de la conversation
2. L'engagement des deux parties
3. Les moments forts et faibles
4. Les opportunités manquées
5. Le niveau de compatibilité
6. Suggestions d'amélioration

Répondez en français de manière constructive et détaillée.
''';

      String analysis = await _openaiService.analyzeText(analysisPrompt);
      
      // Calculer le score d'engagement
      int engagementScore = _calculateEngagementScore(messages);
      
      // Identifier les drapeaux
      List<String> greenFlags = _identifyGreenFlags(messages);
      List<String> redFlags = _identifyRedFlags(messages);
      
      // Générer des recommandations
      List<String> recommendations = _generateRecommendations(messages, analysis);
      
      // Créer le rapport
      ChatAnalysisReport report = ChatAnalysisReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        messages: messages,
        analysis: analysis,
        engagementScore: engagementScore,
        greenFlags: greenFlags,
        redFlags: redFlags,
        recommendations: recommendations,
        overallRating: _calculateOverallRating(engagementScore, greenFlags.length, redFlags.length),
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
      
      print('Analyse terminée avec succès');
      return report;
      
    } catch (e) {
      print('Erreur lors de l\'analyse du chat: $e');
      throw Exception('Impossible d\'analyser le chat: $e');
    }
  }

  int _calculateEngagementScore(List<ChatMessage> messages) {
    if (messages.isEmpty) return 0;
    
    int score = 0;
    int userMessages = 0;
    int otherMessages = 0;
    
    for (var message in messages) {
      if (message.isUser) {
        userMessages++;
        // Bonus pour les messages longs
        if (message.content.content.length > 50) {
          score += 2;
        }
        if (message.content.content.length > 100) {
          score += 3;
        }
      } else {
        otherMessages++;
        // Bonus pour les réponses rapides de l'autre personne
        if (message.content.content.length > 30) {
          score += 2;
        }
      }
      
      // Bonus pour les questions
      if (message.content.content.contains('?')) {
        score += 1;
      }
      
      // Bonus pour les emojis
      if (message.content.content.contains('😊') || 
          message.content.content.contains('❤️') ||
          message.content.content.contains('😍')) {
        score += 1;
      }
    }
    
    // Calculer le ratio d'engagement
    if (otherMessages > 0) {
      double ratio = userMessages / otherMessages;
      if (ratio >= 0.8 && ratio <= 1.2) {
        score += 10; // Bon équilibre
      } else if (ratio > 1.2) {
        score += 5; // L'utilisateur parle plus
      }
    }
    
    return score.clamp(0, 100);
  }

  double _calculateOverallRating(int engagementScore, int greenFlags, int redFlags) {
    double baseScore = engagementScore / 100.0;
    
    // Bonus pour les drapeaux verts
    double greenBonus = greenFlags * 0.1;
    
    // Malus pour les drapeaux rouges
    double redMalus = redFlags * 0.15;
    
    double finalScore = baseScore + greenBonus - redMalus;
    return finalScore.clamp(0.0, 5.0);
  }

  Future<ChatAnalysisReport> analyzeScreenshot(File imageFile) async {
    try {
      print('Début de l\'analyse de screenshot');
      
      // Pour l'instant, on simule l'extraction de texte
      String extractedText = "Simulation d'extraction de texte depuis l'image";
      
      // Parser le chat
      List<ChatMessage> messages = await parseChatText(extractedText);
      print('Messages parsés: ${messages.length}');
      
      // Analyser le chat
      ChatAnalysisReport report = await analyzeChat(messages);
      
      print('Analyse de screenshot terminée');
      return report;
      
    } catch (e) {
      print('Erreur lors de l\'analyse de screenshot: $e');
      throw Exception('Impossible d\'analyser le screenshot: $e');
    }
  }

  Future<ChatAnalysisReport> analyzeTextInput(String text) async {
    try {
      print('Début de l\'analyse de texte');
      
      // Parser le chat
      List<ChatMessage> messages = await parseChatText(text);
      print('Messages parsés: ${messages.length}');
      
      // Analyser le chat
      ChatAnalysisReport report = await analyzeChat(messages);
      
      print('Analyse de texte terminée');
      return report;
      
    } catch (e) {
      print('Erreur lors de l\'analyse de texte: $e');
      throw Exception('Impossible d\'analyser le texte: $e');
    }
  }

  Future<void> saveAnalysisReport(ChatAnalysisReport report) async {
    try {
      // TODO: Implémenter la sauvegarde dans la base de données
      print('Sauvegarde du rapport d\'analyse: ${report.id}');
      
      // Pour l'instant, on simule la sauvegarde
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Rapport sauvegardé avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      throw Exception('Impossible de sauvegarder le rapport: $e');
    }
  }

  Future<List<ChatAnalysisReport>> getAnalysisHistory() async {
    try {
      // TODO: Implémenter la récupération depuis la base de données
      print('Récupération de l\'historique des analyses');
      
      // Pour l'instant, on retourne une liste vide
      await Future.delayed(const Duration(milliseconds: 300));
      
      return [];
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      throw Exception('Impossible de récupérer l\'historique: $e');
    }
  }

  void dispose() {
    // Nettoyage si nécessaire
  }
} 