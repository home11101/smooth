# Guide de Déploiement CodeMagic

## 🚀 Configuration pour CodeMagic

### 1. Préparation locale

Exécutez le script de configuration :
```bash
./scripts/setup-codemagic-certs.sh
```

### 2. Configuration dans CodeMagic

#### Variables d'environnement à configurer :

1. **APPSTORECONNECT_API_KEY_KEY_ID**: `4V6GWRQFC9`
2. **APPSTORECONNECT_API_KEY_ISSUER_ID**: `bbd1db28-6a57-409f-860f-cfc657430d67`
3. **APPSTORECONNECT_API_KEY_KEY**: Contenu de votre clé privée (fichier .p8)
4. **MATCH_PASSWORD**: Mot de passe de votre repo Match privé
5. **APPLE_ID**: Votre Apple ID
6. **APP_SPECIFIC_PASSWORD**: Mot de passe spécifique à l'application

#### Comment obtenir ces valeurs :

1. **Clé API App Store Connect** :
   - Allez sur https://appstoreconnect.apple.com/access/api
   - Créez une nouvelle clé avec les permissions "App Manager"
   - Téléchargez le fichier .p8
   - Le contenu du fichier .p8 = `APPSTORECONNECT_API_KEY_KEY`
   - L'ID de la clé = `APPSTORECONNECT_API_KEY_KEY_ID`
   - L'ID de l'émetteur = `APPSTORECONNECT_API_KEY_ISSUER_ID`

2. **Mot de passe spécifique à l'app** :
   - Allez sur https://appleid.apple.com/account/manage
   - Section "Sécurité" > "Mots de passe spécifiques aux applications"
   - Créez un nouveau mot de passe pour "App Store Connect"

### 3. Configuration du repo Match (optionnel)

Si vous utilisez Match pour la gestion des certificats :

1. Créez un repo privé sur GitHub
2. Configurez Match dans `ios/fastlane/Matchfile`
3. Ajoutez le mot de passe du repo dans `MATCH_PASSWORD`

### 4. Déploiement

1. Connectez votre repo GitHub à CodeMagic
2. Configurez les variables d'environnement
3. Lancez le workflow `ios-workflow`

## 🔧 Résolution des problèmes

### Problème : Fichier .p8 non trouvé

**Solution** :
1. Vérifiez que le fichier `AuthKey_P4JVQNHTAR.p8` est dans le dossier `ios/`
2. Exécutez le script de configuration : `./scripts/setup-codemagic-certs.sh`

### Problème : Erreur de code signing

**Solution** :
1. Vérifiez que le certificat de distribution est valide
2. Vérifiez que le Team ID est correct : `7BHY8D9X9V`
3. Vérifiez que le Bundle ID est correct : `com.henrikanda.smoothai`

### Problème : Erreur de provisioning profile

**Solution** :
1. Vérifiez que Match est correctement configuré
2. Vérifiez que le repo Match privé est accessible
3. Vérifiez que le mot de passe Match est correct

## 📁 Structure des fichiers

```
ios/
├── AuthKey_P4JVQNHTAR.p8          # Clé API App Store Connect
├── api_key.json                    # Configuration API
├── fastlane/
│   ├── Fastfile                   # Configuration Fastlane
│   └── Matchfile                  # Configuration Match
└── certs/                         # Certificats (créé par le script)
    └── distribution_certificate.p12 # Certificat de distribution
```

## 🎯 Workflow CodeMagic

Le workflow `ios-workflow` dans `codemagic.yaml` :

1. **Setup** : Configure l'environnement et les certificats
2. **Build** : Compile l'application Flutter
3. **Archive** : Crée l'archive iOS avec Fastlane
4. **Upload** : Upload vers App Store Connect

## 📱 Résultat

Après un déploiement réussi :
- L'IPA sera disponible dans les artefacts CodeMagic
- L'app sera uploadée vers App Store Connect
- L'app sera disponible pour TestFlight (si activé)

## 🔄 Mise à jour

Pour mettre à jour la configuration :

1. Modifiez `codemagic.yaml` si nécessaire
2. Mettez à jour les variables d'environnement dans CodeMagic
3. Relancez le workflow

## 📞 Support

En cas de problème :
1. Vérifiez les logs CodeMagic
2. Vérifiez la configuration des certificats
3. Vérifiez les variables d'environnement
4. Consultez la documentation CodeMagic 