#!/bin/bash

# Script pour déployer la Supabase Edge Function OpenAI Proxy

echo "🚀 Déploiement de la Supabase Edge Function OpenAI Proxy..."

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI n'est pas installé. Installez-le d'abord."
    exit 1
fi

# Vérifier que vous êtes connecté à Supabase
if ! supabase status &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Supabase. Connectez-vous d'abord."
    exit 1
fi

# Déployer la fonction
echo "📦 Déploiement de la fonction openai-proxy..."
supabase functions deploy openai-proxy

# Ajouter la variable d'environnement pour l'API key OpenAI
echo "🔑 Ajout de la variable d'environnement OPENAI_API_KEY..."
echo "⚠️  IMPORTANT: Vous devez ajouter votre API key OpenAI manuellement:"
echo "   supabase secrets set OPENAI_API_KEY='votre-api-key-ici'"

echo "✅ Déploiement terminé!"
echo "🌐 URL de la fonction: https://oahmneimzzfahkuervii.supabase.co/functions/v1/openai-proxy" 