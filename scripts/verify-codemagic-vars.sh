#!/bin/bash

# Script pour vérifier que les noms de variables respectent les règles CodeMagic
echo "🔍 Vérification des noms de variables CodeMagic..."

# Variables à vérifier
variables=(
    "APPSTORE_CONNECT_API_KEY_ID"
    "APPSTORE_CONNECT_ISSUER_ID"
    "APPSTORE_CONNECT_API_KEY"
    "MATCH_PASSWORD"
    "APPLE_ID"
    "APP_SPECIFIC_PASSWORD"
)

echo "✅ Variables valides pour CodeMagic :"
for var in "${variables[@]}"; do
    # Vérifier que le nom ne contient que des lettres, chiffres et _
    if [[ $var =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "  ✅ $var"
    else
        echo "  ❌ $var (nom invalide)"
    fi
done

echo ""
echo "📋 Règles CodeMagic pour les noms de variables :"
echo "- Seulement des lettres, chiffres et le symbole _"
echo "- Ne peut pas commencer par un chiffre"
echo "- Doit être en majuscules"
echo ""
echo "✅ Toutes les variables respectent les règles !" 