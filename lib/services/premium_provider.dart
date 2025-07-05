import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumProvider extends ChangeNotifier {
  static const String _premiumKey = 'isPremium';
  static const String _expiryDateKey = 'premiumExpiryDate';
  
  bool _isPremium = false;
  DateTime? _expiryDate;

  bool _isProcessing = false;
  String? _errorMessage;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  
  bool get isPremium {
    if (_expiryDate != null && DateTime.now().isAfter(_expiryDate!)) {
      _isPremium = false;
      _savePremiumStatus(false);
    }
    return _isPremium;
  }
  
  DateTime? get expiryDate => _expiryDate;
  
  PremiumProvider() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    
    final expiryDateStr = prefs.getString(_expiryDateKey);
    if (expiryDateStr != null) {
      _expiryDate = DateTime.parse(expiryDateStr);
      
      // Vérifier si l'abonnement est expiré
      if (DateTime.now().isAfter(_expiryDate!)) {
        _isPremium = false;
        await _savePremiumStatus(false);
      }
    }
    
    notifyListeners();
  }

  Future<void> setPremium(bool value, {DateTime? expiryDate}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value) {
      await prefs.setBool(_premiumKey, true);
      _isPremium = true;
      
      if (expiryDate != null) {
        await prefs.setString(_expiryDateKey, expiryDate.toIso8601String());
        _expiryDate = expiryDate;
      }
    } else {
      await prefs.setBool(_premiumKey, false);
      await prefs.remove(_expiryDateKey);
      _isPremium = false;
      _expiryDate = null;
    }
    
    notifyListeners();
  }
  
  Future<void> _savePremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    if (!value) {
      await prefs.remove(_expiryDateKey);
    }
  }
  
  // Vérifie si une fonctionnalité est disponible
  bool isFeatureAvailable(String feature) {
    // Certaines fonctionnalités peuvent être disponibles même sans abonnement
    if (feature == 'basic_feature') {
      return true;
    }
    return isPremium;
  }
  
  // Met à jour l'état premium à partir d'un achat
  Future<void> updateFromPurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased || 
        purchase.status == PurchaseStatus.restored) {
      
      // Pour un abonnement mensuel (30 jours)
      if (purchase.productID.contains('monthly')) {
        final expiry = DateTime.now().add(const Duration(days: 30));
        await setPremium(true, expiryDate: expiry);
      } 
      // Pour un abonnement annuel (365 jours)
      else if (purchase.productID.contains('yearly')) {
        final expiry = DateTime.now().add(const Duration(days: 365));
        await setPremium(true, expiryDate: expiry);
      }
      // Pour un achat unique
      else {
        await setPremium(true);
      }
    } else if (purchase.status == PurchaseStatus.error) {
      // Gérer les erreurs d'achat
      debugPrint('Erreur d\'achat: ${purchase.error}');
    }
  }

  // Méthodes pour gérer l'état de l'interface utilisateur
  void setProcessing(bool processing) {
    _isProcessing = processing;
    if (processing) {
      _errorMessage = null; // Réinitialiser les erreurs au début d'une nouvelle opération
    }
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  // Met à jour le statut premium à partir d'un achat (alias pour updateFromPurchase)
  Future<void> updatePremiumStatus(PurchaseDetails purchase) async {
    await updateFromPurchase(purchase);
  }
}
