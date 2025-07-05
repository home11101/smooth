import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  Map<String, bool> _notificationSettings = {};
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _hasPermission = await _subscriptionService.checkNotificationPermissions();
      _notificationSettings = await _subscriptionService.loadNotificationSettings();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() {
      _notificationSettings[key] = value;
    });

    try {
      await _subscriptionService.saveNotificationSettings(_notificationSettings);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPermissionSection(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasPermission ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasPermission ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasPermission ? Icons.notifications_active : Icons.notifications_off,
            color: _hasPermission ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hasPermission ? 'Notifications activées' : 'Notifications désactivées',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _hasPermission ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Types de Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          'renewal_reminders',
          'Rappels de renouvellement',
          'Avant l\'expiration de votre abonnement',
        ),
        _buildSettingTile(
          'trial_reminders',
          'Rappels d\'essai gratuit',
          'Avant la fin de votre essai gratuit',
        ),
        _buildSettingTile(
          'feature_updates',
          'Nouvelles fonctionnalités',
          'Nouvelles fonctionnalités disponibles',
        ),
      ],
    );
  }

  Widget _buildSettingTile(String key, String title, String subtitle) {
    final isEnabled = _notificationSettings[key] ?? true;
    
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: isEnabled && _hasPermission,
      onChanged: _hasPermission 
          ? (value) => _updateSetting(key, value)
          : null,
      activeColor: AppTheme.primaryBlue,
    );
  }
} 