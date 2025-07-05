import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/coaching_service.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp)';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smooth IA Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: '-apple-system',
      ),
      home: const SmoothCoachingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SmoothCoachingScreen extends StatefulWidget {
  const SmoothCoachingScreen({super.key});

  @override
  _SmoothCoachingScreenState createState() => _SmoothCoachingScreenState();
}

class _SmoothCoachingScreenState extends State<SmoothCoachingScreen>
    with TickerProviderStateMixin {
  late final CoachingService _coachingService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _floatAnimationController;
  late Animation<double> _floatAnimation;
  bool? _isPremium;

  @override
  void initState() {
    super.initState();
    
    // Initialisation du service de coaching DOCTEUR LOVE
    _coachingService = CoachingService();
    
    // Initialisation de l'animation
    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _floatAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Afficher le message de bienvenue après un court délai
    Future.delayed(const Duration(milliseconds: 500), _showWelcomeMessage);
    
    // Vérifier l'accès premium
    SubscriptionService().isPremium().then((value) {
      if (mounted) setState(() => _isPremium = value);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _floatAnimationController.dispose();
    _coachingService.dispose();
    super.dispose();
  }

  void _showWelcomeMessage() {
    _addMessage("🩺💕 Bonjour, je suis le DOCTEUR LOVE ! Votre coach de séduction personnel. Comment puis-je vous aider aujourd'hui ? Avez-vous un problème de cœur à me confier ?", false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();
  }

  void _hideTypingIndicator() {
    setState(() {
      _isTyping = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Ajouter le message de l'utilisateur à l'UI pour une réactivité instantanée
    _addMessage(message, true);
    _messageController.clear();
    _showTypingIndicator();

    try {
      // Convertir l'historique des messages au format attendu par le CoachingService
      final history = _messages
          .where((msg) => !msg.isUser) // Seulement les messages du coach
          .map((msg) => {
                'role': 'assistant',
                'content': msg.text,
              })
          .toList();

      // Utilisation du CoachingService pour générer une réponse du DOCTEUR LOVE
      final botResponse = await _coachingService.getCoachResponse(message, history);
      
      _hideTypingIndicator();
      _addMessage(botResponse, false);
    } catch (e) {
      debugPrint('Erreur dans _sendMessage: $e');
      _hideTypingIndicator();
      _addMessage(
          "🩺 Désolé, le DOCTEUR LOVE est temporairement indisponible. Veuillez réessayer plus tard.",
          false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isPremium == false) {
      return Scaffold(
        body: Center(
          child: PremiumLockWidget(
            feature: 'smooth_coaching',
            title: 'Fonctionnalité Premium',
            description: 'Le coach IA Smooth est réservé aux membres Premium.',
            icon: Icons.chat_bubble,
            onUnlock: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppTheme.buildPickupScreenBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildChatArea()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF007AFF)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            return _buildTypingIndicator();
          }
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: message.isUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 20),
              child: Text(
                'Smooth IA',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: message.isUser
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        Color(0xFF5BA3F2),
                        Color(0xFF6BB6FF),
                      ],
                    )
                  : null,
              color: message.isUser 
                  ? null 
                  : Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: message.isUser 
                      ? AppTheme.primaryBlue.withAlpha(77)
                      : Colors.black.withAlpha(26),
                  blurRadius: message.isUser ? 32 : 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 16,
                color: message.isUser ? Colors.white : const Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 5, left: 20),
            child: Text(
              'Smooth IA',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDots(),
                const SizedBox(width: 8),
                const Text(
                  '🩺 DOCTEUR LOVE réfléchit...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: 30 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(102),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/leSmenu.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(204),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppTheme.primaryBlue.withAlpha(26),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "L'amour est la poésie du sens",
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryBlue,
                            Color(0xFF5BA3F2),
                            Color(0xFF6BB6FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withAlpha(40),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: Modèles de données pour l'API
/*
class ApiRequest {
  final String message;
  final String userId;
  final String sessionId;

  ApiRequest({
    required this.message,
    required this.userId,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_id': userId,
      'session_id': sessionId,
    };
  }
}

class ApiResponse {
  final String response;
  final bool success;
  final String? error;

  ApiResponse({
    required this.response,
    required this.success,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      response: json['response'] ?? '',
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}
*/

// TODO: Service de gestion des API
/*
class ChatService {
  static const String _baseUrl = 'https://your-api-url.com';
  static const String _chatEndpoint = '/api/chat';

  static Future<ApiResponse> sendMessage(ApiRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(
        response: 'Erreur de connexion',
        success: false,
        error: e.toString(),
      );
    }
  }
}
*/