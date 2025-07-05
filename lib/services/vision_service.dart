import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class VisionService {
  final String apiKey;
  VisionService(this.apiKey);

  /// Analyse une image et retourne un Map { 'messagesRecus': ..., 'messagesEnvoyes': ... }
  /// Les messages sont séparés pour l'analyse de conversation.
  Future<Map<String, String>?> detectAndSplitMessages(File imageFile) async {
    print('[DEBUG] VisionService.detectAndSplitMessages: début');
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    final body = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [{"type": "TEXT_DETECTION"}]
        }
      ]
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    print('[DEBUG] VisionService.detectAndSplitMessages: réponse status ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['responses'][0]['fullTextAnnotation']?['text'] ?? '';
      print('[DEBUG] VisionService.detectAndSplitMessages: texte brut = $text');
      final lines = (text.split('\n') as List)
          .where((l) => l is String && l.trim().isNotEmpty)
          .cast<String>()
          .toList();
      print('[DEBUG] VisionService.detectAndSplitMessages: lines = $lines');
      List<String> messagesRecus = [];
      List<String> messagesEnvoyes = [];
      for (int i = 0; i < lines.length; i++) {
        if (i % 2 == 0) {
          messagesRecus.add(lines[i]);
        } else {
          messagesEnvoyes.add(lines[i]);
        }
      }
      print('[DEBUG] VisionService.detectAndSplitMessages: messagesRecus = $messagesRecus, messagesEnvoyes = $messagesEnvoyes');
      return {
        'messagesRecus': messagesRecus.join('\n'),
        'messagesEnvoyes': messagesEnvoyes.join('\n'),
      };
    } else {
      print('Erreur Vision API: ${response.body}');
      return null;
    }
  }

  Future<Map<String, String>?> detectAndSplitMessagesFromBytes(Uint8List imageBytes) async {
    print('[DEBUG] VisionService.detectAndSplitMessagesFromBytes: début');
    final base64Image = base64Encode(imageBytes);
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    final body = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [{"type": "TEXT_DETECTION"}]
        }
      ]
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    print('[DEBUG] VisionService.detectAndSplitMessagesFromBytes: réponse status ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['responses'][0]['fullTextAnnotation']?['text'] ?? '';
      print('[DEBUG] VisionService.detectAndSplitMessagesFromBytes: texte brut = $text');
      final lines = (text.split('\n') as List)
          .where((l) => l is String && l.trim().isNotEmpty)
          .cast<String>()
          .toList();
      print('[DEBUG] VisionService.detectAndSplitMessagesFromBytes: lines = $lines');
      List<String> messagesRecus = [];
      List<String> messagesEnvoyes = [];
      for (int i = 0; i < lines.length; i++) {
        if (i % 2 == 0) {
          messagesRecus.add(lines[i]);
        } else {
          messagesEnvoyes.add(lines[i]);
        }
      }
      print('[DEBUG] VisionService.detectAndSplitMessagesFromBytes: messagesRecus = $messagesRecus, messagesEnvoyes = $messagesEnvoyes');
      return {
        'messagesRecus': messagesRecus.join('\n'),
        'messagesEnvoyes': messagesEnvoyes.join('\n'),
      };
    } else {
      print('Erreur Vision API (bytes): ${response.body}');
      return null;
    }
  }
} 