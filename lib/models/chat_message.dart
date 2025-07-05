import 'package:uuid/uuid.dart';

enum MessageType {
  text,
  image,
  document,
  audio,
  video,
  location,
  other
}

class MessageContent {
  final MessageType type;
  final String content; // Texte ou URL du média
  final String? mimeType;
  Map<String, dynamic>? metadata;

  MessageContent({
    required this.type,
    required this.content,
    this.mimeType,
    this.metadata,
  });

  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isDocument => type == MessageType.document;
  bool get isMedia => isImage || type == MessageType.video || type == MessageType.audio;

  factory MessageContent.text(String text) {
    return MessageContent(
      type: MessageType.text,
      content: text,
    );
  }

  factory MessageContent.image(String url, {String? mimeType}) {
    return MessageContent(
      type: MessageType.image,
      content: url,
      mimeType: mimeType ?? 'image/jpeg',
    );
  }

  factory MessageContent.document(String url, {String? mimeType}) {
    return MessageContent(
      type: MessageType.document,
      content: url,
      mimeType: mimeType ?? 'application/octet-stream',
    );
  }

  void updateMetadata(Map<String, dynamic> newMetadata) { metadata = newMetadata; }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'content': content,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.other,
      ),
      content: json['content'],
      mimeType: json['mimeType'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageContent content;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    String? id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    DateTime? timestamp,
    this.isRead = false,
    this.metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  bool get isUser => senderId == 'user';  // Assuming 'user' ID defines isUser; adjust if different logic is needed

  factory ChatMessage.text({
    String? id,
    required String conversationId,
    required String senderId,
    required String text,
    DateTime? timestamp,
    bool isRead = false,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: MessageContent.text(text),
      timestamp: timestamp,
      isRead: isRead,
      metadata: metadata,
    );
  }

  factory ChatMessage.image({
    String? id,
    required String conversationId,
    required String senderId,
    required String imageUrl,
    String? mimeType,
    DateTime? timestamp,
    bool isRead = false,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: MessageContent.image(imageUrl, mimeType: mimeType),
      timestamp: timestamp,
      isRead: isRead,
      metadata: metadata,
    );
  }

  factory ChatMessage.document({
    String? id,
    required String conversationId,
    required String senderId,
    required String documentUrl,
    String? mimeType,
    DateTime? timestamp,
    bool isRead = false,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: MessageContent.document(documentUrl, mimeType: mimeType),
      timestamp: timestamp,
      isRead: isRead,
      metadata: metadata,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: MessageContent.fromJson(Map<String, dynamic>.from(json['content'])),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      if (metadata != null) 'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageContent? content,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
