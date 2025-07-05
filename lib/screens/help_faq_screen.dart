import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & FAQ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions fréquentes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const SizedBox(height: 20),
            ..._buildFaqItems(),
            const SizedBox(height: 30),
            _buildContactCard(context),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => launchUrlString('https://smooth-pages.vercel.app/faq.html'),
                child: const Text(
                  'Voir la FAQ complète en ligne',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFaqItems() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'Comment utiliser cette application ?',
        'reponse': 'Smooth AI est conçu pour vous aider à améliorer vos compétences en séduction. Utilisez les différentes fonctionnalités pour analyser vos conversations et obtenir des conseils personnalisés.'
      },
      {
        'question': 'Comment analyser une conversation ?',
        'reponse': 'Allez dans l\'écran d\'analyse et importez une capture d\'écran de votre conversation. Notre IA analysera le contenu et vous fournira des retours détaillés.'
      },
      {
        'question': 'Comment fonctionne le coaching ?',
        'reponse': 'Notre coach IA analyse vos messages et vous donne des conseils en temps réel pour améliorer vos interactions. Posez des questions spécifiques pour obtenir des conseils personnalisés.'
      },
      {
        'question': 'Comment mettre à niveau vers la version Premium ?',
        'reponse': 'Allez dans le menu et sélectionnez "Mettre à niveau". Choisissez l\'abonnement qui vous convient pour débloquer toutes les fonctionnalités avancées.'
      },
    ];

    return faqs.map((faq) => _buildFaqItem(faq['question']!, faq['reponse']!)).toList();
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Besoin d\'aide supplémentaire ?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notre équipe est là pour vous aider. Contactez-nous pour toute question ou problème technique.',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Ferme l'écran FAQ et ouvre l'email
                Navigator.pop(context); // Ferme l'écran FAQ
                // Ouvre directement l'email sans passer par le menu
                final emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'contact@smoothai.com',
                  query: 'subject=Contact depuis l\'application Smooth AI',
                );
                launchUrlString(emailLaunchUri.toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Contactez-nous'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
