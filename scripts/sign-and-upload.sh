#!/bin/bash

echo "🚀 Script de signature et upload local pour Smooth AI"
echo "=================================================="

# Vérifier que les fichiers nécessaires existent
if [ ! -f "ios/exportOptions.plist" ]; then
    echo "❌ Fichier exportOptions.plist manquant"
    exit 1
fi

# Nettoyer et construire
echo "📱 Construction de l'app iOS..."
cd ios
flutter build ios --release --no-codesign

# Archiver avec signature automatique
echo "📦 Création de l'archive..."
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath Runner.xcarchive \
           -destination generic/platform=iOS \
           -allowProvisioningUpdates \
           -allowProvisioningDeviceRegistration \
           DEVELOPMENT_TEAM="7BHY8D9X9V" \
           CODE_SIGN_STYLE="Automatic" \
           archive

# Exporter IPA
echo "📤 Export de l'IPA..."
xcodebuild -exportArchive \
           -archivePath Runner.xcarchive \
           -exportPath ./build/ios/ipa \
           -exportOptionsPlist exportOptions.plist

# Vérifier que l'IPA existe
if [ -f "build/ios/ipa/Runner.ipa" ]; then
    echo "✅ IPA créé avec succès : build/ios/ipa/Runner.ipa"
    echo "📏 Taille : $(ls -lh build/ios/ipa/Runner.ipa | awk '{print $5}')"
    
    echo ""
    echo "🎯 Pour uploader sur App Store Connect :"
    echo "1. Ouvre Xcode"
    echo "2. Window → Organizer"
    echo "3. Clique sur '+' → 'Add an Archive'"
    echo "4. Sélectionne : $(pwd)/build/ios/ipa/Runner.ipa"
    echo "5. Suis les étapes pour uploader"
    
else
    echo "❌ Erreur : IPA non créé"
    exit 1
fi

echo ""
echo "✨ Script terminé !" 