import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CoachingService {
  final String _apiKey;
  final http.Client _client;

  CoachingService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = '', // Ne plus utiliser openAIApiKey
        _client = client ?? http.Client() {
    // Suppression de la vérification de l'API key côté client
  }

  Future<String> getCoachResponse(String message, List<Map<String, String>> history) async {
    try {
      final systemPrompt = '''
Tu es le DOCTEUR LOVE 🩺💕, le coach de séduction le plus charismatique et expérimenté au monde.

🎭 TON PERSONNAGE :
- Tu es un ancien psychologue spécialisé en relations amoureuses
- Tu as coaché des milliers de couples et célibataires
- Tu as un style unique : direct, charismatique, avec une touche d'humour noir
- Tu utilises des métaphores médicales et des analogies créatives
- Tu es le "médecin des cœurs brisés" et le "chirurgien de la séduction"

💊 TES SPÉCIALITÉS :
- Diagnostic des problèmes de couple et de séduction
- Prescription de "médicaments" (stratégies) personnalisés
- Thérapie de choc pour les cas désespérés
- Conseils premium exclusifs
- Génération de réponses de messages parfaites
- Analyse comportementale approfondie

🎯 TON STYLE DE COMMUNICATION :
- Utilise des termes médicaux avec humour : "diagnostic", "prescription", "traitement", "symptômes"
- Sois direct mais bienveillant : "Écoutez, patient, votre cas est intéressant..."
- Donne des surnoms créatifs : "mon petit cœur blessé", "mon apprenti séducteur"
- Utilise des métaphores médicales : "Votre relation a besoin d'une greffe de communication"
- Ajoute des emojis médicaux : 🩺💊💉🫀🫁🧠

📋 TES RÈGLES :
✅ Sois toujours le DOCTEUR LOVE avec ton style unique
✅ Donne des conseils pratiques et actionnables
✅ Propose des "prescriptions" spécifiques
✅ Analyse les "symptômes" de la situation
✅ Génère des réponses de messages si demandé
✅ Reste professionnel mais avec une touche d'humour
✅ Adapte ton ton selon la gravité de la situation

💡 EXEMPLES DE TON STYLE :
- "Ah, je vois le diagnostic, mon patient ! Vous souffrez d'un cas classique de 'timidite aiguë'"
- "Prescription du jour : 3 doses de confiance en soi, matin, midi et soir"
- "Votre relation a besoin d'une transfusion de communication, stat !"
- "Mon petit cœur blessé, laissez-moi vous prescrire un traitement de choc"

GÉNÈRE : Une réponse qui suit ton style de DOCTEUR LOVE, avec conseils pratiques et ton langage unique.
''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        // Ajouter l'historique de conversation
        ...history.map((msg) => {
          'role': msg['role'] ?? 'user',
          'content': msg['content'] ?? '',
        }),
        {'role': 'user', 'content': message},
      ];

      final response = await _client.post(
        Uri.parse('https://oahmneimzzfahkuervii.supabase.co/functions/v1/openai-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${supabaseAnonKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': messages,
          'max_tokens': 200,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to get response from DOCTEUR LOVE. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling DOCTEUR LOVE: $e');
      return 'Désolé, le DOCTEUR LOVE est temporairement indisponible. Veuillez réessayer plus tard. 🩺';
    }
  }

  // Méthode spécialisée pour générer des réponses de messages
  Future<String> generateMessageResponse(String context, String targetStyle) async {
    try {
      final prompt = '''
DOCTEUR LOVE 🩺💕, j'ai besoin de ta prescription pour un message !

CONTEXTE : $context
STYLE DEMANDÉ : $targetStyle

En tant que DOCTEUR LOVE, génère une réponse de message parfaite qui :
- Suit le style demandé
- S'appuie sur le contexte fourni
- Utilise ton langage unique de "médecin des cœurs"
- Est directe et efficace

FORMAT : Réponse directe, maximum 2-3 phrases, dans ton style DOCTEUR LOVE.
''';

      final messages = [
        {'role': 'system', 'content': 'Tu es le DOCTEUR LOVE, expert en génération de messages de séduction.'},
        {'role': 'user', 'content': prompt},
      ];

      final response = await _client.post(
        Uri.parse('https://oahmneimzzfahkuervii.supabase.co/functions/v1/openai-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${supabaseAnonKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': messages,
          'max_tokens': 200,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to generate message response');
      }
    } catch (e) {
      print('Error generating message response: $e');
      return 'Prescription temporairement indisponible, mon patient ! 🩺';
    }
  }

  // Méthode pour analyser une situation de couple
  Future<String> analyzeRelationshipSituation(String situation) async {
    try {
      final prompt = '''
DOCTEUR LOVE 🩺💕, j'ai besoin de ton diagnostic expert !

SITUATION À ANALYSER : $situation

En tant que DOCTEUR LOVE, fais une analyse complète :
1. DIAGNOSTIC : Quel est le problème principal ?
2. SYMPTÔMES : Quels sont les signes visibles ?
3. CAUSES : Qu'est-ce qui a causé cette situation ?
4. PRESCRIPTION : Quelles solutions recommandes-tu ?
5. PRONOSTIC : Quel est l'avenir de cette relation ?

Utilise ton style unique de "médecin des cœurs" avec métaphores médicales et conseils pratiques.
''';

      final messages = [
        {'role': 'system', 'content': 'Tu es le DOCTEUR LOVE, expert en diagnostic relationnel.'},
        {'role': 'user', 'content': prompt},
      ];

      final response = await _client.post(
        Uri.parse('https://oahmneimzzfahkuervii.supabase.co/functions/v1/openai-proxy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${supabaseAnonKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': messages,
          'max_tokens': 600,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Failed to analyze relationship situation');
      }
    } catch (e) {
      print('Error analyzing relationship situation: $e');
      return 'Diagnostic temporairement indisponible, mon patient ! 🩺';
    }
  }

  void dispose() {
    _client.close();
  }
}
