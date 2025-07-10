#!/bin/bash

# Script pour télécharger le certificat de distribution
echo "🔐 Téléchargement du certificat de distribution..."

# Créer le dossier des certificats
mkdir -p ios/certs

echo ""
echo "📋 Instructions pour obtenir le certificat de distribution :"
echo ""
echo "1. Allez sur https://developer.apple.com/account/"
echo "2. Cliquez sur 'Certificates, Identifiers & Profiles'"
echo "3. Dans 'Certificates', cliquez sur '+' pour créer un nouveau certificat"
echo "4. Sélectionnez 'iOS Distribution (App Store and Ad Hoc)'"
echo "5. Suivez les instructions pour créer le certificat"
echo "6. Téléchargez le fichier .p12"
echo "7. Placez-le dans ios/certs/distribution_certificate.p12"
echo ""
echo "🔑 Si le certificat a un mot de passe, notez-le pour CodeMagic"
echo ""
echo "📁 Structure attendue :"
echo "ios/certs/"
echo "├── distribution_certificate.p12  # Certificat de distribution"
echo "└── AuthKey_4V6GWRQFC9.p8        # Clé API (déjà présent)"
echo ""
echo "✅ Une fois le certificat placé, relancez le build CodeMagic" 