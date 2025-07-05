# Configuration de la Validation Android - Supabase Function

## 📋 Vue d'ensemble

Ce guide explique comment configurer la validation des achats Android dans votre Supabase Function `validate-receipt`.

## 🔧 Prérequis

### 1. Compte Google Play Console
- Accès administrateur à votre compte Google Play Console
- Application publiée ou en mode test

### 2. Service Account
- Créer un compte de service dans Google Cloud Console
- Télécharger la clé privée JSON

## 🚀 Configuration Étape par Étape

### Étape 1: Créer un Service Account

1. **Accéder à Google Cloud Console**
   ```
   https://console.cloud.google.com/
   ```

2. **Sélectionner votre projet**
   - Choisir le projet lié à votre application Android

3. **Créer un Service Account**
   - Aller dans "IAM & Admin" > "Service Accounts"
   - Cliquer sur "Create Service Account"
   - Nom: `supabase-validate-receipt`
   - Description: `Service account for Supabase receipt validation`

4. **Attribuer les rôles**
   - `Android Publisher API` > `Android Publisher`
   - Permissions nécessaires pour valider les achats

### Étape 2: Télécharger la Clé Privée

1. **Créer une clé**
   - Dans le service account créé, cliquer sur "Keys"
   - "Add Key" > "Create new key"
   - Format: JSON
   - Télécharger le fichier

2. **Contenu du fichier JSON**
   ```json
   {
     "type": "service_account",
     "project_id": "your-project-id",
     "private_key_id": "key-id",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "service-account@project-id.iam.gserviceaccount.com",
     "client_id": "client-id",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
     "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/service-account%40project-id.iam.gserviceaccount.com"
   }
   ```

### Étape 3: Configurer Supabase

1. **Ajouter la variable d'environnement**
   ```bash
   supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
   ```

2. **Alternative: Interface Supabase**
   - Aller dans votre projet Supabase
   - Settings > API > Environment Variables
   - Ajouter `GOOGLE_SERVICE_ACCOUNT_JSON`
   - Coller le contenu JSON complet

### Étape 4: Mettre à Jour le Code Flutter

1. **Mettre à jour le package name**
   Dans `lib/services/in_app_purchase_service.dart`:
   ```dart
   requestBody['packageName'] = 'com.votre.package.name'; // Votre vrai package name
   ```

2. **Vérifier les IDs de produits**
   ```dart
   static const String premiumMonthly = 'premium_monthly';
   static const String premiumYearly = 'premium_yearly';
   ```

## 🔍 Test de la Validation

### Test avec un Achat Réel

1. **Créer un produit de test**
   - Google Play Console > Monetization > Products
   - Créer un produit avec l'ID `premium_monthly`

2. **Tester l'achat**
   - Utiliser un compte de test
   - Effectuer un achat
   - Vérifier les logs Supabase

### Test avec des Données Mock

```dart
// Dans votre code de test
final mockPurchase = PurchaseDetails(
  productID: 'premium_monthly',
  verificationData: PurchaseVerificationData(
    serverVerificationData: 'mock-purchase-token',
    localVerificationData: 'mock-local-data',
  ),
);
```

## 🐛 Dépannage

### Erreurs Communes

1. **"Configuration Google Service Account manquante"**
   - Vérifier que `GOOGLE_SERVICE_ACCOUNT_JSON` est défini
   - Vérifier le format JSON

2. **"Impossible d'obtenir le token d'accès Google"**
   - Vérifier les permissions du service account
   - Vérifier que l'API Android Publisher est activée

3. **"Erreur API Google Play: 404"**
   - Vérifier le package name
   - Vérifier que l'application est publiée

### Logs de Debug

Dans Supabase Function, ajoutez des logs :
```typescript
console.log('Package name:', packageName);
console.log('Product ID:', productId);
console.log('Purchase token:', purchaseToken);
```

## 🔒 Sécurité

### Bonnes Pratiques

1. **Ne jamais exposer la clé privée**
   - Utiliser les variables d'environnement Supabase
   - Ne pas commiter la clé dans le code

2. **Limiter les permissions**
   - Donner seulement les permissions nécessaires
   - Utiliser le principe du moindre privilège

3. **Valider côté serveur**
   - Toujours valider les achats côté serveur
   - Ne pas faire confiance aux données client

### Rotation des Clés

1. **Créer une nouvelle clé**
   - Google Cloud Console > Service Accounts
   - Ajouter une nouvelle clé

2. **Mettre à jour Supabase**
   ```bash
   supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='nouveau-json'
   ```

3. **Supprimer l'ancienne clé**
   - Après vérification que tout fonctionne

## 📊 Monitoring

### Métriques à Surveiller

1. **Taux de succès de validation**
   - Logs Supabase Function
   - Métriques Google Play Console

2. **Temps de réponse**
   - Performance de la validation
   - Optimisation si nécessaire

3. **Erreurs de validation**
   - Types d'erreurs fréquentes
   - Actions correctives

### Alertes

Configurer des alertes pour :
- Taux d'erreur élevé
- Temps de réponse anormal
- Échecs de validation répétés

## 🔄 Mise à Jour

### Quand Mettre à Jour

1. **Nouveaux produits**
   - Ajouter les IDs dans le code
   - Tester la validation

2. **Changements d'API Google**
   - Surveiller les changements
   - Mettre à jour si nécessaire

3. **Nouvelles fonctionnalités**
   - Abonnements familiaux
   - Offres promotionnelles

## 📞 Support

### Ressources Utiles

1. **Documentation Google Play**
   - [Android Publisher API](https://developers.google.com/android-publisher)
   - [In-App Billing](https://developer.android.com/google/play/billing)

2. **Documentation Supabase**
   - [Edge Functions](https://supabase.com/docs/guides/functions)
   - [Environment Variables](https://supabase.com/docs/guides/functions/secrets)

3. **Support Flutter**
   - [In-App Purchase Plugin](https://pub.dev/packages/in_app_purchase)
   - [Android Configuration](https://developer.android.com/google/play/billing/integrate)

### Contact

Pour des questions spécifiques :
- Issues GitHub du projet
- Support Supabase
- Documentation Flutter officielle 