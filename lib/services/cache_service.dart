import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pickup_line.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _pickupLinesKey = 'pickup_lines_cache';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _lastUpdateKey = 'last_update';
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Cache les phrases d'accroche
  static Future<void> cachePickupLines(List<PickupLine> pickupLines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = pickupLines.map((line) => line.toJson()).toList();
      await prefs.setString(_pickupLinesKey, jsonEncode(jsonList));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erreur lors du cache des phrases d\'accroche: $e');
    }
  }

  /// Récupère les phrases d'accroche du cache
  static Future<List<PickupLine>?> getCachedPickupLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_pickupLinesKey);
      final lastUpdate = prefs.getString(_lastUpdateKey);

      if (cachedData == null || lastUpdate == null) {
        return null;
      }

      // Vérifier si le cache a expiré
      final lastUpdateTime = DateTime.parse(lastUpdate);
      if (DateTime.now().difference(lastUpdateTime) > _cacheExpiration) {
        await clearCache();
        return null;
      }

      final jsonList = jsonDecode(cachedData) as List;
      return jsonList.map((json) => PickupLine.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }

  /// Cache les préférences utilisateur
  static Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPreferencesKey, jsonEncode(preferences));
    } catch (e) {
      print('Erreur lors du cache des préférences: $e');
    }
  }

  /// Récupère les préférences utilisateur du cache
  static Future<Map<String, dynamic>?> getCachedUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_userPreferencesKey);
      
      if (cachedData == null) {
        return null;
      }

      return jsonDecode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      print('Erreur lors de la récupération des préférences: $e');
      return null;
    }
  }

  /// Met à jour une préférence spécifique
  static Future<void> updateUserPreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPreferences = await getCachedUserPreferences() ?? {};
      currentPreferences[key] = value;
      await cacheUserPreferences(currentPreferences);
    } catch (e) {
      print('Erreur lors de la mise à jour de la préférence: $e');
    }
  }

  /// Récupère une préférence spécifique
  static Future<T?> getUserPreference<T>(String key, T defaultValue) async {
    try {
      final preferences = await getCachedUserPreferences();
      if (preferences == null || !preferences.containsKey(key)) {
        return defaultValue;
      }
      return preferences[key] as T;
    } catch (e) {
      print('Erreur lors de la récupération de la préférence: $e');
      return defaultValue;
    }
  }

  /// Cache des données génériques
  static Future<void> cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (data is String) {
        await prefs.setString(key, data);
      } else if (data is int) {
        await prefs.setInt(key, data);
      } else if (data is double) {
        await prefs.setDouble(key, data);
      } else if (data is bool) {
        await prefs.setBool(key, data);
      } else {
        await prefs.setString(key, jsonEncode(data));
      }
    } catch (e) {
      print('Erreur lors du cache des données: $e');
    }
  }

  /// Cache spécialisé pour l'historique d'analyse OCR avec gestion des Uint8List
  static Future<void> cacheAnalysisHistory(String key, List<Map<String, dynamic>> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les données pour la sérialisation JSON
      final serializableHistory = history.map((item) {
        final Map<String, dynamic> serializableItem = Map<String, dynamic>.from(item);
        
        // Convertir Uint8List en base64 pour la sérialisation JSON
        if (serializableItem['uploadedImageBytes'] is Uint8List) {
          serializableItem['uploadedImageBytes'] = base64Encode(serializableItem['uploadedImageBytes']);
          serializableItem['_hasImageData'] = true; // Marqueur pour la désérialisation
        }
        
        return serializableItem;
      }).toList();
      
      await prefs.setString(key, jsonEncode(serializableHistory));
    } catch (e) {
      print('Erreur lors du cache de l\'historique d\'analyse: $e');
    }
  }

  /// Récupère l'historique d'analyse OCR avec conversion des Uint8List
  static Future<List<Map<String, dynamic>>?> getCachedAnalysisHistory(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      
      if (data == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(data);
      final List<Map<String, dynamic>> history = [];
      
      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          final Map<String, dynamic> deserializedItem = Map<String, dynamic>.from(item);
          
          // Convertir base64 en Uint8List si nécessaire
          if (deserializedItem['_hasImageData'] == true && deserializedItem['uploadedImageBytes'] is String) {
            try {
              deserializedItem['uploadedImageBytes'] = base64Decode(deserializedItem['uploadedImageBytes']);
              deserializedItem.remove('_hasImageData'); // Nettoyer le marqueur
            } catch (e) {
              print('Erreur lors de la conversion base64 vers Uint8List: $e');
              deserializedItem['uploadedImageBytes'] = null;
            }
          }
          
          history.add(deserializedItem);
        }
      }
      
      return history;
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique d\'analyse: $e');
      return null;
    }
  }

  /// Récupère des données génériques du cache
  static Future<T?> getCachedData<T>(String key, T defaultValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (defaultValue is String) {
        return prefs.getString(key) as T? ?? defaultValue;
      } else if (defaultValue is int) {
        return prefs.getInt(key) as T? ?? defaultValue;
      } else if (defaultValue is double) {
        return prefs.getDouble(key) as T? ?? defaultValue;
      } else if (defaultValue is bool) {
        return prefs.getBool(key) as T? ?? defaultValue;
      } else {
        final data = prefs.getString(key);
        if (data == null) return defaultValue;
        return jsonDecode(data) as T;
      }
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return defaultValue;
    }
  }

  /// Vérifie si le cache est valide
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      if (lastUpdate == null) {
        return false;
      }

      final lastUpdateTime = DateTime.parse(lastUpdate);
      return DateTime.now().difference(lastUpdateTime) <= _cacheExpiration;
    } catch (e) {
      print('Erreur lors de la vérification du cache: $e');
      return false;
    }
  }

  /// Efface tout le cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Erreur lors de l\'effacement du cache: $e');
    }
  }

  /// Efface une clé spécifique du cache
  static Future<void> removeFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      print('Erreur lors de la suppression du cache: $e');
    }
  }

  /// Obtient la taille du cache
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int size = 0;
      
      for (String key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          size += value.length;
        }
      }
      
      return size;
    } catch (e) {
      print('Erreur lors du calcul de la taille du cache: $e');
      return 0;
    }
  }

  /// Optimise le cache en supprimant les anciennes données
  static Future<void> optimizeCache() async {
    try {
      final cacheSize = await getCacheSize();
      const maxCacheSize = 10 * 1024 * 1024; // 10 MB
      
      if (cacheSize > maxCacheSize) {
        // Supprimer les données les plus anciennes
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().toList();
        
        // Trier par date de modification (approximatif)
        keys.sort((a, b) {
          final aValue = prefs.get(a);
          final bValue = prefs.get(b);
          // Logique simple de tri basée sur la taille
          if (aValue is String && bValue is String) {
            return aValue.length.compareTo(bValue.length);
          }
          return 0;
        });
        
        // Supprimer les 20% les plus anciens
        final keysToRemove = keys.take((keys.length * 0.2).round()).toList();
        for (String key in keysToRemove) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Erreur lors de l\'optimisation du cache: $e');
    }
  }
} 