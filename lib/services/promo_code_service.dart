import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

class PromoCodeService {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  // URLs des Supabase Functions
  static const String _validateUrl = 'https://qlomkoexurbxqsezavdi.supabase.co/functions/v1/validate-promo-code';
  static const String _useUrl = 'https://qlomkoexurbxqsezavdi.supabase.co/rest/v1/rpc/use_promo_code';

  // Clés pour les préférences
  static const String _appliedPromoCodeKey = 'applied_promo_code';
  static const String _promoCodeDiscountKey = 'promo_code_discount';
  static const String _promoCodeTypeKey = 'promo_code_type';
  static const String _deviceIdKey = 'device_id';

  // Cache pour éviter les appels répétés
  String? _cachedDeviceId;
  PromoCodeValidation? _cachedValidation;

  /// Valide un code promo
  Future<PromoCodeValidation> validatePromoCode(String code, {String? context}) async {
    try {
      final deviceId = await _getDeviceId();
      
      final response = await http.post(
        Uri.parse(_validateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8', // Remplacer par votre anon key
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8',
        },
        body: jsonEncode({
          'code': code.toUpperCase().trim(),
          'device_id': deviceId,
          'context': context ?? 'general'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final validation = PromoCodeValidation.fromJson(data);
        
        // Cache la validation pour éviter les appels répétés
        _cachedValidation = validation;
        
        debugPrint('Code promo validé: ${validation.isValid} - ${validation.description}');
        return validation;
      } else {
        debugPrint('Erreur de validation: ${response.statusCode} - ${response.body}');
        return PromoCodeValidation(
          isValid: false,
          errorMessage: 'Erreur de connexion lors de la validation du code promo.'
        );
      }
    } catch (e) {
      debugPrint('Exception lors de la validation du code promo : ${e.toString()}');
      return PromoCodeValidation(
        isValid: false,
        errorMessage: 'Erreur de connexion. Vérifiez votre connexion internet.'
      );
    }
  }

  /// Applique un code promo et enregistre son utilisation
  Future<bool> applyPromoCode(String code, double discountApplied, {String? subscriptionType}) async {
    try {
      final deviceId = await _getDeviceId();
      
      final response = await http.post(
        Uri.parse(_useUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzI5NzAsImV4cCI6MjA1MDU0ODk3MH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzI5NzAsImV4cCI6MjA1MDU0ODk3MH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
        },
        body: jsonEncode({
          'p_code': code.toUpperCase().trim(),
          'p_device_id': deviceId,
          'p_discount_applied': discountApplied,
          'p_subscription_type': subscriptionType,
          'p_ip_address': null,
          'p_user_agent': null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? false;
        if (success) {
          await _saveAppliedPromoCode(code, discountApplied);
          debugPrint('Code promo appliqué avec succès: $code');
        }
        return success;
      } else {
        debugPrint('Erreur d\'application: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception lors de l\'application du code promo : ${e.toString()}');
      return false;
    }
  }

  /// Obtient l'ID unique de l'appareil
  Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      if (kIsWeb) {
        // Pour le web, génère un ID unique et stocke-le
        deviceId = 'web_' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + (Random().nextInt(99999)).toString();
      } else {
        // Générer un ID unique basé sur les informations de l'appareil
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
        } else {
          // Fallback pour les autres plateformes
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
      }
      // Sauvegarder l'ID
      await prefs.setString(_deviceIdKey, deviceId);
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Sauvegarde le code promo appliqué
  Future<void> _saveAppliedPromoCode(String code, double discount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appliedPromoCodeKey, code);
    await prefs.setDouble(_promoCodeDiscountKey, discount);
    
    if (_cachedValidation != null) {
      if (_cachedValidation!.discountType != null) {
        await prefs.setString(_promoCodeTypeKey, _cachedValidation!.discountType!);
      }
    }
  }

  /// Récupère le code promo appliqué
  Future<AppliedPromoCode?> getAppliedPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_appliedPromoCodeKey);
    final discount = prefs.getDouble(_promoCodeDiscountKey);
    final type = prefs.getString(_promoCodeTypeKey);

    if (code != null && discount != null) {
      return AppliedPromoCode(
        code: code,
        discount: discount,
        discountType: type ?? 'percentage',
      );
    }

    return null;
  }

  /// Supprime le code promo appliqué
  Future<void> clearAppliedPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appliedPromoCodeKey);
    await prefs.remove(_promoCodeDiscountKey);
    await prefs.remove(_promoCodeTypeKey);
    _cachedValidation = null;
  }

  /// Vérifie si un code promo a déjà été appliqué
  Future<bool> hasAppliedPromoCode() async {
    final appliedCode = await getAppliedPromoCode();
    return appliedCode != null;
  }

  /// Calcule le prix avec réduction
  double calculateDiscountedPrice(double originalPrice, double discountPercentage) {
    if (discountPercentage <= 0) return originalPrice;
    if (discountPercentage >= 100) return 0.0;
    
    return originalPrice * (1 - discountPercentage / 100);
  }

  /// Formate le message de réduction
  String formatDiscountMessage(double discountPercentage) {
    if (discountPercentage >= 100) {
      return 'GRATUIT !';
    } else if (discountPercentage > 0) {
      return '-${discountPercentage.toInt()}%';
    } else {
      return '';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _cachedDeviceId = null;
    _cachedValidation = null;
  }
}

/// Modèle pour la validation d'un code promo
class PromoCodeValidation {
  final bool isValid;
  final String? discountType;
  final double? discountValue;
  final String? description;
  final String? errorMessage;

  PromoCodeValidation({
    required this.isValid,
    this.discountType,
    this.discountValue,
    this.description,
    this.errorMessage,
  });

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    return PromoCodeValidation(
      isValid: json['is_valid'] ?? false,
      discountType: json['discount_type'],
      discountValue: json['discount_value']?.toDouble(),
      description: json['description'],
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_valid': isValid,
      'discount_type': discountType,
      'discount_value': discountValue,
      'description': description,
      'error_message': errorMessage,
    };
  }
}

/// Modèle pour un code promo appliqué
class AppliedPromoCode {
  final String code;
  final double discount;
  final String discountType;

  AppliedPromoCode({
    required this.code,
    required this.discount,
    required this.discountType,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discount': discount,
      'discount_type': discountType,
    };
  }

  factory AppliedPromoCode.fromJson(Map<String, dynamic> json) {
    return AppliedPromoCode(
      code: json['code'],
      discount: json['discount'].toDouble(),
      discountType: json['discount_type'],
    );
  }
} 