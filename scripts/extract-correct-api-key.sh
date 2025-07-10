#!/bin/bash

# Script pour extraire le contenu de la clé API correcte pour CodeMagic
echo "🔑 Extraction du contenu de la clé API correcte..."

if [ -f "ios/AuthKey_4V6GWRQFC9.p8" ]; then
    echo "📄 Contenu de votre clé API pour CodeMagic :"
    echo ""
    echo "=== APPSTORECONNECT_API_KEY_KEY ==="
    cat ios/AuthKey_4V6GWRQFC9.p8
    echo ""
    echo "=== FIN DU CONTENU ==="
    echo ""
    echo "📋 Copiez ce contenu dans la variable APPSTORECONNECT_API_KEY_KEY dans CodeMagic"
    echo ""
    echo "🔑 Variables à configurer dans CodeMagic :"
echo "- APPSTORE_CONNECT_API_KEY_ID: 4V6GWRQFC9"
echo "- APPSTORE_CONNECT_ISSUER_ID: bbd1db28-6a57-409f-860f-cfc657430d67"
echo "- APPSTORE_CONNECT_API_KEY: [Contenu ci-dessus]"
    echo "- MATCH_PASSWORD: [Mot de passe de votre repo Match]"
    echo "- APPLE_ID: [Votre Apple ID]"
    echo "- APP_SPECIFIC_PASSWORD: [Mot de passe spécifique à l'app]"
    echo ""
    echo "⚠️  IMPORTANT : Ne partagez jamais ce contenu publiquement !"
    echo ""
    echo "✅ Configuration CodeMagic :"
    echo "1. Allez sur https://codemagic.io/apps"
    echo "2. Connectez votre repo GitHub"
    echo "3. Configurez les variables d'environnement ci-dessus"
    echo "4. Utilisez le workflow 'ios-workflow'"
else
    echo "❌ Fichier AuthKey_4V6GWRQFC9.p8 non trouvé dans ios/"
    echo "Veuillez placer votre fichier .p8 dans le dossier ios/"
    exit 1
fi 