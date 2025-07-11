#!/bin/bash

# Script automatique pour générer un CSR et une clé privée pour certificat iOS Distribution
# Usage : ./generate-ios-csr.sh

echo "=== Génération d'une CSR pour certificat iOS Distribution ==="

# Demander l'email et le nom
read -p "Entrez votre email Apple Developer : " EMAIL
read -p "Entrez votre nom complet (pour le certificat) : " CN

# Pays par défaut
C=FR

# Noms de fichiers
KEY_FILE="ios_distribution.key"
CSR_FILE="ios_distribution.csr"

# Générer la clé privée et la CSR
openssl req -new -newkey rsa:2048 -nodes -keyout "$KEY_FILE" -out "$CSR_FILE" -subj "/emailAddress=$EMAIL, CN=$CN, C=$C"

if [[ -f "$KEY_FILE" && -f "$CSR_FILE" ]]; then
  echo "\n✅ CSR générée : $CSR_FILE"
  echo "✅ Clé privée générée : $KEY_FILE"
  echo "\nProchaine étape :"
  echo "1. Va sur https://developer.apple.com/account/resources/certificates/list"
  echo "2. Clique sur '+' puis choisis 'Apple Distribution'"
  echo "3. Upload le fichier $CSR_FILE"
  echo "4. Télécharge le certificat .cer généré, puis double-clique pour l'ajouter au Trousseau"
  echo "5. Exporte-le en .p12 depuis le Trousseau (clic droit > Exporter) et note le mot de passe !"
else
  echo "❌ Erreur lors de la génération du CSR ou de la clé privée."
  exit 1
fi 