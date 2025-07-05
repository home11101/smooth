import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:smooth_ai_dating_assistant/services/openai_service.dart';
import 'package:smooth_ai_dating_assistant/models/chat_message.dart';

// Mock pour le client HTTP
class MockHttpClient extends Mock implements http.Client {}

// Mock pour la réponse HTTP
class MockResponse extends Mock implements http.Response {
  final dynamic bodyData;
  @override
  final int statusCode;

  MockResponse(this.bodyData, {required this.statusCode});

  @override
  String get body => jsonEncode(bodyData);

  @override
  Map<String, String> get headers => {'content-type': 'application/json'};
}

// Fakes pour les types nécessaires
class UriFake extends Fake implements Uri {
  @override
  String toString() => 'https://api.openai.com/v1/chat/completions';
}

class ChatMessageFake extends Fake implements ChatMessage {
  @override
  final String senderId = 'user';
  
  @override
  final MessageContent content = MessageContent.text('Test message');
}

void main() {
  // Enregistrer les valeurs de repli avant tous les tests
  setUpAll(() {
    registerFallbackValue(UriFake());
    registerFallbackValue(ChatMessageFake());
  });
  
  late OpenAIService openAIService;
  late MockHttpClient mockHttpClient;
  
  const testApiKey = 'test-api-key';
  
  setUp(() {
    mockHttpClient = MockHttpClient();
    openAIService = OpenAIService(
      apiKey: testApiKey,
      client: mockHttpClient,
    );
  });

  group('getChatResponse', () {
    test('should return response when API call is successful', () async {
      // Arrange
      final expectedResponse = {
        'choices': [
          {
            'message': {
              'content': 'Bonjour! Comment puis-je vous aider aujourd\'hui?',
              'role': 'assistant',
            },
          },
        ],
        'usage': {'total_tokens': 42},
        'model': 'gpt-3.5-turbo',
      };

      when(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => MockResponse(expectedResponse, statusCode: 200));

      // Act
      final response = await openAIService.getChatResponse(
        'Bonjour',
        [],
      );

      // Assert
      expect(response, isA<String>());
      expect(response, isNotEmpty);
      verify(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).called(1);
    });

    test('should handle rate limit error gracefully', () async {
      // Arrange
      when(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => MockResponse(
        {
          'error': {
            'message': 'Rate limit exceeded',
            'type': 'rate_limit_exceeded',
          },
        },
        statusCode: 429,
      ));

      // Act
      final result = await openAIService.getChatResponse('Test', []);

      // Assert
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });

  group('analyzeChat', () {
    test('should return analysis when API call is successful', () async {
      // Arrange
      const testAnalysis = '''
      ## Analyse de la Conversation
      
      ### Dynamique de Conversation
      - Échange équilibré
      
      ### Recommandations
      - Continuer la discussion''';
      
      final expectedResponse = {
        'choices': [
          {
            'message': {
              'content': testAnalysis,
              'role': 'assistant',
            },
          },
        ],
        'usage': {'total_tokens': 150},
        'model': 'gpt-4',
      };

      when(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => MockResponse(expectedResponse, statusCode: 200));

      // Act
      final analysis = await openAIService.analyzeChat(
        texteEnvoye: 'User: Bonjour\nAI: Salut!',
        texteRecu: 'Bonjour',
      );

      // Assert
      expect(analysis, isA<String>());
      expect(analysis, contains('Analyse de la Conversation'));
    });
  });

  test('dispose should close the HTTP client', () {
    // Arrange
    when(() => mockHttpClient.close()).thenAnswer((_) async {});

    // Act
    openAIService.dispose();

    // Assert
    verify(() => mockHttpClient.close()).called(1);
  });
}
