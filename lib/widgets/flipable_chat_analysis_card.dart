import 'package:flutter/material.dart';
import '../models/chat_analysis_report.dart';
import 'chat_analysis_visual_card.dart';
import 'dart:ui';
import 'dart:typed_data';

class FlipableChatAnalysisCard extends StatefulWidget {
  final ChatAnalysisReport report;
  final Uint8List? uploadedImageBytes;
  final GlobalKey? repaintBoundaryKey;
  const FlipableChatAnalysisCard({Key? key, required this.report, required this.uploadedImageBytes, this.repaintBoundaryKey}) : super(key: key);

  @override
  State<FlipableChatAnalysisCard> createState() => _FlipableChatAnalysisCardState();
}

class _FlipableChatAnalysisCardState extends State<FlipableChatAnalysisCard> with TickerProviderStateMixin {
  bool isFlipped = false;
  late AnimationController _controller;
  late AnimationController _gradientController;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _gradientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _gradientColor1 = ColorTween(
      begin: const Color(0xFFa18cd1),
      end: const Color(0xFFfbc2eb),
    ).animate(_gradientController);
    _gradientColor2 = ColorTween(
      begin: const Color(0xFFfad0c4),
      end: const Color(0xFFffd6e0),
    ).animate(_gradientController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() {
      isFlipped = !isFlipped;
      if (isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _gradientController]),
          builder: (context, child) {
            final angle = _controller.value * 3.1416;
            final isUnder = (angle > 3.1416 / 2);
            final scale = _isHovered ? 1.07 : 1.0;
            final translateZ = _isHovered ? 24.0 : 0.0;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle)
                ..scale(scale, scale, scale)
                ..translate(0.0, 0.0, translateZ),
              child: isUnder
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.1416),
                      child: _buildBack(context),
                    )
                  : _buildFront(context),
            );
          },
        ),
      ),
    );
    if (widget.repaintBoundaryKey != null) {
      cardContent = RepaintBoundary(
        key: widget.repaintBoundaryKey,
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildFront(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              width: 530,
              height: 520,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientColor1.value ?? const Color(0xFFa18cd1),
                    _gradientColor2.value ?? const Color(0xFFfad0c4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: Colors.white.withAlpha(89),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ChatAnalysisVisualCard(report: widget.report),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: widget.uploadedImageBytes != null
          ? Image.memory(
              widget.uploadedImageBytes!,
              fit: BoxFit.cover,
              width: 530,
              height: 520,
            )
          : Center(
              child: Text('Aucune image sélectionnée', style: Theme.of(context).textTheme.titleMedium),
            ),
    );
  }
} 