#!/bin/bash

echo "🔐 Script de conversion des certificats iOS"
echo "=========================================="

# Demander le chemin du certificat .p12
echo "📁 Entrez le chemin vers votre certificat .p12 :"
read -p "> " CERT_PATH

if [ -f "$CERT_PATH" ]; then
    echo "✅ Certificat trouvé !"
    echo "🔧 Conversion en base64..."
    CERT_BASE64=$(base64 -i "$CERT_PATH")
    echo "📋 Certificat encodé :"
    echo "$CERT_BASE64"
    echo ""
    echo "💾 Copié dans le presse-papiers !"
    echo "$CERT_BASE64" | pbcopy
else
    echo "❌ Fichier non trouvé : $CERT_PATH"
fi

echo ""
echo "📁 Entrez le chemin vers votre profil .mobileprovision :"
read -p "> " PROFILE_PATH

if [ -f "$PROFILE_PATH" ]; then
    echo "✅ Profil trouvé !"
    echo "🔧 Conversion en base64..."
    PROFILE_BASE64=$(base64 -i "$PROFILE_PATH")
    echo "📋 Profil encodé :"
    echo "$PROFILE_BASE64"
    echo ""
    echo "💾 Copié dans le presse-papiers !"
    echo "$PROFILE_BASE64" | pbcopy
else
    echo "❌ Fichier non trouvé : $PROFILE_PATH"
fi

echo ""
echo "🎉 Conversion terminée !"
echo "📝 Copiez ces valeurs dans Codemagic :"
echo ""
echo "BUILD_CERTIFICATE_BASE64 = [Premier résultat]"
echo "PROVISIONING_PROFILE_BASE64 = [Deuxième résultat]" 