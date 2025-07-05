import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SoundService {
  static bool _soundEnabled = true;

  static Future<void> initialize() async {
    // Charger les préférences de son
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
  }

  static Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  static bool get isSoundEnabled => _soundEnabled;

  static Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Erreur lors du retour haptique: $e');
    }
  }

  static Future<void> playError() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.vibrate();
    } catch (e) {
      print('Erreur lors du retour haptique: $e');
    }
  }

  static Future<void> playNotification() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Erreur lors du retour haptique: $e');
    }
  }

  static Future<void> playMessage() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Erreur lors du retour haptique: $e');
    }
  }

  static Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Erreur lors du retour haptique: $e');
    }
  }
}
