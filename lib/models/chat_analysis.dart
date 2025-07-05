class ChatAnalysis {
  final int compatibilityScore;
  final int totalMessages;
  final int interestLevel;
  final String responseSpeed;
  final int emojiCount;
  final List<String> redFlags;
  final List<String> greenFlags;
  final List<String> recommendations;

  ChatAnalysis({
    required this.compatibilityScore,
    required this.totalMessages,
    required this.interestLevel,
    required this.responseSpeed,
    required this.emojiCount,
    required this.redFlags,
    required this.greenFlags,
    required this.recommendations,
  });
}
