import '../utils/app_theme.dart';
import '../widgets/premium_lock_widget.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../services/pickup_lines_service.dart';
import '../models/pickup_line.dart';

class PickupLineScreen extends StatefulWidget {
  const PickupLineScreen({super.key});

  @override
  _PickupLineScreenState createState() => _PickupLineScreenState();
}

class _PickupLineScreenState extends State<PickupLineScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _sparkleController;
  late AnimationController _buttonController;
  late AnimationController _copyController;
  
  late Animation<double> _shimmerAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _copyAnimation;



  final List<String> coolEmojis = ['🔥', '😎', '💯', '✨', '🚀', '💎', '⚡', '🌟'];
  int currentEmojiIndex = 0;
  
  String displayedText = '';
  String currentMessage = '';
  bool isTyping = false;
  bool _isLoading = true;
  String? _error;

  Timer? typingTimer;
  Timer? emojiTimer;
  Timer? tapTimer;
  int tapCount = 0;

  bool? _isPremium;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(_shimmerController);
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut));
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));
    _copyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _copyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _copyController, curve: Curves.elasticOut));
    
    _fetchNewMessageFromBackend();

    emojiTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
          changeEmoji();
      }
    });

    // Vérifier l'accès premium
    SubscriptionService().isPremium().then((value) {
      if (mounted) setState(() => _isPremium = value);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _sparkleController.dispose();
    _buttonController.dispose();
    _copyController.dispose();
    typingTimer?.cancel();
    emojiTimer?.cancel();
    tapTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNewMessageFromBackend() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
            final PickupLine line = await PickupLinesService.generateRandomPickupLine();
      if (mounted) {
        startTyping(line.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible de générer une phrase.\nVeuillez réessayer.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void startTyping(String message) {
    typingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      currentMessage = message;
      displayedText = '';
      isTyping = true;
    });
    
    int index = 0;
    typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index < message.length) {
        setState(() {
          displayedText = message.substring(0, index + 1);
        });
        index++;
      } else {
        setState(() {
          isTyping = false;
        });
        timer.cancel();
      }
    });
  }

  void changeEmoji() {
    setState(() {
      currentEmojiIndex = (currentEmojiIndex + 1) % coolEmojis.length;
    });
    
    _buttonController.forward().then((_) {
      if (mounted) {
        _buttonController.reverse();
      }
    });
  }

  void generateNewMessage() {
    if (_isLoading) return;
    changeEmoji();
    _fetchNewMessageFromBackend();
  }

  void handleTap() {
    if (_isLoading || _error != null) return;
    tapCount++;
    
    if (tapCount == 1) {
      tapTimer = Timer(const Duration(milliseconds: 300), () {
        tapCount = 0;
      });
    } else if (tapCount == 2) {
      tapTimer?.cancel();
      tapCount = 0;
      copyToClipboard();
    }
  }

  void copyToClipboard() {
    if (currentMessage.isEmpty) return;
    Clipboard.setData(ClipboardData(text: currentMessage));
    _copyController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _copyController.reverse();
        }
      });
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isPremium == false) {
      return PremiumLockOverlay(
        feature: 'pickup_line',
        title: 'Générateur de Phrases d\'Accroche',
        description: 'Générez des phrases d\'accroche personnalisées et créatives pour maximiser vos chances de succès.',
        icon: Icons.bolt,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFf5f7fa),
                  Color(0xFFc3cfe2),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.6, 0),
                        radius: 1.0,
                        colors: [
                          Color(0x4D7877C6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.6, -0.6),
                        radius: 1.0,
                        colors: [
                          Color(0x33FF77C6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.2, 0.6),
                        radius: 1.0,
                        colors: [
                          Color(0x3378DBFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Color(0xFF007AFF),
                                  size: 24,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60,
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildContentArea(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _buttonAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _buttonAnimation.value,
                            child: GestureDetector(
                              onTap: generateNewMessage,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF007AFF),
                                      Color(0xFF0051D5),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x4D007AFF),
                                      blurRadius: 25,
                                      offset: Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    coolEmojis[currentEmojiIndex],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: generateNewMessage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF007AFF),
                                Color(0xFF0051D5),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D007AFF),
                                blurRadius: 25,
                                offset: Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'File-moi un autre',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf5f7fa),
              Color(0xFFc3cfe2),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.6, 0),
                    radius: 1.0,
                    colors: [
                      Color(0x4D7877C6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.6, -0.6),
                    radius: 1.0,
                    colors: [
                      Color(0x33FF77C6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2, 0.6),
                    radius: 1.0,
                    colors: [
                      Color(0x3378DBFF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF007AFF),
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildContentArea(),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonAnimation.value,
                        child: GestureDetector(
                          onTap: generateNewMessage,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF007AFF),
                                  Color(0xFF0051D5),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x4D007AFF),
                                  blurRadius: 25,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                coolEmojis[currentEmojiIndex],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: generateNewMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF007AFF),
                            Color(0xFF0051D5),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D007AFF),
                            blurRadius: 25,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'File-moi un autre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '⚡',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Center(
      child: GestureDetector(
        onTap: handleTap,
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              width: 380,
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x1A87CEFA),
                    Color(0x264096FF),
                    Color(0x330A63FF),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26007AFF),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0x4DFFFFFF),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _shimmerAnimation.value * 380 - 190,
                        top: 0,
                        width: 380,
                        height: 180,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Color(0x4DFFFFFF),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: _buildCardContent(),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: copyToClipboard,
                          child: AnimatedBuilder(
                            animation: _copyAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + _copyAnimation.value * 0.2,
                                child: Transform.rotate(
                                  angle: _copyAnimation.value * 6.28,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _copyAnimation.value > 0.5
                                          ? const Color(0x3322C55E)
                                          : const Color(0x40FFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _copyAnimation.value > 0.5
                                            ? const Color(0x6622C55E)
                                            : const Color(0x4DFFFFFF),
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: _copyAnimation.value > 0.5
                                              ? AppTheme.successGreen
                                              : AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _sparkleAnimation.value * 0.2,
                  child: Transform.rotate(
                    angle: _sparkleAnimation.value * 3.14,
                    child: const Text(
                      '✨',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Smooth IA',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    displayedText,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
                if (isTyping)
                  AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _sparkleController.value > 0.5 ? 1.0 : 0.0,
                        child: Container(
                          width: 2,
                          height: 20,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}