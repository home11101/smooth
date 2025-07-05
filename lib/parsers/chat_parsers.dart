import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:syncfusion_flutter_pdf/pdf.dart';
// Supprimé: google_mlkit_text_recognition
// On utilise Vision API cloud via VisionService
import '../models/chat_message.dart';
import '../services/vision_service.dart';

// Parser WhatsApp (format texte exporté)
List<ChatMessage> parseWhatsAppExport(String content) {
  final regex = RegExp(r'^(\d{1,2}/\d{1,2}/\d{2,4}),? (\d{1,2}:\d{2}) - ([^:]+): (.+)', multiLine: true);
  final matches = regex.allMatches(content);
  return matches.map((m) {
    final dateStr = m.group(1)!;
    final timeStr = m.group(2)!;
    final sender = m.group(3)!;
    final text = m.group(4)!;
    DateTime timestamp;
    try {
      timestamp = DateTime.parse('${dateStr.split('/').reversed.join('-')}T$timeStr');
    } catch (_) {
      timestamp = DateTime.now();
    }
    return ChatMessage(
      conversationId: 'conv1',
      senderId: sender,
      timestamp: timestamp,
      content: MessageContent(type: MessageType.text, content: text),
    );
  }).toList();
}

// Parser Messenger (format texte exporté simple)
List<ChatMessage> parseMessengerExport(String content) {
  final regex = RegExp(r'^([^:]+): (.+)', multiLine: true);
  final matches = regex.allMatches(content);
  return matches.map((m) {
    final sender = m.group(1)!;
    final text = m.group(2)!;
    return ChatMessage(
      conversationId: 'conv1',
      senderId: sender,
      timestamp: DateTime.now(),
      content: MessageContent(type: MessageType.text, content: text),
    );
  }).toList();
}

// Messenger JSON officiel (Facebook)
List<ChatMessage> parseMessengerJson(String content) {
  final data = jsonDecode(content);
  final List<ChatMessage> messages = [];
  if (data is Map && data['messages'] is List) {
    for (final m in data['messages']) {
      messages.add(ChatMessage(
        conversationId: 'conv1',
        senderId: m['sender_name'] ?? 'unknown',
        timestamp: DateTime.fromMillisecondsSinceEpoch((m['timestamp_ms'] ?? 0)),
        content: MessageContent(type: MessageType.text, content: m['content']?.toString() ?? ''),
      ));
    }
  }
  return messages;
}

// Instagram JSON officiel
List<ChatMessage> parseInstagramJson(String content) {
  final data = jsonDecode(content);
  final List<ChatMessage> messages = [];
  if (data is Map && data['messages'] is List) {
    for (final m in data['messages']) {
      messages.add(ChatMessage(
        conversationId: 'conv1',
        senderId: m['sender'] ?? 'unknown',
        timestamp: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
        content: MessageContent(type: MessageType.text, content: m['text']?.toString() ?? ''),
      ));
    }
  }
  return messages;
}

// Telegram HTML export
List<ChatMessage> parseTelegramHtml(String content) {
  final document = html_parser.parse(content);
  final List<ChatMessage> messages = [];
  final nodes = document.querySelectorAll('.message');
  for (final node in nodes) {
    final sender = node.querySelector('.from')?.text ?? 'unknown';
    final text = node.querySelector('.text')?.text ?? '';
    final dateStr = node.querySelector('.date')?.attributes['title'] ?? '';
    final timestamp = DateTime.tryParse(dateStr) ?? DateTime.now();
    messages.add(ChatMessage(
      conversationId: 'conv1',
      senderId: sender,
      timestamp: timestamp,
      content: MessageContent(type: MessageType.text, content: text),
    ));
  }
  return messages;
}

// CSV simple: sender,text,date
List<ChatMessage> parseCsv(String content) {
  final lines = content.split('\n');
  final List<ChatMessage> messages = [];
  for (final line in lines.skip(1)) {
    final parts = line.split(',');
    if (parts.length >= 3) {
      messages.add(ChatMessage(
        conversationId: 'conv1',
        senderId: parts[0],
        timestamp: DateTime.tryParse(parts[2]) ?? DateTime.now(),
        content: MessageContent(type: MessageType.text, content: parts[1]),
      ));
    }
  }
  return messages;
}

// PDF (Syncfusion)
Future<List<ChatMessage>> parsePdf(File file) async {
  final bytes = await file.readAsBytes();
  final document = PdfDocument(inputBytes: bytes);
  final text = PdfTextExtractor(document).extractText();
  document.dispose();
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  return List<ChatMessage>.generate(lines.length, (i) => ChatMessage(
    conversationId: 'conv1',
    senderId: 'unknown',
    timestamp: DateTime.now(),
    content: MessageContent(type: MessageType.text, content: lines[i]),
  ));
}

// OCR image (Vision API Cloud)
Future<List<ChatMessage>> parseImageOcr(File file) async {
  // Utiliser VisionService pour l'OCR
  final visionService = VisionService('YOUR_VISION_API_KEY'); // À remplacer par la vraie clé
  final result = await visionService.detectAndSplitMessages(file);
  
  if (result != null) {
    final allText = '${result['messagesRecus']}\n${result['messagesEnvoyes']}';
    final lines = allText.split('\n').where((l) => l.trim().isNotEmpty).toList();
  return List<ChatMessage>.generate(lines.length, (i) => ChatMessage(
    conversationId: 'conv1',
    senderId: 'ocr',
    timestamp: DateTime.now(),
    content: MessageContent(type: MessageType.text, content: lines[i]),
  ));
  }
  
  return [];
}

// Fallback: chaque ligne = message texte
List<ChatMessage> parseFallbackLines(String content) {
  return content.split('\n').where((l) => l.trim().isNotEmpty).map((l) =>
    ChatMessage(
      conversationId: 'conv1',
      senderId: 'unknown',
      timestamp: DateTime.now(),
      content: MessageContent(type: MessageType.text, content: l),
    )
  ).toList();
}

// Fonction principale pour parser du texte de chat
List<ChatMessage> parseChatText(String text) {
  // Essayer différents formats dans l'ordre
  try {
    if (text.contains(' - ') && text.contains(':')) {
      return parseWhatsAppExport(text);
    }
  } catch (e) {
    // Continuer avec le prochain parser
  }
  
  try {
    if (text.contains('"messages"')) {
      return parseMessengerJson(text);
    }
  } catch (e) {
    // Continuer avec le prochain parser
  }
  
  try {
    if (text.contains('"sender"')) {
      return parseInstagramJson(text);
    }
  } catch (e) {
    // Continuer avec le prochain parser
  }
  
  try {
    if (text.contains(',')) {
      return parseCsv(text);
    }
  } catch (e) {
    // Continuer avec le prochain parser
  }
  
  // Fallback: parser ligne par ligne
  return parseFallbackLines(text);
}
