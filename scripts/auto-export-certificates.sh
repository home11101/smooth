#!/bin/bash

# Script automatisé pour exporter les certificats et les ajouter au repo Match
# Ce script va automatiser le processus d'export des certificats

echo "=== Script Automatisé d'Export des Certificats ==="
echo ""

# Variables
CERT_NAME="iPhone Distribution"
PROFILE_NAME="Smooth_AI_App_Store-2"
MATCH_REPO="git@github.com:home11101/smoothai-ios-certificates.git"
CERT_PASSWORD="smoothai2024"  # Mot de passe pour le certificat

echo "1. Export du certificat depuis Keychain Access..."
echo "   Certificat recherché: $CERT_NAME"
echo ""

# Export automatique du certificat depuis Keychain Access
echo "Export du certificat de distribution..."
security find-identity -v -p codesigning | grep "$CERT_NAME" | head -1 | awk '{print $2}' | xargs -I {} security export -k {} -t identities -f pkcs12 -o distribution_certificate.p12 -P "$CERT_PASSWORD"

if [ ! -f "distribution_certificate.p12" ]; then
    echo "❌ Erreur: Impossible d'exporter le certificat automatiquement"
    echo "   Veuillez l'exporter manuellement depuis Keychain Access"
    echo "   Puis relancez ce script"
    exit 1
fi

echo "✅ Certificat exporté: distribution_certificate.p12"
echo ""

echo "2. Export du provisioning profile..."
echo "   Profile recherché: $PROFILE_NAME"
echo ""

# Tentative d'export automatique du provisioning profile
PROFILE_PATH=$(find ~/Library/MobileDevice/Provisioning\ Profiles -name "*$PROFILE_NAME*" -type f | head -1)

if [ -n "$PROFILE_PATH" ]; then
    cp "$PROFILE_PATH" "Smooth_AI_App_Store-2.mobileprovision"
    echo "✅ Provisioning profile trouvé et copié"
else
    echo "⚠️  Provisioning profile non trouvé automatiquement"
    echo "   Veuillez le télécharger manuellement depuis Xcode"
    echo "   Puis relancez ce script"
    exit 1
fi

echo ""
echo "3. Génération des valeurs Base64..."
echo ""

# Génération Base64
echo "DISTRIBUTION_CERTIFICATE (Base64):"
echo "=================================="
DIST_CERT_B64=$(base64 -i distribution_certificate.p12)
echo "$DIST_CERT_B64"
echo ""

echo "PROVISIONING_PROFILE (Base64):"
echo "=============================="
PROV_PROFILE_B64=$(base64 -i Smooth_AI_App_Store-2.mobileprovision)
echo "$PROV_PROFILE_B64"
echo ""

echo "4. Ajout au repo Match..."
echo ""

# Clone le repo Match si pas déjà fait
if [ ! -d "../smoothai-ios-certificates" ]; then
    cd ..
    git clone "$MATCH_REPO"
    cd smoothai-ios-certificates
else
    cd ../smoothai-ios-certificates
    git pull origin master
fi

# Création de la structure Match
mkdir -p "certs/distribution"
mkdir -p "profiles/distribution"

# Copie des fichiers
cp ../scripts/distribution_certificate.p12 "certs/distribution/"
cp ../scripts/Smooth_AI_App_Store-2.mobileprovision "profiles/distribution/"

# Commit et push
git add .
git commit -m "Add distribution certificate and provisioning profile"
git push origin master

echo "✅ Certificats ajoutés au repo Match"
echo ""

echo "5. Mise à jour des secrets GitHub..."
echo ""
echo "Ajoutez ces secrets dans GitHub Actions:"
echo "========================================"
echo "MATCH_PASSWORD: smoothai2024"
echo "CERTIFICATE_PASSWORD: $CERT_PASSWORD"
echo "APPLE_ID: Henrikanda9@icloud.com"
echo ""

echo "6. Nettoyage..."
echo ""
cd ../scripts
rm -f distribution_certificate.p12 Smooth_AI_App_Store-2.mobileprovision

echo "✅ Script terminé avec succès!"
echo ""
echo "Prochaines étapes:"
echo "1. Ajoutez les secrets dans GitHub Actions"
echo "2. Mettez à jour votre Fastfile pour utiliser Match"
echo "3. Testez votre workflow CI" 