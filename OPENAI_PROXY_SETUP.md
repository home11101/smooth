# Configuration OpenAI Proxy avec Supabase Edge Functions

## 🎯 Objectif
Gérer l'API key OpenAI côté serveur pour éviter de redéployer l'app à chaque changement.

## 📋 Modifications Apportées

### 1. Nouvelle Supabase Edge Function
- **Fichier**: `supabase/functions/openai-proxy/index.ts`
- **Rôle**: Proxy qui cache l'API key OpenAI côté serveur
- **URL**: `https://oahmneimzzfahkuervii.supabase.co/functions/v1/openai-proxy`

### 2. Services Modifiés
- **`lib/services/openai_service.dart`**: URL changée vers le proxy
- **`lib/services/coaching_service.dart`**: URL changée vers le proxy
- **`lib/utils/constants.dart`**: API key supprimée pour sécurité

### 3. Authentification
- Utilise maintenant `supabaseAnonKey` au lieu de `openAIApiKey`
- L'API key OpenAI est stockée dans les variables d'environnement Supabase

## 🚀 Déploiement

### Étape 1: Installer Supabase CLI
```bash
npm install -g supabase
```

### Étape 2: Se connecter à Supabase
```bash
supabase login
```

### Étape 3: Déployer la fonction
```bash
chmod +x deploy-openai-proxy.sh
./deploy-openai-proxy.sh
```

### Étape 4: Configurer l'API key OpenAI
```bash
supabase secrets set OPENAI_API_KEY='votre-vraie-api-key-openai'
```

## 🔧 Avantages

### ✅ Sécurité
- API key jamais exposée dans le code client
- Gestion centralisée des clés
- Rotation facile des clés

### ✅ Flexibilité
- Changement d'API key sans redéploiement
- Monitoring des appels API
- Rate limiting côté serveur

### ✅ Maintenance
- Une seule source de vérité pour l'API key
- Logs centralisés
- Gestion des erreurs améliorée

## 🐛 Dépannage

### Erreur "OPENAI_API_KEY not configured"
```bash
# Vérifier que la variable est définie
supabase secrets list

# Redéfinir si nécessaire
supabase secrets set OPENAI_API_KEY='votre-api-key'
```

### Erreur CORS
- La fonction inclut déjà les headers CORS nécessaires
- Vérifier que l'URL est correcte dans le code

### Erreur 500
- Vérifier les logs Supabase: `supabase functions logs openai-proxy`
- S'assurer que l'API key OpenAI est valide

## 📊 Monitoring

### Logs Supabase
```bash
# Voir les logs en temps réel
supabase functions logs openai-proxy --follow

# Voir les logs récents
supabase functions logs openai-proxy
```

### Métriques à surveiller
- Nombre d'appels par minute
- Taux d'erreur
- Temps de réponse
- Utilisation de l'API OpenAI

## 🔄 Mise à Jour de l'API Key

### Méthode 1: Via CLI
```bash
supabase secrets set OPENAI_API_KEY='nouvelle-api-key'
```

### Méthode 2: Via Dashboard Supabase
1. Aller dans votre projet Supabase
2. Settings > API > Environment Variables
3. Modifier `OPENAI_API_KEY`

## 🚨 Important

- **Ne jamais commiter l'API key** dans le code
- **Toujours utiliser les variables d'environnement** Supabase
- **Tester après chaque changement** d'API key
- **Monitorer les coûts** OpenAI régulièrement

## 📞 Support

En cas de problème :
1. Vérifier les logs Supabase
2. Tester l'API key directement avec OpenAI
3. Vérifier la configuration CORS
4. Contacter le support si nécessaire 