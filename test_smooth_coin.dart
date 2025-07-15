import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/services/referral_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test du système Smooth Coin...');
  
  try {
    // Test 1: Récupérer le device_id
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
      print('✅ Nouveau device_id créé: $deviceId');
    } else {
      print('✅ Device_id existant: $deviceId');
    }
    
    // Test 2: Créer/récupérer le code de parrainage
    final referralService = ReferralService();
    final referralCode = await referralService.createReferralCode(deviceId);
    print('✅ Code de parrainage: $referralCode');
    
    // Test 3: Récupérer les statistiques
    final stats = await referralService.getUserReferralStats(deviceId);
    print('✅ Statistiques: $stats');
    
    if (stats != null) {
      print('📊 Points disponibles: ${stats['available_points']}');
      print('📊 Total gagnés: ${stats['total_points_earned']}');
      print('📊 Total utilisés: ${stats['total_points_used']}');
      print('📊 Parrainages: ${stats['total_referrals']}');
      print('📊 Code: ${stats['referral_code']}');
    }
    
    print('\n✅ Tous les tests sont passés !');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
} 