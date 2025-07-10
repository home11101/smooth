import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/app_theme.dart';


import '../services/smooth_reply_service.dart';
import '../services/openai_service.dart';
import '../services/sound_service.dart';
import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';



class SmoothAIScreen extends StatefulWidget {
  const SmoothAIScreen({super.key});

  @override
  _SmoothAIScreenState createState() => _SmoothAIScreenState();
}

class _SmoothAIScreenState extends State<SmoothAIScreen>
    with TickerProviderStateMixin {
  
  // Controllers et variables d'état
  final List<Message> _messages = [];
  final TextEditingController _destinataireController = TextEditingController();
  final List<TextEditingController> _messageControllers = [];
  
  bool _isGenerating = false;
  String _generatedResponse = '';
  String _typewriterText = '';
  int _currentTypeIndex = 0;
  
  // Initialiser avec vos services réels
  late SmoothReplyService smoothReplyService;
  
  // Animations
  late AnimationController _backgroundAnimationController;
  late AnimationController _typewriterController;
  Timer? _typewriterTimer;

  // Types de réponses
  final List<ResponseType> _responseTypes = [
    ResponseType('SMOOTH', '😎'),
    ResponseType('SEXY', '🔥'),
    ResponseType('DRÔLE', '😂'),
    ResponseType('INTELLIGENTE', '🧠'),
  ];

  bool? _isPremium;

  // Ajouter la liste pour stocker toutes les réponses IA
  final List<String> _iaResponses = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMessageControllers();
    _initializeServices();
    // Vérifier l'accès premium
    SubscriptionService().isPremium().then((value) {
      if (mounted) setState(() => _isPremium = value);
    });
  }

  void _initializeServices() {
    // Initialiser vos services comme dans votre app existante
    final openAIService = OpenAIService();
    smoothReplyService = SmoothReplyService(openAIService);
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
  }

  void _initializeMessageControllers() {
    // Initialiser avec au moins une paire de contrôleurs
    for (int i = 0; i < 10; i++) {
      _messageControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _typewriterController.dispose();
    _typewriterTimer?.cancel();
    _destinataireController.dispose();
    for (var controller in _messageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Méthode adaptée à votre backend existant
  Future<void> _generateResponse() async {
    if (_messages.isEmpty) {
      _showSnack('Veuillez ajouter au moins un message pour obtenir une réponse.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedResponse = '';
      _typewriterText = '';
    });

    try {
      // Extraire les messages reçus et envoyés comme dans votre backend
      final receivedMessages = _messages
          .where((m) => m.type == MessageType.received && m.text.isNotEmpty)
          .map((m) => m.text)
          .join('\n');
      
      final userReplies = _messages
          .where((m) => m.type == MessageType.sent && m.text.isNotEmpty)
          .map((m) => m.text)
          .join('\n');

      // APPEL RÉEL À VOTRE SERVICE :
      final result = await smoothReplyService.generateSmoothReply(
        receivedMessage: receivedMessages,
        userReply: userReplies.isNotEmpty ? userReplies : null,
        context: _destinataireController.text.isNotEmpty 
          ? "Conversation avec ${_destinataireController.text}" 
          : null,
        intensity: _getIntensityFromType(),
      );
      
      setState(() {
        _isGenerating = false;
        _iaResponses.add(result);
      });
      
      _startTypewriterEffect(result);
      
    } catch (e) {
      _handleApiError(e.toString());
    }
  }

  // TODO: Mapper les types de réponse aux intensités
  int _getIntensityFromType() {
    switch (_responseTypes[_currentTypeIndex].type) {
      case 'SMOOTH':
        return 3;
      case 'SEXY':
        return 5;
      case 'DRÔLE':
        return 2;
      case 'INTELLIGENTE':
        return 1;
      default:
        return 3;
    }
  }



  void _handleApiError(String error) {
    setState(() {
      _isGenerating = false;
    });
    SoundService.playError();
    _showSnack('Erreur lors de la génération: $error');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: _generateResponse,
        ),
      ),
    );
  }

  void _startTypewriterEffect(String text) {
    _typewriterTimer?.cancel();
    int index = 0;
    
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < text.length) {
        setState(() {
          _typewriterText = text.substring(0, index + 1);
        });
        index++;
      } else {
        timer.cancel();
        SoundService.playSuccess();
      }
    });
  }

  void _cycleResponseType() {
    setState(() {
      _currentTypeIndex = (_currentTypeIndex + 1) % _responseTypes.length;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedResponse));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réponse copiée!')),
    );
  }

  void _updateMessage(int index, String value, MessageType type) {
    setState(() {
      if (value.trim().isNotEmpty) {
        if (index < _messages.length) {
          _messages[index] = Message(text: value, type: type);
        } else {
          // Ajouter des messages vides si nécessaire
          while (_messages.length <= index) {
            _messages.add(Message(text: '', type: MessageType.received));
          }
          _messages[index] = Message(text: value, type: type);
        }
      } else {
        if (index < _messages.length) {
          _messages[index] = Message(text: '', type: type);
        }
      }
    });
  }

  List<InputField> _getInputsToShow() {
    List<InputField> inputs = [];
    int pairIndex = 0;

    while (pairIndex < 5) {
      int receivedIndex = pairIndex * 2;
      int sentIndex = pairIndex * 2 + 1;

      // Toujours afficher la première case "Sa réponse"
      if (pairIndex == 0 || 
          (receivedIndex - 2 < _messages.length && 
           _messages[receivedIndex - 2].text.isNotEmpty)) {
        
        inputs.add(InputField(
          type: MessageType.received,
          index: receivedIndex,
          pairIndex: pairIndex,
        ));

        // Afficher "Ma réponse" seulement si "Sa réponse" a du contenu
        if (receivedIndex < _messages.length && 
            _messages[receivedIndex].text.isNotEmpty) {
          inputs.add(InputField(
            type: MessageType.sent,
            index: sentIndex,
            pairIndex: pairIndex,
          ));
        }
      }

      pairIndex++;

      // Arrêter si on a affiché une case vide
      if (pairIndex > 0 && 
          (receivedIndex >= _messages.length || 
           _messages[receivedIndex].text.isEmpty)) {
        break;
      }
    }

    return inputs;
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
            feature: 'enter_text',
            title: 'Fonctionnalité Premium',
            description: 'La génération de réponses IA est réservée aux membres Premium.',
            icon: Icons.text_fields,
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
      body: AppTheme.buildPickupScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildScrollableContent()),
              _buildBottomActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
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
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_messages.isEmpty && _iaResponses.isEmpty)
            _buildAlertBox(),
          const SizedBox(height: 16),
          _buildInputBoxes(),
          if (_isGenerating) _buildLoadingState(),
          if (_iaResponses.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.only(top: 24),
              child: ListView.builder(
                itemCount: _iaResponses.length,
                itemBuilder: (context, index) {
                  final isLast = index == _iaResponses.length - 1;
                  final iaResponse = _iaResponses[index];
                  // Only the last response uses the typing effect if generating
                  final displayText = isLast && _isGenerating ? _typewriterText : iaResponse;
                  return _buildGeneratedResponse(displayText);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellow.shade100, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200.withAlpha(128)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.yellow.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Veuillez saisir au moins un message pour obtenir des réponses',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBoxes() {
    final inputsToShow = _getInputsToShow();
    return Column(
      children: inputsToShow.asMap().entries.map((entry) {
        int idx = entry.key;
        InputField input = entry.value;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(
                input.type == MessageType.received
                  ? -100 * (1 - value)
                  : 100 * (1 - value),
                0,
              ),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  alignment: input.type == MessageType.received
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: _buildInputField(input),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildInputField(InputField input) {
    final isReceived = input.type == MessageType.received;
    final controller = _messageControllers[input.index];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 320,
        minHeight: 48,
        maxHeight: 200,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: isReceived
              ? const LinearGradient(
                  colors: [Color(0xFFF5F7FA), Color(0xFFD4EFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isReceived ? const Radius.circular(4) : const Radius.circular(20),
            bottomRight: isReceived ? const Radius.circular(20) : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: IntrinsicHeight(
          child: TextField(
            controller: controller,
            onChanged: (value) => _updateMessage(input.index, value, input.type),
            minLines: 1,
            maxLines: 6,
            expands: false,
            style: TextStyle(
              color: isReceived ? const Color(0xFF007AFF) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: isReceived ? 'Sa réponse' : 'Ma réponse',
              hintStyle: TextStyle(
                color: isReceived ? const Color(0xFF007AFF).withAlpha(128) : Colors.white70,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              suffixIcon: controller.text.isNotEmpty
                  ? Icon(
                      isReceived ? Icons.message : Icons.send,
                      color: isReceived ? const Color(0xFF007AFF) : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Réponse smooth en cours ...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedResponse([String? response]) {
    final displayText = response ?? _typewriterText;
    return Column(
      children: [
        // Séparateur avec icônes
        Row(
          children: [
            Expanded(child: Divider(color: Colors.yellow.shade400)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade100, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Colors.yellow.shade600, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Lignes générées par l\'IA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.flash_on, color: Colors.yellow.shade600, size: 12),
                ],
              ),
            ),
            Expanded(child: Divider(color: Colors.yellow.shade400)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Réponse générée
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.pink.shade400, Colors.red.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Smooth IA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [Colors.purple.shade600, Colors.pink.shade600],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _responseTypes[_currentTypeIndex].emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayText,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (displayText.length < _generatedResponse.length)
                        Text(
                          '|',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Icon(
                    Icons.copy,
                    color: Colors.blue.shade500,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      // Suppression de la couleur de fond et de la bordure
      // decoration: BoxDecoration(
      //   color: Colors.white.withAlpha(204),
      //   border: Border(
      //     top: BorderSide(color: Colors.white.withAlpha(77)),
      //   ),
      // ),
      child: Row(
        children: [
          // Bouton de sélection de type
          GestureDetector(
            onTap: _cycleResponseType,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF64B5F6)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(128), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _responseTypes[_currentTypeIndex].emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Bouton de génération
          Expanded(
            child: GestureDetector(
              onTap: _messages.isEmpty || _isGenerating ? null : _generateResponse,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _messages.isEmpty || _isGenerating
                      ? [Colors.grey.shade300, Colors.grey.shade400]
                      : [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withAlpha(77)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Générer une réponse ${_responseTypes[_currentTypeIndex].type}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Classes de données adaptées
class Message {
  final String text;
  final MessageType type;
  
  Message({required this.text, required this.type});
}

class ResponseType {
  final String type;
  final String emoji;
  
  ResponseType(this.type, this.emoji);
}

class InputField {
  final MessageType type;
  final int index;
  final int pairIndex;
  
  InputField({
    required this.type,
    required this.index,
    required this.pairIndex,
  });
}

enum MessageType { received, sent, ia }
