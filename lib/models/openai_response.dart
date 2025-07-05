class OpenAIChatResponse {
  final String content;
  final int tokensUsed;
  final String model;
  final DateTime timestamp;
  
  OpenAIChatResponse({
    required this.content,
    required this.tokensUsed,
    required this.model,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory OpenAIChatResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIChatResponse(
      content: json['choices'][0]['message']['content'],
      tokensUsed: json['usage']['total_tokens'],
      model: json['model'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'tokens_used': tokensUsed,
      'model': model,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  @override
  String toString() => 'OpenAIChatResponse(tokens: $tokensUsed, model: $model)';
}
