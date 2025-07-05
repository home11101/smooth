import '../models/chat_analysis.dart';

class ChatAnalyzer {
  ChatAnalysis analyzeChat(String chatContent) {
    final lines = chatContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    int totalMessages = lines.length;
    int userMessages = 0;
    int theirMessages = 0;
    int emojiCount = 0;
    List<String> redFlags = [];
    List<String> greenFlags = [];
    List<String> recommendations = [];
    
    // Count messages and analyze patterns
    for (String line in lines) {
      if (line.startsWith('You:')) {
        userMessages++;
      } else if (line.startsWith('Them:')) {
        theirMessages++;
      }
      
      // Count emojis
      emojiCount += _countEmojis(line);
    }
    
    // Calculate metrics
    int compatibilityScore = _calculateCompatibilityScore(
      userMessages, theirMessages, emojiCount, totalMessages
    );
    
    int interestLevel = _calculateInterestLevel(theirMessages, totalMessages);
    String responseSpeed = _calculateResponseSpeed(userMessages, theirMessages);
    
    // Analyze flags and recommendations
    _analyzeFlags(userMessages, theirMessages, emojiCount, redFlags, greenFlags);
    _generateRecommendations(compatibilityScore, redFlags, recommendations);
    
    return ChatAnalysis(
      compatibilityScore: compatibilityScore,
      totalMessages: totalMessages,
      interestLevel: interestLevel,
      responseSpeed: responseSpeed,
      emojiCount: emojiCount,
      redFlags: redFlags,
      greenFlags: greenFlags,
      recommendations: recommendations,
    );
  }
  
  int _countEmojis(String text) {
    // Simple emoji detection
    final emojiRegex = RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true);
    return emojiRegex.allMatches(text).length;
  }
  
  int _calculateCompatibilityScore(int userMessages, int theirMessages, int emojiCount, int totalMessages) {
    if (totalMessages == 0) return 0;
    
    // Balance of messages (closer to 50/50 is better)
    double messageBalance = 1.0 - (userMessages - theirMessages).abs() / totalMessages;
    
    // Emoji usage (moderate usage is good)
    double emojiScore = emojiCount > 0 ? (emojiCount / totalMessages).clamp(0.0, 1.0) : 0.0;
    
    // Overall engagement
    double engagement = theirMessages > 0 ? 1.0 : 0.0;
    
    int score = ((messageBalance * 0.4 + emojiScore * 0.3 + engagement * 0.3) * 100).round();
    return score.clamp(0, 100);
  }
  
  int _calculateInterestLevel(int theirMessages, int totalMessages) {
    if (totalMessages == 0) return 0;
    return ((theirMessages / totalMessages) * 100).round();
  }
  
  String _calculateResponseSpeed(int userMessages, int theirMessages) {
    if (theirMessages == 0) return 'No response';
    if (theirMessages >= userMessages) return 'Fast';
    if (theirMessages >= userMessages * 0.7) return 'Moderate';
    return 'Slow';
  }
  
  void _analyzeFlags(int userMessages, int theirMessages, int emojiCount, 
                    List<String> redFlags, List<String> greenFlags) {
    // Red flags
    if (theirMessages < userMessages * 0.3) {
      redFlags.add('Low response rate - they might not be very interested');
    }
    if (emojiCount == 0) {
      redFlags.add('No emojis used - conversation might feel dry');
    }
    if (userMessages > theirMessages * 3) {
      redFlags.add('You\'re doing most of the talking - try to engage them more');
    }
    
    // Green flags
    if (theirMessages >= userMessages * 0.7) {
      greenFlags.add('Good response rate - they seem engaged');
    }
    if (emojiCount > 0) {
      greenFlags.add('Using emojis - shows emotional engagement');
    }
    if ((userMessages - theirMessages).abs() <= 2) {
      greenFlags.add('Balanced conversation - both parties are participating equally');
    }
  }
  
  void _generateRecommendations(int compatibilityScore, List<String> redFlags, 
                               List<String> recommendations) {
    if (compatibilityScore < 50) {
      recommendations.add('Try asking more open-ended questions to encourage longer responses');
      recommendations.add('Share more about yourself to create deeper connection');
    }
    
    if (redFlags.any((flag) => flag.contains('response rate'))) {
      recommendations.add('Give them more space - avoid double texting');
      recommendations.add('Try changing the topic to something they might be more interested in');
    }
    
    if (redFlags.any((flag) => flag.contains('emojis'))) {
      recommendations.add('Add some emojis to make your messages more expressive');
    }
    
    recommendations.add('Keep the conversation light and fun');
    recommendations.add('Ask about their interests and hobbies');
  }
}
