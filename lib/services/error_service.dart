import 'package:flutter/material.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  /// Gère les erreurs de manière centralisée
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    debugPrint('Error in $context: $error');
    debugPrint('StackTrace: $stackTrace');
    
    // Log l'erreur pour analyse
    _logError(error, stackTrace, context);
    
    // Affiche une notification à l'utilisateur si nécessaire
    _showUserFriendlyError(error, context);
  }

  /// Log les erreurs pour analyse
  static void _logError(dynamic error, StackTrace? stackTrace, String? context) {
    // TODO: Implémenter un système de logging (Firebase Crashlytics, Sentry, etc.)
    print('=== ERROR LOG ===');
    print('Context: $context');
    print('Error: $error');
    print('StackTrace: $stackTrace');
    print('Timestamp: ${DateTime.now()}');
    print('==================');
  }

  /// Affiche une erreur conviviale à l'utilisateur
  static void _showUserFriendlyError(dynamic error, String? context) {
    String message = 'Une erreur inattendue s\'est produite.';
    
    if (error is NetworkException) {
      message = 'Problème de connexion. Vérifiez votre connexion internet.';
    } else if (error is TimeoutException) {
      message = 'La requête a pris trop de temps. Réessayez.';
    } else if (error is FormatException) {
      message = 'Données invalides. Veuillez réessayer.';
    } else if (error.toString().contains('permission')) {
      message = 'Permission refusée. Vérifiez les autorisations de l\'application.';
    }
    
    // TODO: Implémenter un système de notification toast ou snackbar
    print('User message: $message');
  }

  /// Vérifie la connectivité réseau
  static Future<bool> checkConnectivity() async {
    try {
      // TODO: Implémenter une vraie vérification de connectivité
      return true;
    } catch (e) {
      handleError(e, null, context: 'checkConnectivity');
      return false;
    }
  }

  /// Valide les données d'entrée
  static bool validateInput(String? input, {int? minLength, int? maxLength}) {
    if (input == null || input.trim().isEmpty) {
      return false;
    }
    
    if (minLength != null && input.length < minLength) {
      return false;
    }
    
    if (maxLength != null && input.length > maxLength) {
      return false;
    }
    
    return true;
  }

  /// Gère les erreurs de navigation
  static void handleNavigationError(BuildContext context, String route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible d\'ouvrir $route'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Gère les erreurs de chargement
  static Widget buildErrorWidget(String message, VoidCallback? onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }

  /// Gère les erreurs de chargement avec animation
  static Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Exceptions personnalisées
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
} 