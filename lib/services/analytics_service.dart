import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Événements de navigation
  static const String _eventScreenView = 'screen_view';
  static const String _eventButtonClick = 'button_click';
  static const String _eventFeatureUsage = 'feature_usage';
  static const String _eventError = 'error';
  static const String _eventPurchase = 'purchase';
  static const String _eventShare = 'share';

  /// Initialise le service d'analytics
  static Future<void> initialize() async {
    try {
      // TODO: Initialiser Firebase Analytics, Mixpanel, ou autre service
      debugPrint('Analytics service initialized');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
    }
  }

  /// Enregistre une vue d'écran
  static void logScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventScreenView, eventData);
      debugPrint('Screen view logged: $screenName');
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Enregistre un clic sur un bouton
  static void logButtonClick(String buttonName, {String? screenName, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'button_name': buttonName,
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventButtonClick, eventData);
      debugPrint('Button click logged: $buttonName');
    } catch (e) {
      debugPrint('Failed to log button click: $e');
    }
  }

  /// Enregistre l'utilisation d'une fonctionnalité
  static void logFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'feature_name': featureName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventFeatureUsage, eventData);
      debugPrint('Feature usage logged: $featureName');
    } catch (e) {
      debugPrint('Failed to log feature usage: $e');
    }
  }

  /// Enregistre une erreur
  static void logError(String errorType, String errorMessage, {String? screenName, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventError, eventData);
      debugPrint('Error logged: $errorType - $errorMessage');
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Enregistre un achat
  static void logPurchase(String productId, double amount, {String? currency, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'product_id': productId,
        'amount': amount,
        'currency': currency ?? 'EUR',
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventPurchase, eventData);
      debugPrint('Purchase logged: $productId - $amount $currency');
    } catch (e) {
      debugPrint('Failed to log purchase: $e');
    }
  }

  /// Enregistre un partage
  static void logShare(String shareType, {String? content, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'share_type': shareType,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(_eventShare, eventData);
      debugPrint('Share logged: $shareType');
    } catch (e) {
      debugPrint('Failed to log share: $e');
    }
  }

  /// Enregistre l'utilisation des phrases d'accroche
  static void logPickupLineUsage(String category, int intensity, {String? context}) {
    try {
      final eventData = {
        'category': category,
        'intensity': intensity,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _logEvent('pickup_line_used', eventData);
      debugPrint('Pickup line usage logged: $category (intensity: $intensity)');
    } catch (e) {
      debugPrint('Failed to log pickup line usage: $e');
    }
  }

  /// Enregistre l'analyse de conversation
  static void logChatAnalysis(String analysisType, {int? messageCount, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'analysis_type': analysisType,
        'message_count': messageCount,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent('chat_analysis', eventData);
      debugPrint('Chat analysis logged: $analysisType');
    } catch (e) {
      debugPrint('Failed to log chat analysis: $e');
    }
  }

  /// Enregistre l'utilisation du coaching
  static void logCoachingUsage(String coachingType, {Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'coaching_type': coachingType,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent('coaching_used', eventData);
      debugPrint('Coaching usage logged: $coachingType');
    } catch (e) {
      debugPrint('Failed to log coaching usage: $e');
    }
  }

  /// Enregistre les performances de l'application
  static void logPerformance(String metric, double value, {String? unit, Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'metric': metric,
        'value': value,
        'unit': unit,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent('performance', eventData);
      debugPrint('Performance logged: $metric = $value $unit');
    } catch (e) {
      debugPrint('Failed to log performance: $e');
    }
  }

  /// Enregistre les préférences utilisateur
  static void logUserPreference(String preference, dynamic value) {
    try {
      final eventData = {
        'preference': preference,
        'value': value.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _logEvent('user_preference', eventData);
      debugPrint('User preference logged: $preference = $value');
    } catch (e) {
      debugPrint('Failed to log user preference: $e');
    }
  }

  /// Enregistre un événement personnalisé
  static void logCustomEvent(String eventName, {Map<String, dynamic>? parameters}) {
    try {
      final eventData = {
        'event_name': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      };
      
      _logEvent(eventName, eventData);
      debugPrint('Custom event logged: $eventName');
    } catch (e) {
      debugPrint('Failed to log custom event: $e');
    }
  }

  /// Méthode privée pour envoyer l'événement
  static void _logEvent(String eventName, Map<String, dynamic> eventData) {
    // TODO: Implémenter l'envoi vers le service d'analytics choisi
    // Exemples: Firebase Analytics, Mixpanel, Amplitude, etc.
    
    if (kDebugMode) {
      print('=== ANALYTICS EVENT ===');
      print('Event: $eventName');
      print('Data: $eventData');
      print('======================');
    }
    
    // En mode production, envoyer vers le service d'analytics
    _sendToAnalyticsService(eventName, eventData);
  }

  /// Envoie l'événement vers le service d'analytics
  static void _sendToAnalyticsService(String eventName, Map<String, dynamic> eventData) {
    // TODO: Implémenter l'envoi vers le service d'analytics
    // Exemple avec Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: eventData);
    
    // Exemple avec Mixpanel:
    // Mixpanel.track(eventName, properties: eventData);
    
    // Pour l'instant, on stocke localement pour debug
    _storeEventLocally(eventName, eventData);
  }

  /// Stocke l'événement localement pour debug
  static void _storeEventLocally(String eventName, Map<String, dynamic> eventData) {
    // TODO: Implémenter le stockage local des événements
    // Utile pour debug et pour envoyer en batch plus tard
  }

  /// Définit les propriétés utilisateur
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      // TODO: Implémenter la définition des propriétés utilisateur
      debugPrint('User properties set: $properties');
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Définit l'ID utilisateur
  static Future<void> setUserId(String userId) async {
    try {
      // TODO: Implémenter la définition de l'ID utilisateur
      debugPrint('User ID set: $userId');
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  /// Obtient les statistiques d'utilisation
  static Future<Map<String, dynamic>> getUsageStats() async {
    try {
      // TODO: Implémenter la récupération des statistiques
      return {
        'total_sessions': 0,
        'total_events': 0,
        'last_session': null,
        'most_used_feature': null,
      };
    } catch (e) {
      debugPrint('Failed to get usage stats: $e');
      return {};
    }
  }
}