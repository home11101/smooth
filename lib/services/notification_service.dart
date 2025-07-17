import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'sound_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // IDs des notifications
  static const int _subscriptionExpiryId = 2;
  static const int _renewalReminderId = 3;
  static const int _welcomeNotificationId = 4;
  static const int _featureReminderId = 5;

  // Clés pour les préférences
  static const String _notificationSettingsKey = 'notification_settings';

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (!_isInitialized) {
      tzdata.initializeTimeZones();
      _isInitialized = true;
    }
    if (_isInitialized) return;

    // Configuration pour Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration pour iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Configuration générale
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser le plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('Service de notifications initialisé');
  }

  /// Configure les notifications de renouvellement
  Future<void> setupRenewalNotifications(DateTime expiryDate) async {
    if (!_isInitialized) await initialize();

    // Annuler les anciennes notifications
    await cancelRenewalNotifications();

    // Notification 3 jours avant expiration
    final threeDaysBefore = expiryDate.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _renewalReminderId,
        title: 'Votre abonnement expire bientôt',
        body: 'Renouvelez votre abonnement Smooth AI pour continuer à profiter de toutes les fonctionnalités premium.',
        scheduledDate: threeDaysBefore,
        payload: 'renewal_reminder',
      );
    }

    // Notification 1 jour avant expiration
    final oneDayBefore = expiryDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _renewalReminderId + 1,
        title: 'Dernière chance de renouveler',
        body: 'Votre abonnement Smooth AI expire demain. Renouvelez maintenant pour éviter toute interruption.',
        scheduledDate: oneDayBefore,
        payload: 'renewal_urgent',
      );
    }

    // Notification le jour de l'expiration
    if (expiryDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _subscriptionExpiryId,
        title: 'Votre abonnement a expiré',
        body: 'Renouvelez votre abonnement Smooth AI pour retrouver l\'accès à toutes les fonctionnalités premium.',
        scheduledDate: expiryDate,
        payload: 'subscription_expired',
      );
    }
  }

  /// Notification de bienvenue pour les nouveaux utilisateurs
  Future<void> sendWelcomeNotification() async {
    if (!_isInitialized) await initialize();

    await _showNotification(
      id: _welcomeNotificationId,
      title: 'Bienvenue sur Smooth AI !',
      body: 'Découvrez toutes les fonctionnalités premium disponibles pendant votre essai gratuit de 3 jours.',
      payload: 'welcome',
    );
  }

  /// Notification de rappel de fonctionnalités
  Future<void> sendFeatureReminderNotification(String featureName, String description) async {
    if (!_isInitialized) await initialize();

    await _showNotification(
      id: _featureReminderId,
      title: 'Nouvelle fonctionnalité disponible',
      body: 'Découvrez $featureName : $description',
      payload: 'feature_reminder',
    );
  }

  /// Annule toutes les notifications de renouvellement
  Future<void> cancelRenewalNotifications() async {
    if (!_isInitialized) await initialize();

    await _notifications.cancel(_renewalReminderId);
    await _notifications.cancel(_renewalReminderId + 1);
    await _notifications.cancel(_subscriptionExpiryId);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    await _notifications.cancelAll();
  }

  /// Programme une notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Convertir DateTime en TZDateTime
    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'renewal_channel',
      'Renouvellements',
      channelDescription: 'Notifications de renouvellement d\'abonnement',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    debugPrint('Notification programmée pour le ${scheduledDate.toString()}');
  }

  /// Affiche une notification immédiate
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel',
      'Général',
      channelDescription: 'Notifications générales',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);

    // Jouer le son de notification si disponible
    try {
      await SoundService.playNotification();
    } catch (e) {
      print('Erreur lors de la lecture du son de notification: $e');
    }
  }

  /// Gère le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapée: ${response.payload}');
    
    // Ici vous pouvez ajouter la logique pour naviguer vers l'écran approprié
    switch (response.payload) {
      case 'renewal_reminder':
      case 'renewal_urgent':
      case 'subscription_expired':
        // Naviguer vers l'écran premium
        break;
      case 'welcome':
        // Naviguer vers l'écran d'accueil
        break;
      case 'feature_reminder':
        // Naviguer vers la fonctionnalité
        break;
    }
  }

  /// Vérifie et met à jour les notifications selon le statut premium
  Future<void> updateNotificationsBasedOnStatus(bool isPremium, DateTime? expiryDate) async {
    if (!_isInitialized) await initialize();
    if (isPremium && expiryDate != null) {
      await setupRenewalNotifications(expiryDate);
    } else {
      await cancelAllNotifications();
    }
  }

  /// Sauvegarde les paramètres de notifications
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = settings.map((key, value) => MapEntry(key, value.toString()));
    await prefs.setString(_notificationSettingsKey, settingsJson.toString());
  }

  /// Charge les paramètres de notifications
  Future<Map<String, bool>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsStr = prefs.getString(_notificationSettingsKey);
    
    if (settingsStr != null) {
      // Parse simple des paramètres
      final settings = <String, bool>{};
      // Ici vous pouvez implémenter le parsing selon votre format
      return settings;
    }
    
    // Paramètres par défaut
    return {
      'renewal_reminders': true,
      'trial_reminders': true,
      'feature_updates': true,
      'welcome_notifications': true,
    };
  }

  /// Vérifie les permissions de notifications
  Future<bool> checkNotificationPermissions() async {
    if (!_isInitialized) await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // Pour iOS, les permissions sont gérées différemment
  }

  /// Nettoie les ressources
  void dispose() {
    // Le plugin se nettoie automatiquement
  }
}
