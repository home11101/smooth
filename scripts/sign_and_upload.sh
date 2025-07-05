#!/bin/bash

# Script pour signer l'archive iOS et l'uploader vers App Store Connect
# Usage: ./scripts/sign_and_upload.sh

echo "🚀 Script de signature et upload iOS"
echo "=================================="

# Vérifier que l'archive existe
ARCHIVE_PATH="ios/build/Runner.xcarchive"
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive non trouvée: $ARCHIVE_PATH"
    echo "📥 Téléchargez d'abord l'artifact depuis GitHub Actions"
    exit 1
fi

echo "✅ Archive trouvée: $ARCHIVE_PATH"

# Signer et exporter pour App Store
echo "🔐 Signature de l'archive..."
cd ios

xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/AppStore \
    -exportOptionsPlist exportOptions.plist

if [ $? -eq 0 ]; then
    echo "✅ Archive signée avec succès!"
    echo "📦 Package créé: build/AppStore/Runner.ipa"
    echo ""
    echo "📱 Prochaines étapes:"
    echo "1. Ouvrir Xcode Organizer"
    echo "2. Cliquer sur 'Distribute App'"
    echo "3. Sélectionner 'App Store Connect'"
    echo "4. Choisir le fichier: ios/build/AppStore/Runner.ipa"
    echo "5. Suivre les étapes d'upload"
else
    echo "❌ Erreur lors de la signature"
    exit 1
fi 