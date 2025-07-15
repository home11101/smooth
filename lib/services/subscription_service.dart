import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'notification_service.dart';

class SubscriptionService {
  static const String _trialStartKey = 'trial_start_date';
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _purchaseDateKey = 'purchase_date';
  static const String _expiryDateKey = 'expiry_date';
  static const String _isPremiumKey = 'is_premium';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  
  static const String _premiumProductId = 'smooth_ai_premium_monthly';
  static const String _premiumYearlyProductId = 'smooth_ai_premium_yearly';
  
  static const int trialDurationDays = 3;
  
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Service de notifications
  final NotificationService _notificationService = NotificationService();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Initialiser le service de notifications
    await _notificationService.initialize();
    
    // Si c'est la première fois, démarrer la période d'essai
    if (!_prefs.containsKey(_trialStartKey)) {
      await _startTrial();
    }
    
    _isInitialized = true;

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Erreur de stream d\'achat: $error'),
    );
    
    // Configurer les notifications selon le statut actuel
    await _updateNotificationsBasedOnCurrentStatus();
  }

  /// Démarre la période d'essai de 3 jours
  Future<void> _startTrial() async {
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: trialDurationDays));
    
    await _prefs.setString(_trialStartKey, now.toIso8601String());
    await _prefs.setBool(_isPremiumKey, true);
    await _prefs.setString(_subscriptionExpiryKey, trialEndDate.toIso8601String());
    
    // Configurer les notifications d'essai
    await _notificationService.setupTrialNotifications(trialEndDate);
    
    // Envoyer une notification de bienvenue
    await _notificationService.sendWelcomeNotification();
  }

  /// Vérifie si l'utilisateur a un accès premium (essai ou abonnement)
  Future<bool> isPremium() async {
    if (!_isInitialized) await initialize();
    
    final subscriptionStatus = _prefs.getString(_subscriptionStatusKey);
    
    if (subscriptionStatus == 'active') {
      final expiryDateStr = _prefs.getString(_expiryDateKey);
      if (expiryDateStr != null) {
        final expiryDate = DateTime.parse(expiryDateStr);
        if (DateTime.now().isBefore(expiryDate)) {
          return true;
        } else {
          // Abonnement expiré
          await _prefs.setString(_subscriptionStatusKey, 'expired');
          return false;
        }
      }
    }
    
    // Vérifier l'essai gratuit
    return await isInTrial();
  }

  /// Vérifie si l'utilisateur est en période d'essai
  Future<bool> isInTrial() async {
    if (!_isInitialized) await initialize();
    
    final trialStartStr = _prefs.getString(_trialStartKey);
    if (trialStartStr == null) {
      // Premier lancement, démarrer l'essai
      await _prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
      return true;
    }
    
    final trialStart = DateTime.parse(trialStartStr);
    final trialEnd = trialStart.add(const Duration(days: trialDurationDays));
    
    return DateTime.now().isBefore(trialEnd);
  }

  /// Obtient le nombre de jours restants dans l'essai
  Future<int> getTrialDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartStr = prefs.getString(_trialStartKey);
    
    if (trialStartStr == null) {
      return trialDurationDays;
    }
    
    final trialStart = DateTime.parse(trialStartStr);
    final trialEnd = trialStart.add(const Duration(days: trialDurationDays));
    final now = DateTime.now();
    
    if (now.isAfter(trialEnd)) {
      return 0;
    }
    
    return trialEnd.difference(now).inDays;
  }

  /// Obtient la date d'expiration de l'abonnement
  Future<DateTime?> getSubscriptionExpiry() async {
    if (!_isInitialized) await initialize();
    
    final expiryDate = _prefs.getString(_subscriptionExpiryKey);
    if (expiryDate == null) return null;
    
    return DateTime.parse(expiryDate);
  }

  /// Active l'abonnement premium
  Future<void> activatePremium(DateTime expiryDate) async {
    if (!_isInitialized) await initialize();
    
    await _prefs.setBool(_isPremiumKey, true);
    await _prefs.setString(_subscriptionExpiryKey, expiryDate.toIso8601String());
    
    // Configurer les notifications de renouvellement
    await _notificationService.setupRenewalNotifications(expiryDate);
    
    // Annuler les notifications d'essai
    await _notificationService.cancelTrialNotifications();
  }

  /// Désactive l'abonnement premium
  Future<void> deactivatePremium() async {
    if (!_isInitialized) await initialize();
    
    await _prefs.setBool(_isPremiumKey, false);
    
    // Annuler toutes les notifications de renouvellement
    await _notificationService.cancelRenewalNotifications();
  }

  /// Vérifie si une fonctionnalité est disponible
  Future<bool> isFeatureAvailable(String feature) async {
    // La fonction "Saisir le texte" est toujours disponible
    if (feature == 'text_input') return true;
    
    // Toutes les autres fonctionnalités nécessitent un abonnement premium
    return await isPremium();
  }

  /// Obtient les produits d'abonnement disponibles
  Future<List<ProductDetails>> getAvailableProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('Store non disponible');
      return [];
    }

    const Set<String> kIds = <String>{
      _premiumProductId,
      _premiumYearlyProductId,
    };

    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Produits non trouvés: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      print('Erreur lors de la récupération des produits: ${response.error}');
      return [];
    }

    return response.productDetails;
  }

  /// Achète un produit
  Future<bool> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      if (product.id.contains('monthly') || product.id.contains('yearly')) {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      return false;
    }
  }

  /// Restaure les achats
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('Erreur lors de la restauration: $e');
      return false;
    }
  }

  /// Écoute les mises à jour d'achat
  Stream<List<PurchaseDetails>> get purchaseUpdates => _inAppPurchase.purchaseStream;

  /// Traite un achat
  Future<void> handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      // Achat en attente
      print('Achat en attente: ${purchaseDetails.productID}');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Erreur d'achat
      print('Erreur d\'achat: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
      // Achat réussi ou restauré
      await _processSuccessfulPurchase(purchaseDetails);
    }

    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Traite un achat réussi
  Future<void> _processSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    DateTime expiryDate;
    
    // Calculer la date d'expiration selon le type d'abonnement
    if (purchaseDetails.productID.contains('yearly')) {
      expiryDate = DateTime.now().add(const Duration(days: 365));
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }
    
    await activatePremium(expiryDate);
    print('Abonnement activé jusqu\'au: $expiryDate');
  }

  /// Obtient le statut de l'abonnement en format texte
  Future<String> getSubscriptionStatusText() async {
    if (await isPremium()) {
      if (await isInTrial()) {
        final daysLeft = await getTrialDaysRemaining();
        return 'Essai gratuit - $daysLeft jours restants';
      } else {
        final expiry = await getSubscriptionExpiry();
        if (expiry != null) {
          return 'Premium - Expire le ${expiry.day}/${expiry.month}/${expiry.year}';
        }
        return 'Premium actif';
      }
    } else {
      return 'Essai expiré - Abonnement requis';
    }
  }

  /// Vérifie si l'utilisateur peut accéder à une fonctionnalité spécifique
  Future<bool> canAccessFeature(String feature) async {
    return await isFeatureAvailable(feature);
  }

  /// Obtient le message d'erreur pour une fonctionnalité verrouillée
  String getLockedFeatureMessage(String feature) {
    switch (feature) {
      case 'pickup_lines':
        return 'Générateur de phrases d\'accroche verrouillé';
      case 'chat_analysis':
        return 'Analyse de conversations verrouillée';
      case 'screenshot_analysis':
        return 'Analyse de captures d\'écran verrouillée';
      case 'coaching':
        return 'Coaching personnalisé verrouillé';
      case 'premium_features':
        return 'Fonctionnalités premium verrouillées';
      default:
        return 'Fonctionnalité verrouillée';
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Achat en attente...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Erreur d\'achat: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Enregistrer la date d'achat
    await prefs.setString(_purchaseDateKey, DateTime.now().toIso8601String());
    
    // Calculer la date d'expiration
    final now = DateTime.now();
    final expiryDate = purchaseDetails.productID.contains('yearly') 
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));
    
    await prefs.setString(_expiryDateKey, expiryDate.toIso8601String());
    await prefs.setString(_subscriptionStatusKey, 'active');
    
    print('Achat traité avec succès: ${purchaseDetails.productID}');
  }

  /// Met à jour les notifications selon le statut actuel
  Future<void> _updateNotificationsBasedOnCurrentStatus() async {
    final isPremium = await this.isPremium();
    final expiryDate = await getSubscriptionExpiry();
    
    await _notificationService.updateNotificationsBasedOnStatus(isPremium, expiryDate);
  }

  /// Envoie une notification de rappel de fonctionnalité
  Future<void> sendFeatureReminderNotification(String featureName, String description) async {
    await _notificationService.sendFeatureReminderNotification(featureName, description);
  }

  /// Vérifie les permissions de notifications
  Future<bool> checkNotificationPermissions() async {
    return await _notificationService.checkNotificationPermissions();
  }

  /// Sauvegarde les paramètres de notifications
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    await _notificationService.saveNotificationSettings(settings);
  }

  /// Charge les paramètres de notifications
  Future<Map<String, bool>> loadNotificationSettings() async {
    return await _notificationService.loadNotificationSettings();
  }

  /// Prolonge la période d'essai gratuite de [days] jours supplémentaires
  Future<void> extendTrial(int days) async {
    if (!_isInitialized) await initialize();

    final trialStartStr = _prefs.getString(_trialStartKey);
    DateTime trialStart;
    if (trialStartStr == null) {
      // Si pas d'essai, on démarre maintenant
      trialStart = DateTime.now();
      await _prefs.setString(_trialStartKey, trialStart.toIso8601String());
    } else {
      trialStart = DateTime.parse(trialStartStr);
    }

    // Calculer la date de fin d'essai actuelle
    final currentTrialEnd = trialStart.add(const Duration(days: trialDurationDays));
    final now = DateTime.now();
    DateTime newTrialEnd;
    if (now.isAfter(currentTrialEnd)) {
      // Si l'essai est déjà expiré, on repart de maintenant
      newTrialEnd = now.add(Duration(days: days));
      await _prefs.setString(_trialStartKey, now.toIso8601String());
    } else {
      // Sinon, on prolonge la date de fin d'essai actuelle
      newTrialEnd = currentTrialEnd.add(Duration(days: days));
    }
    await _prefs.setString(_subscriptionExpiryKey, newTrialEnd.toIso8601String());
    await _prefs.setBool(_isPremiumKey, true); // L'utilisateur reste premium pendant l'essai

    // Configurer les notifications d'essai
    await _notificationService.setupTrialNotifications(newTrialEnd);
  }

  void dispose() {
    _subscription.cancel();
  }
} 