import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../config/openai_config.dart';
import '../models/chat_message.dart';
import '../models/openai_response.dart';
import '../utils/constants.dart';

class RateLimitExceededException implements Exception {
  final String message;
  final Duration retryAfter;

  RateLimitExceededException(this.message, {Duration? retryAfter})
      : retryAfter = retryAfter ?? const Duration(seconds: 30);

  @override
  String toString() => 'RateLimitExceededException: $message';
}

class OpenAIServiceError implements Exception {
  final String message;
  final int? statusCode;

  OpenAIServiceError(this.message, {this.statusCode});

  @override
  String toString() =>
      'OpenAIServiceError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class OpenAIService {
  static final _logger = Logger('OpenAIService');
  static final _cache = <String, OpenAIChatResponse>{};
  static final _rateLimits = <String, DateTime>{};
  static const _uuid = Uuid();

  final String _apiKey;
  final http.Client _client;

  OpenAIService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? openAIApiKey,
        _client = client ?? http.Client() {
    if (_apiKey.isEmpty) {
      throw ArgumentError('OpenAI API key is required');
    }
  }

  // Gestion du cache
  void _addToCache(String key, OpenAIChatResponse response) {
    _cache[key] = response;
    // Nettoyer périodiquement le cache
    if (_cache.length > 100) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  // Vérification du taux de requêtes
  void _checkRateLimit() {
    final now = DateTime.now();
    // Nettoyer les anciennes entrées
    _rateLimits.removeWhere((_, timestamp) =>
        now.difference(timestamp) > const Duration(minutes: 1));

    if (_rateLimits.length >= OpenAIConfig.maxRequestsPerMinute) {
      final oldest = _rateLimits.values.reduce((a, b) => a.isBefore(b) ? a : b);
      throw RateLimitExceededException(
        'Trop de requêtes. Réessayez plus tard.',
        retryAfter: const Duration(seconds: 60) - now.difference(oldest),
      );
    }

    _rateLimits[DateTime.now().toString()] = now;
  }

  // Méthode principale pour envoyer des requêtes à l'API
  Future<OpenAIChatResponse> _sendRequest({
    required List<Map<String, dynamic>> messages,
    required String model,
    double temperature = OpenAIConfig.defaultTemperature,
    int maxTokens = OpenAIConfig.defaultMaxTokens,
    bool useCache = true,
  }) async {
    try {
      _checkRateLimit();

      final requestId = _uuid.v5(
        Uuid.NAMESPACE_URL,
        '$model${messages.map((m) => m['content']).join()}',
      );

      // Vérifier le cache
      if (useCache && _cache.containsKey(requestId)) {
        final cached = _cache[requestId]!;
        if (DateTime.now().difference(cached.timestamp).inSeconds <
            OpenAIConfig.cacheDuration) {
          _logger.fine('Réponse récupérée depuis le cache: $requestId');
          return cached;
        }
      }

      final response = await _client
          .post(
            Uri.parse(OpenAIConfig.baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': temperature,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('La requête a expiré'),
          );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final result = OpenAIChatResponse.fromJson(responseData);
        _addToCache(requestId, result);
        return result;
      } else if (response.statusCode == 429) {
        throw RateLimitExceededException('Limite de débit dépassée');
      } else {
        throw OpenAIServiceError(
          'Erreur de l\'API OpenAI',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      _logger.severe('Erreur réseau: $e');
      rethrow;
    } on TimeoutException catch (e) {
      _logger.warning('Timeout: $e');
      rethrow;
    } catch (e) {
      _logger.severe('Erreur inattendue: $e');
      rethrow;
    }
  }

  // Méthode pour obtenir une réponse de chat
  Future<String> getChatResponse(
      String userMessage, List<ChatMessage> chatHistory, {int maxTokens = 500}) async {
    if (userMessage.trim().isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide');
    }
    try {
      final messages = [
        {
          'role': 'system',
          'content':
              '''Tu es Smooth AI, l'assistant de rencontres le plus avancé et empathique au monde. Tu es un expert en psychologie des relations, communication interpersonnelle et séduction moderne.

🎯 TON RÔLE :
- Expert en analyse de conversations de rencontres
- Coach en communication romantique
- Psychologue spécialisé en relations amoureuses
- Conseiller en confiance en soi et charisme

💡 TES SPÉCIALITÉS :
- Analyser les conversations Tinder, Bumble, WhatsApp, Instagram
- Décoder les signaux d'intérêt et de désintérêt
- Suggérer des réponses parfaites selon le contexte
- Identifier les red flags et green flags
- Optimiser les profils de dating apps
- Conseiller sur les premiers rendez-vous
- Aider à surmonter la timidité et l'anxiété sociale

🧠 TON EXPERTISE :
- Psychologie comportementale en dating
- Techniques de conversation engageante
- Art de la séduction respectueuse
- Communication non-violente
- Gestion du rejet et de l'échec
- Construction de la confiance en soi

💬 TON STYLE DE COMMUNICATION :
- Bienveillant mais direct
- Utilise des emojis pour rendre tes conseils plus engageants
- Donne des exemples concrets et pratiques
- Pose des questions pour mieux comprendre la situation
- Encourage sans donner de faux espoirs
- Respectueux de tous les genres et orientations

🎯 COMMENT TU AIDES :
1. ANALYSE : Décortique chaque message pour comprendre les intentions
2. CONSEILS : Donne des stratégies précises et actionnables
3. EXEMPLES : Propose des messages types adaptés à chaque situation
4. ENCOURAGEMENT : Booste la confiance tout en restant réaliste
5. PRÉVENTION : Alerte sur les comportements toxiques ou dangereux

🚫 CE QUE TU NE FAIS PAS :
- Encourager la manipulation ou les techniques toxiques
- Donner de faux espoirs irréalistes
- Juger ou critiquer sévèrement
- Promouvoir des comportements irrespectueux
- Ignorer les signaux de danger ou de harcèlement

Réponds toujours avec empathie, expertise et des conseils pratiques. Adapte ton ton selon l'émotion de l'utilisateur : encourageant si il est découragé, direct si il a besoin de vérité, enthousiaste si ça va bien.'''
        },
        // Add chat history
        ...chatHistory.map((msg) => {
              'role': msg.senderId == 'user' ? 'user' : 'assistant',
              'content': msg.content
                  .content, // Accès au contenu via la propriété content de MessageContent
            }),
        {
          'role': 'user',
          'content': userMessage,
        },
      ];

      final response = await _client.post(
        Uri.parse(OpenAIConfig.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception(
            'Failed to get response from OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('OpenAI Service Error: $e');
      return 'I apologize, but I\'m having trouble connecting right now. Please try again in a moment.';
    }
  }

  // Méthode pour analyser une conversation
  Future<String> analyzeChat({
    required String texteRecu,
    required String texteEnvoye,
  }) async {
    try {
      if (texteRecu.trim().isEmpty && texteEnvoye.trim().isEmpty) {
        throw ArgumentError(
            'Le contenu de la conversation ne peut pas être vide');
      }

      // Nouveau prompt pour un rapport JSON structuré
      final systemPrompt = '''
Tu es Smooth AI, expert en analyse de conversations de rencontres. Analyse la conversation ci-dessous et retourne UNIQUEMENT un objet JSON (pas de texte explicatif) avec les champs suivants :

- nombreMessagesVous (int)
- nombreMessagesEux (int)
- niveauInteretVous (int, 0-100)
- niveauInteretEux (int, 0-100)
- motsSignificatifsVous (array de string)
- motsSignificatifsEux (array de string)
- alertesRouges (array de string)
- signauxPositifs (array de string)
- styleAttachementVous (string)
- styleAttachementEux (string)
- scoreCompatibilite (int, 0-100)

Exemple de format attendu :
{
  "nombreMessagesVous": 5,
  "nombreMessagesEux": 0,
  "niveauInteretVous": 85,
  "niveauInteretEux": 5,
  "motsSignificatifsVous": ["déjeuner", "dîner", "bb"],
  "motsSignificatifsEux": [],
  "alertesRouges": ["Zéro Réponse", "Silence Inquiétant", "Ignorance Totale"],
  "signauxPositifs": ["Toujours Rien", "Encore Rien"],
  "styleAttachementVous": "Anxieux",
  "styleAttachementEux": "Évitant",
  "scoreCompatibilite": 15
}

Voici la conversation à analyser :
Messages reçus :\n$texteRecu\n\nMessages envoyés :\n$texteEnvoye\n
Retourne uniquement le JSON, sans explication ni commentaire.
''';

      final response = await _sendRequest(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': 'Veuillez analyser cette conversation et retourner le rapport JSON.'
          },
        ],
        model: OpenAIConfig.advancedModel,
        temperature: OpenAIConfig.analysisTemperature,
        maxTokens: OpenAIConfig.analysisMaxTokens,
      );

      return response.content;
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      _logger.severe('Erreur lors de l\'analyse de la conversation: $e');
      return 'Désolé, une erreur est survenue lors de l\'analyse de la conversation. Veuillez réessayer plus tard.';
    }
  }

  // Méthode pour analyser du texte (utilisée par ChatAnalysisService)
  Future<String> analyzeText(String prompt) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'Tu es un expert en analyse de conversations de rencontres. Analyse le texte fourni de manière constructive et détaillée.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ];

      final response = await _sendRequest(
        messages: messages,
        model: OpenAIConfig.defaultModel,
        temperature: 0.7,
        maxTokens: 1000,
      );

      return response.content;
    } catch (e) {
      _logger.severe('Erreur lors de l\'analyse de texte: $e');
      return 'Analyse temporairement indisponible. Veuillez réessayer plus tard.';
    }
  }

  // Nouvelle méthode pour analyser le contexte de la conversation
  Future<Map<String, dynamic>> analyzeConversationContext({
    required String texteRecu,
    required String texteEnvoye,
  }) async {
    final analysisPrompt = '''
Tu es Smooth AI, expert en analyse de dynamiques de séduction sur les réseaux sociaux.

Analyse cette conversation entre A (charmeur) et B (fille) et retourne UNIQUEMENT un JSON :

{
  "niveauInteretB": 0-100,
  "phaseConversation": "premiers_echanges|flirt|escalade|planification_rdv|ghosting",
  "signauxPositifs": ["liste des signaux positifs"],
  "signauxNegatifs": ["liste des signaux négatifs"],
  "niveauAudaceAutorise": "faible|moyen|eleve",
  "suggestionAction": "continuer_flirt|proposer_rdv|escalader|changer_sujet|laisser_tomber",
  "tonRecommandé": "mystérieux|direct|taquin|provocateur|sincere"
}

Messages reçus (B) : "$texteRecu"
Messages envoyés (A) : "$texteEnvoye"

Retourne uniquement le JSON, sans explication.
''';

    try {
      final response = await _sendRequest(
        messages: [
          {'role': 'system', 'content': 'Tu es un expert en analyse de conversations de séduction. Retourne uniquement du JSON.'},
          {'role': 'user', 'content': analysisPrompt},
        ],
        model: OpenAIConfig.advancedModel,
        temperature: 0.3,
        maxTokens: 300,
      );

      // Parser le JSON de la réponse
      final jsonStart = response.content.indexOf('{');
      final jsonEnd = response.content.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = response.content.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      
      // Fallback si parsing échoue
      return {
        "niveauInteretB": 50,
        "phaseConversation": "premiers_echanges",
        "signauxPositifs": [],
        "signauxNegatifs": [],
        "niveauAudaceAutorise": "moyen",
        "suggestionAction": "continuer_flirt",
        "tonRecommandé": "mystérieux"
      };
    } catch (e) {
      _logger.warning('Erreur lors de l\'analyse contextuelle: $e');
      return {
        "niveauInteretB": 50,
        "phaseConversation": "premiers_echanges",
        "signauxPositifs": [],
        "signauxNegatifs": [],
        "niveauAudaceAutorise": "moyen",
        "suggestionAction": "continuer_flirt",
        "tonRecommandé": "mystérieux"
      };
    }
  }

  Future<String> analyzeConversation({
  required String texteRecu,
  required String texteEnvoye,
  required String typeReponse, // 'smooth', 'sincere', 'sexy', 'drole', 'intelligent'
  double temperature = 0.7,
}) async {
  // D'abord analyser le contexte
  final context = await analyzeConversationContext(
    texteRecu: texteRecu,
    texteEnvoye: texteEnvoye,
  );

  final prompt = '''
Tu es Smooth AI, expert en séduction et charme masculin sur les réseaux sociaux (Instagram, Snapchat, etc.).

CONTEXTE : Tu es le charmeur (A) qui répond aux stories d'une fille (B). Tu dois être direct, charismatique et créer de l'attraction.

ANALYSE DE LA CONVERSATION :
Messages reçus (B) : "$texteRecu"
Messages envoyés (A) : "$texteEnvoye"

ANALYSE CONTEXTUELLE :
- Niveau d'intérêt de B : ${context['niveauInteretB']}/100
- Phase de conversation : ${context['phaseConversation']}
- Niveau d'audace autorisé : ${context['niveauAudaceAutorise']}
- Action suggérée : ${context['suggestionAction']}
- Ton recommandé : ${context['tonRecommandé']}

TON RÔLE : Tu es le bad boy charmeur qui :
- Ose être direct et audacieux
- Crée de la tension sexuelle subtile
- Montre de la confiance et du charisme
- Propose des actions concrètes (rencontre, appel, etc.)
- Reste mystérieux et intriguant

STYLE DEMANDÉ : $typeReponse
- smooth : charmeur, mystérieux, subtilement séduisant (ex: "Tu ne sais pas encore tout ce que tu es capable de provoquer...")
- sincère : authentique, vulnérable mais confiant (ex: "Pour toi je peux faire tous les efforts possibles")
- sexy : audacieux, provocateur, créateur de tension (ex: "Si tu savais ce que j'imagine à côté de cette piscine...")
- drole : amusant, taquin, léger (ex: "C'est marqué invitation !?")
- intelligent : spirituel, cultivé, engageant (ex: "La tempête commence toujours calmement")

RÈGLES STRICTES :
✅ MAXIMUM 2 PHRASES
✅ Sois direct et charismatique
✅ Propose une action concrète (rencontre, appel, etc.)
✅ Crée de l'attraction et de la curiosité
✅ Adapte ton audace au niveau d'intérêt de B (${context['niveauInteretB']}/100)
✅ Utilise le "tu" et sois personnel

EXEMPLES DE TON STYLE :
- "T'as pas un 06 sur le côté. Je m'occupe du reste"
- "Si tu savais ce que j'imagine à côté de cette piscine..."
- "Je me tiens bien jusqu'à ce que tu me dises de ne plus le faire"
- "Ramène toi mais t'as intérêt à être plus charmant en vrai"

GÉNÈRE : Une réponse de 2 phrases maximum qui suit ton style de charmeur et propose une action concrète.
''';

  final messages = [
    {'role': 'system', 'content': 'Tu es Smooth AI, expert en séduction masculine et charme sur les réseaux sociaux. Tu es direct, audacieux et charismatique.'},
    {'role': 'user', 'content': prompt},
  ];

  final response = await _sendRequest(
    messages: messages,
    model: OpenAIConfig.defaultModel,
    temperature: temperature,
    maxTokens: 150, // Limiter pour 2 phrases max
  );

  return response.content;
}

  // Nettoyage des ressources
  void dispose() {
    _client.close();
  }
}
