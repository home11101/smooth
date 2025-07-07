import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  static const String _supabaseUrl = 'https://qlomkoexurbxqsezavdi.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

  /// Génère un code de parrainage pour un utilisateur après un paiement premium
  Future<String?> createReferralCode(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/rpc/create_referral_code'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as String?;
      } else {
        print('Erreur lors de la création du code de parrainage: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur réseau lors de la création du code de parrainage: $e');
      return null;
    }
  }

  /// Récupère les statistiques de parrainage d'un utilisateur
  Future<Map<String, dynamic>?> getUserReferralStats(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/rpc/get_user_referral_stats'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>?;
      } else {
        print('Erreur lors de la récupération des stats de parrainage: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur réseau lors de la récupération des stats de parrainage: $e');
      return null;
    }
  }

  /// Utilise un code de parrainage
  Future<Map<String, dynamic>?> useReferralCode(String code, String deviceId, String? subscriptionType) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/rpc/use_referral_code'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_code': code,
          'p_referred_device_id': deviceId,
          'p_subscription_type': subscriptionType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>?;
      } else {
        print('Erreur lors de l\'utilisation du code de parrainage: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur réseau lors de l\'utilisation du code de parrainage: $e');
      return null;
    }
  }

  /// Applique une réduction de parrainage
  Future<Map<String, dynamic>?> applyReferralDiscount(String deviceId, int pointsToUse, String? paymentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/rpc/apply_referral_discount'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'p_device_id': deviceId,
          'p_points_to_use': pointsToUse,
          'p_payment_id': paymentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>?;
      } else {
        print('Erreur lors de l\'application de la réduction: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur réseau lors de l\'application de la réduction: $e');
      return null;
    }
  }

  /// Récupère l'ID de l'appareil
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }

  /// Génère un code de parrainage pour l'utilisateur actuel
  Future<String?> generateReferralCodeForCurrentUser() async {
    final deviceId = await _getDeviceId();
    return await createReferralCode(deviceId);
  }

  /// Récupère les stats de parrainage de l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUserReferralStats() async {
    final deviceId = await _getDeviceId();
    return await getUserReferralStats(deviceId);
  }

  /// Utilise un code de parrainage pour l'utilisateur actuel
  Future<Map<String, dynamic>?> useReferralCodeForCurrentUser(String code, String? subscriptionType) async {
    final deviceId = await _getDeviceId();
    return await useReferralCode(code, deviceId, subscriptionType);
  }

  /// Applique une réduction de parrainage pour l'utilisateur actuel
  Future<Map<String, dynamic>?> applyReferralDiscountForCurrentUser(int pointsToUse, String? paymentId) async {
    final deviceId = await _getDeviceId();
    return await applyReferralDiscount(deviceId, pointsToUse, paymentId);
  }
} 