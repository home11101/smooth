# Guide pour obtenir les certificats iOS

## 1. Certificat de Distribution (.p12)

1. Allez sur [Apple Developer](https://developer.apple.com/account/resources/certificates/list)
2. Cliquez sur "+" pour créer un nouveau certificat
3. Sélectionnez "Apple Distribution"
4. Téléchargez le certificat
5. Double-cliquez pour l'installer dans Keychain Access
6. Exportez en .p12 avec mot de passe

## 2. Convertir en base64

```bash
base64 -i votre_certificat.p12
```

## 3. Profil de provisionnement

1. Allez sur [Apple Developer > Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Créez un profil "App Store" pour votre app
3. Téléchargez le .mobileprovision
4. Convertissez en base64 :

```bash
base64 -i votre_profil.mobileprovision
```

## 4. Variables Codemagic à ajouter

```
BUILD_CERTIFICATE_BASE64 = [Résultat de l'étape 2]
BUILD_CERTIFICATE_PASSWORD = [Mot de passe choisi]
PROVISIONING_PROFILE_BASE64 = [Résultat de l'étape 3]
```

## 5. Mettre à jour exportOptions.plist

Remplacez dans `ios/exportOptions.plist` :
- `YOUR_TEAM_ID` par votre Team ID
- `YOUR_PROVISIONING_PROFILE_NAME` par le nom de votre profil 