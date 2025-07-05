# Service OpenAI Amélioré

## Fonctionnalités Ajoutées

### 1. Gestion du Cache
- Mise en cache des réponses pour des requêtes identiques
- Durée de vie configurable du cache (5 minutes par défaut)
- Nettoyage automatique du cache

### 2. Rate Limiting
- Limite de 10 requêtes par minute par défaut
- Messages d'erreur clairs avec délai de réessai
- Prévention du spam de l'API

### 3. Gestion des Erreurs Améliorée
- Exceptions personnalisées
- Messages d'erreur détaillés
- Gestion des timeouts
- Logging complet

### 4. Configuration Centralisée
- Tous les paramètres dans `OpenAIConfig`
- Modèles, températures et tokens configurables
- Facilement extensible

### 5. Sécurité Renforcée
- Validation des entrées
- Gestion sécurisée des clés API
- Protection contre les injections

## Utilisation

```dart
// Initialisation
final openAIService = OpenAIService(
  apiKey: 'votre_cle_api', // Optionnel, utilise la clé par défaut si non fournie
);

try {
  // Obtenir une réponse de chat
  final response = await openAIService.getChatResponse(
    'Bonjour, comment vas-tu ?',
    chatHistory,
  );
  
  // Analyser une conversation
  final analysis = await openAIService.analyzeChat(conversationText);
  
} on RateLimitExceededException catch (e) {
  // Gérer la limite de débit
  print('Réessayez dans ${e.retryAfter.inSeconds} secondes');
} on OpenAIServiceError catch (e) {
  // Gérer les autres erreurs
  print('Erreur: ${e.message}');
}

// Nettoyer les ressources
openAIService.dispose();
```

## Configuration

Modifiez `lib/config/openai_config.dart` pour ajuster :
- Modèles par défaut
- Limites de tokens
- Durée du cache
- Taux de requêtes

## Bonnes Pratiques

1. Toujours appeler `dispose()` quand le service n'est plus nécessaire
2. Gérer les exceptions spécifiques
3. Utiliser le cache pour les requêtes répétitives
4. Surveiller les logs pour détecter les problèmes
5. Adapter les limites selon vos besoins
