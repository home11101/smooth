import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'premium_provider.dart';
import 'notification_service.dart';

class InAppPurchaseService {
  // IDs des produits
  static const String premiumWeekly = 'smooth_ai_premium_weekly';
  static const String premiumMonthly = 'smooth_ai_premium_monthly';
  static const String premiumYearly = 'smooth_ai_premium_yearly';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // Référence au PremiumProvider, initialisée dans [initialize](cci:1://file:///Users/bv/Desktop/flutter-supabase-app%20%281%29/lib/services/in_app_purchase_service.dart:30:2-51:3)
  late final PremiumProvider premiumProvider;

  // Service de notifications
  final NotificationService _notificationService = NotificationService();

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  double? _lastPurchaseAmount;

  // Singleton
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  /// Initialise le service avec le PremiumProvider.
  /// Doit être appelé une seule fois au démarrage de l'application.
  Future<void> initialize(PremiumProvider provider) async {
    premiumProvider = provider;
    
    // Initialiser le service de notifications
    await _notificationService.initialize();
    
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      premiumProvider.setErrorMessage('Les achats intégrés ne sont pas disponibles sur cet appareil.');
      return;
    }

    // Écoute des mises à jour d'achat
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        debugPrint('Erreur du flux d\'achat: $error');
        premiumProvider.setErrorMessage('Une erreur de connexion est survenue.');
      },
    );

    await loadProducts();
  }

  /// Charge les produits depuis la boutique (App Store / Play Store)
  Future<void> loadProducts() async {
    const Set<String> kIds = <String>{premiumWeekly, premiumMonthly, premiumYearly};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

    if (response.error != null) {
      debugPrint('Erreur de chargement des produits: ${response.error}');
      premiumProvider.setErrorMessage('Erreur lors du chargement des abonnements.');
      _products = [];
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IDs d\'achats intégrés non trouvés: ${response.notFoundIDs}');
      premiumProvider.setErrorMessage(
        'Aucun abonnement n\'a été trouvé. Vérifiez la configuration de vos achats intégrés sur App Store Connect.\nIDs manquants: ${response.notFoundIDs.join(", ")}'
      );
    } else if (response.productDetails.isEmpty) {
      debugPrint('Aucun produit trouvé.');
      premiumProvider.setErrorMessage('Aucun abonnement n\'a été trouvé. Vérifiez la configuration de vos achats intégrés sur App Store Connect.');
    }
    
    _products = response.productDetails;
    // Notifier l'UI que les produits sont chargés (ou non)
    premiumProvider.notifyListeners(); 
  }

  /// Lance le processus d'achat pour un produit
  Future<void> buyProduct(ProductDetails productDetails) async {
    premiumProvider.setProcessing(true);
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      // Stocke le montant réel du produit (en nombre)
      _lastPurchaseAmount = double.tryParse(productDetails.price.replaceAll(RegExp(r'[^0-9.]'), ''));
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Erreur lors du lancement de l\'achat: $e');
      premiumProvider.setErrorMessage('L\'achat n\'a pas pu être initié.');
      premiumProvider.setProcessing(false);
    }
  }

  /// Lance le processus de restauration des achats
  Future<void> restorePurchases() async {
    premiumProvider.setProcessing(true);
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Erreur lors de la restauration: $e');
      premiumProvider.setErrorMessage('La restauration a échoué.');
      premiumProvider.setProcessing(false);
    }
  }

  /// Gère les mises à jour de statut des achats (le cœur de la logique)
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          premiumProvider.setProcessing(true);
          break;
        case PurchaseStatus.error:
          premiumProvider.setErrorMessage(purchaseDetails.error?.message ?? 'Une erreur d\'achat est survenue.');
          premiumProvider.setProcessing(false);
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = await _validateAndGrantPremium(purchaseDetails);
          if (!valid) {
             premiumProvider.setErrorMessage('La validation de votre achat a échoué. Veuillez contacter le support.');
          }
          // Toujours finaliser l'achat, même si la validation échoue, pour le retirer de la file d'attente.
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          premiumProvider.setProcessing(false);
          break;
        case PurchaseStatus.canceled:
           premiumProvider.setProcessing(false);
           if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
      }
    }
  }

  /// Enregistre le paiement dans Supabase
  Future<void> savePaymentToSupabase(PurchaseDetails purchase, double amount) async {
    const supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co/rest/v1/payments';
    const supabaseApiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

    String deviceId = 'unknown_device';
    try {
      
    } catch (_) {}

    // Récupère le user_id Supabase si connecté
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;

    final response = await http.post(
      Uri.parse(supabaseUrl),
      headers: {
        'apikey': supabaseApiKey,
        'Authorization': 'Bearer $supabaseApiKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      },
      body: jsonEncode({
        'user_id': userId,
        'device_id': deviceId,
        'product_id': purchase.productID,
        'amount': amount,
        'currency': 'EUR',
        'platform': Platform.isIOS ? 'ios' : 'android',
        'receipt': purchase.verificationData.serverVerificationData,
        'status': 'validated',
      }),
    );

    if (response.statusCode == 201) {
      debugPrint('✅ Paiement enregistré dans Supabase');
    } else {
      debugPrint('❌ Erreur lors de l\'enregistrement du paiement : ${response.body}');
    }
  }

  /// Valide le reçu via le backend et met à jour le statut premium
  Future<bool> _validateAndGrantPremium(PurchaseDetails purchase) async {
    const String validationUrl = 'https://qlomkoexurbxqsezavdi.supabase.co/functions/v1/validate-receipt';
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;

      final Map<String, dynamic> requestBody = {
        'productId': purchase.productID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'userId': userId, // Ajouté pour le backend
      };

      // Ajouter les paramètres spécifiques à la plateforme
      if (Platform.isIOS) {
        requestBody['receipt'] = purchase.verificationData.serverVerificationData;
      } else {
        // Pour Android, nous avons besoin de plus d'informations
        requestBody['packageName'] = 'com.example.smooth_ai_dating_assistant'; // Remplacer par votre package name
        requestBody['purchaseToken'] = purchase.verificationData.serverVerificationData;
        requestBody['isSubscription'] = purchase.productID.contains('monthly') || purchase.productID.contains('yearly');
      }

      final response = await http.post(
        Uri.parse(validationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isValid'] == true) {
          // Le backend a confirmé la validité
          await premiumProvider.updatePremiumStatus(purchase);
          premiumProvider.setErrorMessage(null); // Succès, on nettoie les erreurs
          
          // Configurer les notifications de renouvellement
          await _setupRenewalNotifications(purchase);
          
          // Enregistrement du paiement dans Supabase avec le vrai montant
          await savePaymentToSupabase(purchase, _lastPurchaseAmount ?? 0.0);
          
          return true;
        }
      }
      // Si le statut n'est pas 200 ou si isValid est false
      return false;
    } catch (e) {
      debugPrint('Erreur de validation réseau: $e');
      premiumProvider.setErrorMessage('Erreur de connexion lors de la validation.');
      return false;
    }
  }

  /// Configure les notifications de renouvellement après un achat réussi
  Future<void> _setupRenewalNotifications(PurchaseDetails purchase) async {
    try {
      DateTime expiryDate;
      // Calculer la date d'expiration selon le type d'abonnement
      if (purchase.productID == premiumYearly) {
        expiryDate = DateTime.now().add(const Duration(days: 365));
      } else if (purchase.productID == premiumMonthly) {
        expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (purchase.productID == premiumWeekly) {
        expiryDate = DateTime.now().add(const Duration(days: 7));
      } else {
        // Achat unique - pas de notifications de renouvellement
        return;
      }
      // Configurer les notifications de renouvellement
      await _notificationService.setupRenewalNotifications(expiryDate);
      debugPrint('Notifications de renouvellement configurées pour le ${expiryDate.toString()}');
    } catch (e) {
      debugPrint('Erreur lors de la configuration des notifications: $e');
    }
  }

  /// Nettoie les ressources (à appeler dans le dispose du widget principal)
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}