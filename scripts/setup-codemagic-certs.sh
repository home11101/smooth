#!/bin/bash

# Script pour préparer les certificats pour CodeMagic
# Ce script doit être exécuté localement pour créer les certificats nécessaires

echo "🔧 Configuration des certificats pour CodeMagic..."

# Créer le dossier des certificats
mkdir -p ios/certs

# Copier le fichier .p8 existant
if [ -f "ios/AuthKey_4V6GWRQFC9.p8" ]; then
    echo "📁 Copie du fichier .p8 existant..."
    cp ios/AuthKey_4V6GWRQFC9.p8 ios/certs/
    echo "✅ Fichier .p8 copié avec succès"
else
    echo "❌ Fichier .p8 non trouvé dans ios/"
    echo "Veuillez placer votre fichier .p8 dans le dossier ios/"
    exit 1
fi

# Instructions pour les certificats de distribution
echo ""
echo "📋 Instructions pour les certificats de distribution :"
echo "1. Allez sur https://developer.apple.com/account/"
echo "2. Téléchargez votre certificat de distribution (.p12)"
echo "3. Placez-le dans ios/certs/distribution_certificate.p12"
echo "4. Si vous avez un mot de passe pour le certificat, notez-le"
echo ""
echo "🔑 Variables d'environnement à configurer dans CodeMagic :"
echo "- APPSTORECONNECT_API_KEY_KEY_ID: 4V6GWRQFC9"
echo "- APPSTORECONNECT_API_KEY_ISSUER_ID: bbd1db28-6a57-409f-860f-cfc657430d67"
echo "- APPSTORECONNECT_API_KEY_KEY: [Contenu de votre clé privée]"
echo "- MATCH_PASSWORD: [Mot de passe de votre repo Match]"
echo "- APPLE_ID: [Votre Apple ID]"
echo "- APP_SPECIFIC_PASSWORD: [Mot de passe spécifique à l'app]"
echo ""
echo "✅ Configuration terminée !" 