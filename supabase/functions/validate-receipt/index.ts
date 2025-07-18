/// <reference types="https://deno.land/x/types/index.d.ts" />

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
// @ts-ignore: Deno types and djwt types may not be available in Edge Functions, but are fine at runtime
import { makeJwt, setExpiration, Jose, Payload } from "https://deno.land/x/djwt@v2.8/mod.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

console.log('Fonction de validation de reçu initialisée');

// Utilitaire fetch avec timeout
async function fetchWithTimeout(url: string, options: any, timeout = 8000) {
  return Promise.race([
    fetch(url, options),
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), timeout))
  ]);
}

// Utilitaire pour valider un reçu Apple
async function validateAppleReceipt(receipt: string, productId: string): Promise<{ isValid: boolean; reason?: string; expiryDate?: number }> {
  const APPLE_PROD_URL = 'https://buy.itunes.apple.com/verifyReceipt';
  const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
  const body = JSON.stringify({ 'receipt-data': receipt });

  let response, data;
  try {
    response = await fetchWithTimeout(APPLE_PROD_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
    data = await response.json();
    console.log('[AppleReceipt] Réponse production:', data.status);
  } catch (e) {
    console.error('[AppleReceipt] Erreur réseau Apple (prod):', e);
    return { isValid: false, reason: 'Erreur réseau Apple (prod): ' + e.message };
  }

  // Gestion des statuts Apple
  if (data.status === 21007) {
    // Sandbox receipt envoyé sur prod
    try {
      response = await fetchWithTimeout(APPLE_SANDBOX_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
      data = await response.json();
      console.log('[AppleReceipt] Réponse sandbox (après 21007):', data.status);
    } catch (e) {
      console.error('[AppleReceipt] Erreur réseau Apple (sandbox):', e);
      return { isValid: false, reason: 'Erreur réseau Apple (sandbox): ' + e.message };
    }
  } else if (data.status === 21008) {
    // Production receipt envoyé sur sandbox (rare, mais possible)
    try {
      response = await fetchWithTimeout(APPLE_PROD_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
      data = await response.json();
      console.log('[AppleReceipt] Réponse production (après 21008):', data.status);
    } catch (e) {
      console.error('[AppleReceipt] Erreur réseau Apple (prod 2):', e);
      return { isValid: false, reason: 'Erreur réseau Apple (prod 2): ' + e.message };
    }
  }

  if (data.status !== 0) {
    console.warn('[AppleReceipt] Statut Apple non 0:', data.status);
    return { isValid: false, reason: `Apple status: ${data.status}` };
  }

  // Vérification du produit dans le reçu
  let found = false;
  let expirationDateMs = null;
  if (data.latest_receipt_info && Array.isArray(data.latest_receipt_info)) {
    for (const info of data.latest_receipt_info) {
      if (info.product_id === productId) {
        found = true;
        expirationDateMs = info.expires_date_ms;
        break;
      }
    }
  } else if (data.receipt && data.receipt.in_app && Array.isArray(data.receipt.in_app)) {
    for (const info of data.receipt.in_app) {
      if (info.product_id === productId) {
        found = true;
        expirationDateMs = info.expires_date_ms;
        break;
      }
    }
  }

  if (!found) {
    console.warn('[AppleReceipt] Produit non trouvé dans le reçu:', productId);
    return { isValid: false, reason: 'Produit non trouvé dans le reçu.' };
  }

  // Vérification de l'expiration (pour les abonnements)
  if (expirationDateMs) {
    const now = Date.now();
    if (parseInt(expirationDateMs) < now) {
      console.warn('[AppleReceipt] Abonnement expiré:', expirationDateMs);
      return { isValid: false, reason: 'Abonnement expiré.' };
    }
    return { isValid: true, expiryDate: parseInt(expirationDateMs) };
  }

  return { isValid: true };
}

// Utilitaire pour valider un reçu Android
async function validateAndroidReceipt(
  packageName: string, 
  productId: string, 
  purchaseToken: string,
  isSubscription: boolean = true
): Promise<{ isValid: boolean; reason?: string; expiryDate?: number }> {
  try {
    // Récupérer les variables d'environnement
    const googleServiceAccountJson = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON');
    if (!googleServiceAccountJson) {
      return { isValid: false, reason: 'Configuration Google Service Account manquante.' };
    }

    const serviceAccount = JSON.parse(googleServiceAccountJson);
    
    // Créer un JWT pour l'authentification (RS256 signé)
    const header: Jose = {
      alg: 'RS256',
      typ: 'JWT',
    };
    const now = Math.floor(Date.now() / 1000);
    const payload: Payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600, // 1 heure
      iat: now,
    };
    // Générer le JWT signé
    const jwt = await makeJwt({ key: serviceAccount.private_key, header, payload });
    
    // Obtenir un token d'accès
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenData = await tokenResponse.json();
    if (!tokenData.access_token) {
      return { isValid: false, reason: 'Impossible d\'obtenir le token d\'accès Google.' };
    }

    // Valider l'achat via l'API Google Play
    const apiUrl = isSubscription 
      ? `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`
      : `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`;

    const validationResponse = await fetch(apiUrl, {
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`,
        'Content-Type': 'application/json',
      },
    });

    if (!validationResponse.ok) {
      return { isValid: false, reason: `Erreur API Google Play: ${validationResponse.status}` };
    }

    const purchaseData = await validationResponse.json();
    
    // Vérifier l'état de l'achat
    if (purchaseData.purchaseState !== 0) {
      return { isValid: false, reason: 'Achat non valide ou annulé.' };
    }

    // Vérifier l'expiration pour les abonnements
    if (isSubscription && purchaseData.expiryTimeMillis) {
      const expiryTime = parseInt(purchaseData.expiryTimeMillis);
      const now = Date.now();
      
      if (expiryTime < now) {
        return { isValid: false, reason: 'Abonnement expiré.' };
      }
      
      return { isValid: true, expiryDate: expiryTime };
    }

    return { isValid: true };
  } catch (error) {
    console.error('Erreur validation Android:', error);
    return { isValid: false, reason: `Erreur de validation: ${error.message}` };
  }
}

serve(async (req) => {
  // Gérer les requêtes CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      headers: { 
        'Access-Control-Allow-Origin': '*', 
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      } 
    });
  }

  try {
    const { 
      receipt, 
      productId, 
      platform, 
      packageName, 
      purchaseToken, 
      isSubscription = true,
      userId // récupéré du body
    } = await req.json();
    
    console.log(`Validation pour le produit ${productId} sur ${platform}`);

    if (!productId || !platform) {
      return new Response(
        JSON.stringify({ isValid: false, reason: 'Paramètres manquants.' }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
      );
    }

    if (platform === 'ios') {
      if (!receipt) {
        return new Response(
          JSON.stringify({ isValid: false, reason: 'Reçu manquant pour iOS.' }),
          { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
        );
      }
      const result = await validateAppleReceipt(receipt, productId);
      if (result.isValid && userId) {
        // Récompense le parrain si l'achat est validé
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabase = createClient(supabaseUrl, supabaseServiceKey);
        await supabase.rpc('reward_referrer_on_premium', { filleul_id: userId });
      }
      if (!result.isValid) {
        console.warn('Validation iOS échouée:', result.reason);
      }
      return new Response(
        JSON.stringify({ 
          isValid: result.isValid, 
          reason: result.reason,
          expiryDate: result.expiryDate 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 200 }
      );
    } else if (platform === 'android') {
      if (!packageName || !purchaseToken) {
        return new Response(
          JSON.stringify({ isValid: false, reason: 'Package name ou purchase token manquant pour Android.' }),
          { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
        );
      }
      const result = await validateAndroidReceipt(packageName, productId, purchaseToken, isSubscription);
      if (result.isValid && userId) {
        // Récompense le parrain si l'achat est validé
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabase = createClient(supabaseUrl, supabaseServiceKey);
        await supabase.rpc('reward_referrer_on_premium', { filleul_id: userId });
      }
      if (!result.isValid) {
        console.warn('Validation Android échouée:', result.reason);
      }
      return new Response(
        JSON.stringify({ 
          isValid: result.isValid, 
          reason: result.reason,
          expiryDate: result.expiryDate 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 200 }
      );
    } else {
      return new Response(
        JSON.stringify({ isValid: false, reason: 'Plateforme inconnue.' }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
      );
    }
  } catch (error) {
    console.error('Erreur de validation:', error);
    return new Response(
      JSON.stringify({ isValid: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
    );
  }
});
