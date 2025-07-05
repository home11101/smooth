import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_ai_dating_assistant/models/chat_message.dart';
import 'package:uuid/uuid.dart';

// Test d'intégration simplifié
void main() {
  test('Dummy test for chat analysis', () {
    // Ce test vérifie simplement que les modèles peuvent être instanciés
    final message = ChatMessage(
      id: const Uuid().v4(),
      conversationId: const Uuid().v4(),
      senderId: 'test-user',
      content: MessageContent.text('Test message'),
      timestamp: DateTime.now(),
    );
    
    expect(message.id, isNotEmpty);
    expect(message.content.isText, isTrue);
    expect(message.content.content, 'Test message');
  });
}
