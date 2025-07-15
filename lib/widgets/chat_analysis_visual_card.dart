import 'package:flutter/material.dart';
import '../models/chat_analysis_report.dart';
import 'dart:math';

class ChatAnalysisVisualCard extends StatelessWidget {
  final ChatAnalysisReport report;
  const ChatAnalysisVisualCard({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Analyse de Chat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
            children: [
              Expanded(
                child: _messagesBar(
                  label: 'Vous',
                  value: report.nombreMessagesVous,
                  color: Colors.blueAccent,
                        background: Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _messagesBar(
                  label: 'Eux',
                  value: report.nombreMessagesEux,
                  color: Colors.pinkAccent,
                        background: Colors.transparent,
                ),
              ),
            ],
          ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
            children: [
              Expanded(
                child: _interestCircle(
                  label: 'Intérêt (Vous)',
                  percent: report.niveauInteretVous,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _interestCircle(
                  label: 'Intérêt (Eux)',
                  percent: report.niveauInteretEux,
                  color: Colors.pinkAccent,
                ),
              ),
            ],
          ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
            children: [
              Expanded(
                child: _keywordsSection(
                  label: 'Mots significatifs (Vous)',
                  keywords: report.motsSignificatifsVous,
                        color: Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _keywordsSection(
                  label: 'Mots significatifs (Eux)',
                  keywords: report.motsSignificatifsEux,
                        color: Colors.transparent,
                ),
              ),
            ],
          ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
            children: [
              Expanded(
                child: _listSection(
                        label: 'Red flag',
                  items: report.alertesRouges,
                  icon: Icons.warning,
                        color: Colors.transparent,
                  iconColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _listSection(
                        label: 'Green flag',
                  items: report.signauxPositifs,
                  icon: Icons.thumb_up,
                        color: Colors.transparent,
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _attachmentStyle(
                        label: 'Tonalité (Vous)',
                        style: report.styleAttachementVous,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _attachmentStyle(
                        label: 'Tonalité (Eux)',
                        style: report.styleAttachementEux,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.purple, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Score de compatibilité',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blueGrey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${report.scoreCompatibilite}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messagesBar({required String label, required int value, required Color color, Color background = Colors.transparent}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (value / 20).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withAlpha(38),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 6),
          Text('$value messages', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _interestCircle({required String label, required int percent, required Color color}) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 8,
                backgroundColor: color.withAlpha(38),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _keywordsSection({required String label, required List<String> keywords, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: keywords.map((k) => Chip(label: Text(k))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _listSection({required String label, required List<String> items, required IconData icon, required Color color, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: iconColor)),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((e) => Text('• $e', style: const TextStyle(fontSize: 13))).toList(),
        ],
      ),
    );
  }

  Widget _attachmentStyle({required String label, required String style, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color.withAlpha(20))),
          const SizedBox(height: 6),
          Chip(
            label: Text(style, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: color.withAlpha(38),
          ),
        ],
      ),
    );
  }
} 