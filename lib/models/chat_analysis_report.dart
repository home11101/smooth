import 'chat_message.dart';

class ChatAnalysisReport {
  final String id;
  final DateTime timestamp;
  final List<ChatMessage> messages;
  final String analysis;
  final int engagementScore;
  final List<String> greenFlags;
  final List<String> redFlags;
  final List<String> recommendations;
  final double overallRating;
  final int nombreMessagesVous;
  final int nombreMessagesEux;
  final int niveauInteretVous;
  final int niveauInteretEux;
  final List<String> motsSignificatifsVous;
  final List<String> motsSignificatifsEux;
  final List<String> alertesRouges;
  final List<String> signauxPositifs;
  final String styleAttachementVous;
  final String styleAttachementEux;
  final int scoreCompatibilite;

  ChatAnalysisReport({
    required this.id,
    required this.timestamp,
    required this.messages,
    required this.analysis,
    required this.engagementScore,
    required this.greenFlags,
    required this.redFlags,
    required this.recommendations,
    required this.overallRating,
    required this.nombreMessagesVous,
    required this.nombreMessagesEux,
    required this.niveauInteretVous,
    required this.niveauInteretEux,
    required this.motsSignificatifsVous,
    required this.motsSignificatifsEux,
    required this.alertesRouges,
    required this.signauxPositifs,
    required this.styleAttachementVous,
    required this.styleAttachementEux,
    required this.scoreCompatibilite,
  });

  factory ChatAnalysisReport.fromJson(Map<String, dynamic> json) {
    return ChatAnalysisReport(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => ChatMessage.fromJson(msg))
          .toList() ?? [],
      analysis: json['analysis'] ?? '',
      engagementScore: json['engagementScore'] ?? 0,
      greenFlags: List<String>.from(json['greenFlags'] ?? []),
      redFlags: List<String>.from(json['redFlags'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      overallRating: (json['overallRating'] ?? 0.0).toDouble(),
      nombreMessagesVous: json['nombreMessagesVous'] ?? 0,
      nombreMessagesEux: json['nombreMessagesEux'] ?? 0,
      niveauInteretVous: json['niveauInteretVous'] ?? 0,
      niveauInteretEux: json['niveauInteretEux'] ?? 0,
      motsSignificatifsVous: List<String>.from(json['motsSignificatifsVous'] ?? []),
      motsSignificatifsEux: List<String>.from(json['motsSignificatifsEux'] ?? []),
      alertesRouges: List<String>.from(json['alertesRouges'] ?? []),
      signauxPositifs: List<String>.from(json['signauxPositifs'] ?? []),
      styleAttachementVous: json['styleAttachementVous'] ?? '',
      styleAttachementEux: json['styleAttachementEux'] ?? '',
      scoreCompatibilite: json['scoreCompatibilite'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'analysis': analysis,
      'engagementScore': engagementScore,
      'greenFlags': greenFlags,
      'redFlags': redFlags,
      'recommendations': recommendations,
      'overallRating': overallRating,
      'nombreMessagesVous': nombreMessagesVous,
      'nombreMessagesEux': nombreMessagesEux,
      'niveauInteretVous': niveauInteretVous,
      'niveauInteretEux': niveauInteretEux,
      'motsSignificatifsVous': motsSignificatifsVous,
      'motsSignificatifsEux': motsSignificatifsEux,
      'alertesRouges': alertesRouges,
      'signauxPositifs': signauxPositifs,
      'styleAttachementVous': styleAttachementVous,
      'styleAttachementEux': styleAttachementEux,
      'scoreCompatibilite': scoreCompatibilite,
    };
  }
} 