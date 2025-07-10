#!/bin/bash

# Script pour extraire le contenu de la clé API pour CodeMagic
echo "🔑 Extraction du contenu de la clé API..."

if [ -f "ios/AuthKey_P4JVQNHTAR.p8" ]; then
    echo "📄 Contenu de votre clé API pour CodeMagic :"
    echo ""
    echo "=== APPSTORECONNECT_API_KEY_KEY ==="
    cat ios/AuthKey_P4JVQNHTAR.p8
    echo ""
    echo "=== FIN DU CONTENU ==="
    echo ""
    echo "📋 Copiez ce contenu dans la variable APPSTORECONNECT_API_KEY_KEY dans CodeMagic"
    echo ""
    echo "🔑 Autres variables à configurer :"
    echo "- APPSTORECONNECT_API_KEY_KEY_ID: 4V6GWRQFC9"
    echo "- APPSTORECONNECT_API_KEY_ISSUER_ID: bbd1db28-6a57-409f-860f-cfc657430d67"
    echo ""
    echo "⚠️  IMPORTANT : Ne partagez jamais ce contenu publiquement !"
else
    echo "❌ Fichier AuthKey_P4JVQNHTAR.p8 non trouvé dans ios/"
    echo "Veuillez placer votre fichier .p8 dans le dossier ios/"
    exit 1
fi 