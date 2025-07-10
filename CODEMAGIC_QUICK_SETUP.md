# 🚀 Configuration CodeMagic - Guide Rapide

## ✅ Variables corrigées pour CodeMagic

Les noms de variables ont été corrigés pour respecter les règles CodeMagic.

## 🔑 Variables à configurer dans CodeMagic

### Variables obligatoires :

1. **APPSTORE_CONNECT_API_KEY_ID**: `4V6GWRQFC9`
2. **APPSTORE_CONNECT_ISSUER_ID**: `bbd1db28-6a57-409f-860f-cfc657430d67`
3. **APPSTORE_CONNECT_API_KEY**: 
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgkMgjuZYt4R2t4CwX
PsxArZs2EBzkuWLLW67g3rZDxOugCgYIKoZIzj0DAQehRANCAATXyLEQeX6CCDmI
0UO8xFiFbWaJWz1okKrDRGsy2VMDJLHrUaxWxJD49PVB+IyOtV5Aot5/9DBEBy0d
eNUULbC8
-----END PRIVATE KEY-----
```

### Variables optionnelles :

4. **MATCH_PASSWORD**: Mot de passe de votre repo Match privé
5. **APPLE_ID**: Votre Apple ID
6. **APP_SPECIFIC_PASSWORD**: Mot de passe spécifique à l'application

## 📋 Étapes rapides

### 1. Dans CodeMagic
1. Allez sur https://codemagic.io/apps
2. Connectez votre repo GitHub
3. Dans les paramètres du projet → "Environment variables"
4. Ajoutez les 3 variables obligatoires ci-dessus
5. Marquez-les comme "Secure"

### 2. Déploiement
1. Push vos changements vers GitHub
2. Lancez le workflow `ios-workflow`
3. Suivez les logs

## ✅ Vérification

Toutes les variables respectent maintenant les règles CodeMagic :
- ✅ Seulement des lettres, chiffres et `_`
- ✅ Ne commencent pas par un chiffre
- ✅ En majuscules

## 🎯 Résultat

Votre app devrait maintenant se déployer correctement sur CodeMagic ! 