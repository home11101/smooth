# Configuration CI/CD iOS avec Fastlane + Match

## Problème résolu

Le build échouait avec les erreurs suivantes :
1. **Problème de keychain** : Mot de passe non spécifié pour le keychain
2. **Problème de provisioning profiles** : Les pods ne supportent pas les provisioning profiles manuels

## Solutions implémentées

### 1. Configuration du keychain pour CI

Ajout de `setup_ci_keychain` dans les lanes Fastlane :
```ruby
setup_ci_keychain(
  keychain_name: "login",
  keychain_password: ENV["KEYCHAIN_PASSWORD"] || "password"
)
```

### 2. Configuration Match avec keychain

Ajout du paramètre `keychain_password` à Match :
```ruby
match(type: "appstore", api_key: api_key, readonly: true, keychain_password: ENV["KEYCHAIN_PASSWORD"] || "password")
```

### 3. Configuration du keychain dans GitHub Actions

```yaml
- name: Setup keychain for code signing
  run: |
    security create-keychain -p "password" login.keychain
    security list-keychains -s login.keychain
    security default-keychain -s login.keychain
    security unlock-keychain -p "password" login.keychain
    security set-keychain-settings -t 3600 -l ~/Library/Keychains/login.keychain-db
```

### 4. Variable d'environnement KEYCHAIN_PASSWORD

Ajout de `KEYCHAIN_PASSWORD: "password"` dans les variables d'environnement du workflow.

## Secrets GitHub requis

Assurez-vous d'avoir configuré ces secrets dans votre repository GitHub :

### Secrets existants (à conserver)
- `APPLE_ID` : Votre Apple ID
- `APP_SPECIFIC_PASSWORD` : Mot de passe spécifique à l'application
- `APPSTORECONNECT_API_KEY_KEY_ID` : ID de la clé API App Store Connect
- `APPSTORECONNECT_API_KEY_ISSUER_ID` : ID de l'émetteur de la clé API
- `APPSTORECONNECT_API_KEY_KEY` : Contenu de la clé API App Store Connect
- `MATCH_PASSWORD` : Mot de passe du repo Match privé

### Nouveaux secrets (optionnels)
- `KEYCHAIN_PASSWORD` : Mot de passe du keychain (par défaut "password")

## Lanes Fastlane disponibles

### `build_and_upload`
Lane principale qui :
1. Configure l'environnement CI (`setup_ci`)
2. Build l'application (`build`)
3. Upload vers App Store Connect (`upload`)

### `setup_ci`
Configure l'environnement pour CI :
- Nettoie les artefacts de build
- Installe les pods
- Configure le keychain

### `build`
Build l'application avec code signing manuel

### `upload`
Upload l'IPA vers App Store Connect

### `debug_signing`
Lane de debug pour vérifier la configuration de code signing

## Utilisation

### Dans GitHub Actions
Le workflow utilise automatiquement `fastlane build_and_upload`

### En local
```bash
cd ios
fastlane build_and_upload
```

### Debug
```bash
cd ios
fastlane debug_signing
```

## Notes importantes

1. **Keychain** : Le keychain est configuré avec le mot de passe "password" par défaut
2. **Match** : Utilise le repo privé configuré avec le mot de passe dans `MATCH_PASSWORD`
3. **Code signing** : Configuration manuelle avec le certificat de distribution
4. **Pods** : Les pods utilisent automatiquement le code signing automatique

## Troubleshooting

### Erreur de keychain
Si vous avez des erreurs de keychain, vérifiez que :
- La variable `KEYCHAIN_PASSWORD` est définie
- Le keychain est correctement configuré dans le workflow

### Erreur de provisioning profile
Si vous avez des erreurs de provisioning profile :
- Vérifiez que Match est correctement configuré
- Vérifiez que le repo Match privé est accessible
- Vérifiez que le mot de passe Match est correct

### Erreur de certificat
Si vous avez des erreurs de certificat :
- Vérifiez que le certificat de distribution est valide
- Vérifiez que le certificat correspond au Team ID
- Vérifiez que Match a correctement installé le certificat 