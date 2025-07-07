# 🎁 Système de Parrainage Smooth AI

## Vue d'ensemble

Le système de parrainage permet aux utilisateurs premium de gagner des points en parrainant leurs amis. Ces points peuvent être échangés contre des réductions sur leurs abonnements.

## Fonctionnalités

### Pour les utilisateurs
- **Code de parrainage unique** : Généré automatiquement après le premier achat premium
- **Points de parrainage** : 1 point par ami qui devient premium
- **Réductions** : 5% de réduction pour 5 points
- **Partage facile** : Copier/coller et partage direct
- **Suivi en temps réel** : Statistiques et historique

### Pour l'administration
- **Tableau de bord** : Vue d'ensemble des parrainages
- **Statistiques détaillées** : Parrainages par période, points distribués
- **Gestion des codes** : Validation, désactivation, limites d'utilisation

## Architecture technique

### Base de données

#### Tables principales
1. **`referral_codes`** : Codes de parrainage des utilisateurs
2. **`referral_usage`** : Historique des utilisations de codes
3. **`user_referral_points`** : Points de parrainage des utilisateurs
4. **`referral_rewards`** : Récompenses et réductions appliquées

#### Fonctions SQL
- `create_referral_code(device_id)` : Génère un code unique
- `use_referral_code(code, device_id, subscription_type)` : Utilise un code
- `apply_referral_discount(device_id, points, payment_id)` : Applique une réduction
- `get_user_referral_stats(device_id)` : Récupère les statistiques

#### Vues admin
- `referral_admin_stats` : Statistiques pour l'administration
- `referral_rewards_used` : Historique des récompenses

### Application Flutter

#### Services
- **`ReferralService`** : Interface avec l'API Supabase
- **Méthodes principales** :
  - `generateReferralCodeForCurrentUser()`
  - `getCurrentUserReferralStats()`
  - `useReferralCodeForCurrentUser()`
  - `applyReferralDiscountForCurrentUser()`

#### Écrans
- **`ReferralSuccessDialog`** : Affiché après un achat premium réussi
- **`ReferralScreen`** : Page dédiée au parrainage (accessible via menu)

#### Intégration
- **Menu principal** : Lien "Parrainage" ajouté
- **Écran premium** : Section parrainage avec statistiques
- **Flux d'achat** : Dialogue de succès avec code de parrainage

## Flux utilisateur

### 1. Obtention du code
```
Achat premium → Validation → Affichage du code de parrainage
```

### 2. Partage du code
```
Code affiché → Copier/Partager → Amis utilisent le code
```

### 3. Gain de points
```
Ami devient premium → 1 point ajouté → Notification
```

### 4. Utilisation des points
```
5 points accumulés → Demande de réduction → 5% appliqué
```

## Configuration

### Installation de la base de données
```sql
-- Exécuter le script de setup
\i scripts/setup-referral-system.sql

-- Tester le système
\i scripts/test-referral-system.sql
```

### Variables d'environnement
```dart
// Dans ReferralService
static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
static const String _supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
```

## Utilisation

### Pour les développeurs

#### Ajouter le service à un écran
```dart
final referralService = ReferralService();

// Générer un code
String? code = await referralService.generateReferralCodeForCurrentUser();

// Récupérer les stats
Map<String, dynamic>? stats = await referralService.getCurrentUserReferralStats();
```

#### Afficher le dialogue de succès
```dart
showDialog(
  context: context,
  builder: (context) => ReferralSuccessDialog(),
);
```

### Pour les administrateurs

#### Accéder aux statistiques
```sql
-- Vue d'ensemble
SELECT * FROM referral_admin_stats;

-- Récompenses utilisées
SELECT * FROM referral_rewards_used;
```

#### Gérer les codes
```sql
-- Désactiver un code
UPDATE referral_codes SET is_active = FALSE WHERE code = 'CODE123';

-- Voir les utilisations d'un code
SELECT * FROM referral_usage WHERE referral_code_id = (
  SELECT id FROM referral_codes WHERE code = 'CODE123'
);
```

## Sécurité

### Validations
- **Codes uniques** : Génération automatique avec vérification
- **Anti-fraude** : Un device_id ne peut pas utiliser son propre code
- **Limites** : Nombre maximum d'utilisations par code
- **Vérification** : Un device_id ne peut utiliser un code qu'une fois

### Permissions
- **Lecture** : Tous les utilisateurs peuvent voir leurs propres stats
- **Écriture** : Seuls les utilisateurs premium peuvent générer des codes
- **Admin** : Accès complet via l'interface d'administration

## Monitoring

### Métriques importantes
- **Taux de conversion** : Parrainages / Codes générés
- **Points distribués** : Total des points gagnés
- **Réductions utilisées** : Nombre de récompenses réclamées
- **Performance** : Temps de réponse des fonctions SQL

### Alertes
- **Codes inactifs** : Codes non utilisés depuis 30 jours
- **Points expirés** : Points non utilisés depuis 90 jours
- **Erreurs** : Échecs de génération ou d'utilisation de codes

## Maintenance

### Tâches régulières
1. **Nettoyage** : Supprimer les codes inactifs anciens
2. **Optimisation** : Analyser les performances des requêtes
3. **Sauvegarde** : Sauvegarder les données de parrainage
4. **Mise à jour** : Maintenir les dépendances Flutter

### Scripts utiles
```sql
-- Nettoyer les codes inactifs
DELETE FROM referral_codes 
WHERE is_active = FALSE 
AND created_at < NOW() - INTERVAL '90 days';

-- Optimiser les tables
VACUUM ANALYZE referral_codes;
VACUUM ANALYZE referral_usage;
```

## Support

### Problèmes courants
1. **Code non généré** : Vérifier que l'utilisateur est premium
2. **Points non ajoutés** : Vérifier la validité du code utilisé
3. **Réduction non appliquée** : Vérifier le nombre de points disponibles

### Contact
Pour toute question technique : [contact@smoothai.app](mailto:contact@smoothai.app)

---

*Dernière mise à jour : $(date)* 