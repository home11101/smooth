import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'notification_service.dart';

class SubscriptionService {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _purchaseDateKey = 'purchase_date';
  static const String _expiryDateKey = 'expiry_date';
  static const String _isPremiumKey = 'is_premium';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _premiumProductId = 'smooth_ai_premium_weekly_v2';
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
    
    _isInitialized = true;

    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Erreur de stream d\'achat: $error'),
    );
    
    // Configurer les notifications selon le statut actuel
    await _updateNotificationsBasedOnCurrentStatus();
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
    
    return false;
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

    const Set<String> kIds = <String>{_premiumProductId};

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
      if (product.id.contains('weekly_v2')) {
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
    if (purchaseDetails.productID.contains('weekly_v2')) {
      expiryDate = DateTime.now().add(const Duration(days: 7));
    } else {
      // Achat unique ou inconnu
      expiryDate = DateTime.now().add(const Duration(days: 7));
    }
    
    await activatePremium(expiryDate);
    print('Abonnement activé jusqu\'au: $expiryDate');
  }

  /// Obtient le statut de l'abonnement en format texte
  Future<String> getSubscriptionStatusText() async {
    if (await isPremium()) {
        final expiry = await getSubscriptionExpiry();
        if (expiry != null) {
          return 'Premium - Expire le ${expiry.day}/${expiry.month}/${expiry.year}';
        }
        return 'Premium actif';
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
    final expiryDate = purchaseDetails.productID.contains('weekly_v2') 
        ? now.add(const Duration(days: 7))
        : now.add(const Duration(days: 7));
    
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

  void dispose() {
    _subscription.cancel();
  }
} 