import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'openai_service.dart';

/// Configuration pour le service de génération de réponses
class SmoothReplyConfig {
  final int defaultMaxTokens;
  final bool enableCache;
  final int cacheSize;
  final Duration timeout;
  final String systemPrompt;

  const SmoothReplyConfig({
    this.defaultMaxTokens = 100,
    this.enableCache = true,
    this.cacheSize = 100,
    this.timeout = const Duration(seconds: 30),
    this.systemPrompt =
        "Tu es un Smooth AI un expert en communication interpersonnelle et en séduction. "
            "Ton rôle est d'aider à créer des réponses impactantesauthentiques, respectueuses et adaptées.",
  });
}

/// Clé de cache pour stocker les réponses
class _CacheKey {
  final String receivedMessage;
  final String? userReply;
  final String? context;
  final int? intensity;

  _CacheKey({
    required this.receivedMessage,
    this.userReply,
    this.context,
    this.intensity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          receivedMessage == other.receivedMessage &&
          userReply == other.userReply &&
          context == other.context &&
          intensity == other.intensity;

  @override
  int get hashCode =>
      Object.hash(receivedMessage, userReply, context, intensity);
}

/// Service pour générer des réponses élégantes et adaptées
class SmoothReplyService {
  final OpenAIService _openAIService;
  final SmoothReplyConfig _config;
  final Map<_CacheKey, String> _responseCache = {};
  final List<Function(String event, String details)> _analyticsListeners = [];

  SmoothReplyService(
    this._openAIService, {
    SmoothReplyConfig? config,
  }) : _config = config ?? const SmoothReplyConfig();

  /// Ajoute un écouteur pour les événements d'analyse
  void addAnalyticsListener(Function(String event, String details) listener) {
    _analyticsListeners.add(listener);
  }

  /// Génère une réponse élégante basée sur le message reçu
  Future<String> generateSmoothReply({
    required String receivedMessage,
    String? userReply,
    String? context,
    int? intensity,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? cachedResponse;

    try {
      // Validation des entrées
      if (receivedMessage.trim().isEmpty) {
        throw ArgumentError('Le message reçu ne peut pas être vide');
      }

      if (intensity != null && (intensity < 1 || intensity > 5)) {
        throw ArgumentError('L\'intensité doit être comprise entre 1 et 5');
      }

      // Vérification du cache
      final cacheKey = _CacheKey(
        receivedMessage: receivedMessage,
        userReply: userReply,
        context: context,
        intensity: intensity,
      );

      if (_config.enableCache) {
        cachedResponse = _responseCache[cacheKey];
        if (cachedResponse != null) {
          _logEvent('cache_hit', details: 'key: ${cacheKey.hashCode}');
          return cachedResponse;
        }
      }

      // Construction du prompt
      final prompt = _buildPrompt(
        receivedMessage: receivedMessage,
        userReply: userReply,
        context: context,
        intensity: intensity,
      );

      // Appel au service OpenAI
      final response = await _openAIService
          .getChatResponse(
            prompt,
            <ChatMessage>[],
            maxTokens: _config.defaultMaxTokens,
          )
          .timeout(
            _config.timeout,
            onTimeout: () => throw TimeoutException(
                'La requête a pris plus de ${_config.timeout.inSeconds} secondes'),
          );

      final sanitizedResponse = _sanitizeResponse(response);

      // Mise en cache de la réponse
      if (_config.enableCache) {
        _responseCache[cacheKey] = sanitizedResponse;
        if (_responseCache.length > _config.cacheSize) {
          _responseCache.remove(_responseCache.keys.first);
        }
      }

      _logEvent(
        'reply_generated',
        details: 'length: ${sanitizedResponse.length}',
      );

      return sanitizedResponse;
    } on TimeoutException catch (e) {
      _logEvent('timeout', details: e.toString());
      return "Désolé, la réponse prend plus de temps que prévu. Réessayez.";
    } on SocketException catch (e) {
      _logEvent('network_error', details: e.toString());
      return "Problème de connexion. Vérifiez votre accès internet.";
    } on ArgumentError catch (e) {
      _logEvent('validation_error', details: e.toString());
      rethrow; // L'appelant doit gérer cette erreur
    } catch (e, stackTrace) {
      _logEvent('error', details: '$e\n$stackTrace');
      debugPrint('Erreur dans generateSmoothReply: $e\n$stackTrace');
      return "Désolé, une erreur est survenue lors de la génération de la réponse.";
    } finally {
      stopwatch.stop();
      _logEvent(
        'request_completed',
        details: 'duration_ms: ${stopwatch.elapsedMilliseconds}',
      );
    }
  }

  /// Nettoie la réponse générée
  String _sanitizeResponse(String response) {
    // Supprime les guillemets superflus et les espaces en trop
    return response.trim();
  }

  /// Construit le prompt pour l'API OpenAI
  String _buildPrompt({
    required String receivedMessage,
    String? userReply,
    String? context,
    int? intensity,
  }) {
    final buffer = StringBuffer();

    // Persona premium
    buffer.writeln("Tu es Smooth AI, l'assistant de rencontres le plus premium, hype, fun et empathique. Tu es un expert en psychologie des relations, communication interpersonnelle et séduction moderne. Tu t'adaptes à tous les profils : du plus timide au plus confiant, du plus hype au plus réservé. Tu es toujours respectueux, jamais lourd, jamais générique, et tu sais doser l'humour, la subtilité ou l'audace selon la demande.");

    // Règles et style
    buffer.writeln("\n### RÈGLES STRICTES ###");
    buffer.writeln("- Ne dis jamais que tu es une IA ou un assistant.");
    buffer.writeln("- Ne mets jamais de guillemets autour de la réponse.");
    buffer.writeln("- Ne fais jamais de commentaire, d'analyse ou d'introduction.");
    buffer.writeln("- Ne commence jamais par 'Voici', 'Réponse', 'Bien sûr', etc.");
    buffer.writeln("- Pas de copier-coller, pas de réponses génériques.");
    buffer.writeln("- Maximum 2 phrases, style naturel, conversationnel, original, adapté à un chat de rencontre.");
    buffer.writeln("- Utilise des emojis si pertinent, mais jamais plus de 2 par réponse.");
    buffer.writeln("- Adapte le ton et l'audace à la demande et au contexte.");

    // Contexte d'application
    buffer.writeln("\n### CONTEXTE DE L'APPLICATION ###");
    buffer.writeln("- Application de génération de réponses pour draguer, relancer ou séduire sur une app de rencontre ou réseau social.");
    buffer.writeln("- L'utilisateur souhaite une réponse qui donne envie de continuer la discussion, sans être lourde ni trop générique.");

    // Destinataire/context
    buffer.writeln("\n### DESTINATAIRE ###");
    buffer.writeln(context != null && context.isNotEmpty ? context : "Non précisé");

    // Historique conversationnel
    buffer.writeln("\n### HISTORIQUE DE LA CONVERSATION ###");
    buffer.writeln("Dernier message reçu :\n'$receivedMessage'");
    if (userReply != null && userReply.isNotEmpty) {
      buffer.writeln("\nDerniers messages envoyés :\n'$userReply'");
    }

    // Intensité et style
    final intensityLevels = {
      1: "Très subtil et délicat (intelligent)",
      2: "Légèrement suggestif (drôle)",
      3: "Équilibré entre subtilité et intérêt (smooth)",
      4: "Clairement intéressé(e) (sexy)",
      5: "Direct et passionné (sexy intense)"
    };
    final styleLabels = {
      1: "intelligente",
      2: "drôle",
      3: "smooth",
      4: "sexy",
      5: "sexy"
    };
    final style = intensity != null ? styleLabels[intensity] : "smooth";
    final styleDesc = intensity != null ? intensityLevels[intensity] : "Équilibré entre subtilité et intérêt (smooth)";

    buffer.writeln("\n### STYLE DEMANDÉ ###");
    buffer.writeln("- Style : $style ($styleDesc)");
    buffer.writeln("- Adapte la réponse à ce style, même si l'utilisateur est timide ou hésitant.");

    // Exemples pour chaque style
    buffer.writeln("\n### EXEMPLES DE RÉPONSES PAR STYLE ###");
    buffer.writeln("- smooth : 'Tu ne sais pas encore tout ce que tu es capable de provoquer...'\n- smooth : 'Je te laisse deviner ce que j'ai pensé en lisant ton message.'");
    buffer.writeln("- sexy : 'Si tu savais ce que j'imagine à côté de cette piscine...'\n- sexy : 'T'as pas un 06 sur le côté ? Je m'occupe du reste.'");
    buffer.writeln("- drôle : 'C'est marqué invitation !?'\n- drôle : 'J'espère que tu cuisines mieux que tu ne dragues.'");
    buffer.writeln("- intelligente : 'La tempête commence toujours calmement.'\n- intelligente : 'Je préfère les conversations qui font réfléchir.'");

    // Objectif
    buffer.writeln("\n### OBJECTIF ###");
    buffer.writeln("- Générer une réponse $styleDesc, qui donne envie de répondre, adaptée au contexte, jamais lourde ni générique.");
    buffer.writeln("- Maximum 2 phrases.");

    // Instructions finales
    buffer.writeln("\nRéponds uniquement par le texte à envoyer, sans guillemets, sans commentaire, sans analyse.");

    return buffer.toString();
  }

  /// Journalise un événement
  void _logEvent(String event, {String details = ''}) {
    if (_analyticsListeners.isEmpty) return;

    for (final listener in _analyticsListeners) {
      try {
        listener(event, details);
      } catch (e) {
        debugPrint('Error in analytics listener: $e');
      }
    }
  }

  /// Vide le cache des réponses
  void clearCache() {
    _responseCache.clear();
    _logEvent('cache_cleared');
  }

  /// Statistiques d'utilisation
  Map<String, dynamic> get stats {
    return {
      'cache_size': _responseCache.length,
      'cache_keys':
          _responseCache.keys.map((k) => k.hashCode.toString()).toList(),
    };
  }
}
