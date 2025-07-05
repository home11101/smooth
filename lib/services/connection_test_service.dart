import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class ConnectionTestService {
  
  /// Teste la connexion à Supabase
  static Future<bool> testSupabaseConnection() async {
    try {
      print('🔄 Test de connexion Supabase...');
      
      // Test simple de ping à l'API Supabase
      final response = await supabase
          .from('profiles')
          .select('count')
          .count(CountOption.exact);
      
      print('✅ Supabase connecté avec succès !');
      print('📊 Nombre de profils: ${response.count}');
      return true;
      
    } catch (e) {
      print('❌ Erreur Supabase: $e');
      return false;
    }
  }
  
  /// Teste la connexion à OpenAI
  static Future<bool> testOpenAIConnection() async {
    try {
      print('🔄 Test de connexion OpenAI...');
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Test de connexion'}
          ],
          'max_tokens': 10,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ OpenAI connecté avec succès !');
        final data = jsonDecode(response.body);
        print('🤖 Réponse: ${data['choices'][0]['message']['content']}');
        return true;
      } else {
        print('❌ Erreur OpenAI: ${response.statusCode} - ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ Erreur OpenAI: $e');
      return false;
    }
  }
  
  /// Teste l'authentification Supabase
  static Future<bool> testAuthentication() async {
    try {
      print('🔄 Test d\'authentification...');
      
      // Créer un utilisateur de test
      final email = 'test-${DateTime.now().millisecondsSinceEpoch}@smoothai.com';
      const password = 'TestPassword123!';
      
      // Inscription
      final signUpResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': 'Utilisateur Test'},
      );
      
      if (signUpResponse.user != null) {
        print('✅ Inscription réussie !');
        print('👤 Utilisateur: ${signUpResponse.user!.email}');
        
        // Déconnexion
        await supabase.auth.signOut();
        print('✅ Déconnexion réussie !');
        
        return true;
      } else {
        print('❌ Échec de l\'inscription');
        return false;
      }
      
    } catch (e) {
      print('❌ Erreur d\'authentification: $e');
      return false;
    }
  }
  
  /// Lance tous les tests
  static Future<Map<String, bool>> runAllTests() async {
    print('🚀 Démarrage des tests de connexion...\n');
    
    final results = <String, bool>{};
    
    // Test Supabase
    results['supabase'] = await testSupabaseConnection();
    print('');
    
    // Test OpenAI
    results['openai'] = await testOpenAIConnection();
    print('');
    
    // Test Authentification
    results['auth'] = await testAuthentication();
    print('');
    
    // Résumé
    print('📋 RÉSUMÉ DES TESTS:');
    print('Supabase: ${results['supabase']! ? '✅' : '❌'}');
    print('OpenAI: ${results['openai']! ? '✅' : '❌'}');
    print('Authentification: ${results['auth']! ? '✅' : '❌'}');
    
    final allPassed = results.values.every((test) => test);
    print('\n🎯 Résultat global: ${allPassed ? '✅ TOUS LES TESTS PASSÉS' : '❌ CERTAINS TESTS ONT ÉCHOUÉ'}');
    
    return results;
  }
}
