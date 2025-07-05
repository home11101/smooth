import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

console.log('Fonction d\'utilisation de code promo initialisée');

// Cette function accepte les requêtes avec la clé anon (publique) côté client.
// La sécurité est assurée par les policies RLS sur la table promo_codes et promo_code_usage.

// DEBUG : Cette Edge Function est rendue totalement publique pour test web (aucune vérification JWT, CORS permissif)

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
      code, 
      device_id, 
      discount_applied, 
      subscription_type, 
      ip_address, 
      user_agent 
    } = await req.json();
    
    console.log(`Enregistrement de l'utilisation du code promo: ${code}`);

    if (!code || !device_id || discount_applied === undefined) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error_message: 'Paramètres manquants: code, device_id et discount_applied sont requis.' 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
      );
    }

    // Créer le client Supabase avec la clé service_role côté backend
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Enregistrer l'utilisation du code promo via la fonction SQL
    const { data, error } = await supabase
      .rpc('use_promo_code', {
        p_code: code,
        p_device_id: device_id,
        p_discount_applied: discount_applied,
        p_subscription_type: subscription_type || null,
        p_ip_address: ip_address || null,
        p_user_agent: user_agent || null
      });

    if (error) {
      console.error('Erreur lors de l\'enregistrement:', error);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error_message: 'Erreur lors de l\'enregistrement de l\'utilisation du code promo.' 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 500 }
      );
    }

    // Log pour analytics
    console.log(`Utilisation du code promo ${code} enregistrée:`, {
      device_id: device_id,
      discount_applied: discount_applied,
      subscription_type: subscription_type,
      success: data
    });

    return new Response(
      JSON.stringify({ 
        success: data,
        message: data ? 'Utilisation du code promo enregistrée avec succès.' : 'Erreur lors de l\'enregistrement.'
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 200 }
    );

  } catch (error) {
    console.error('Erreur d\'enregistrement:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error_message: 'Erreur interne du serveur.' 
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 500 }
    );
  }
}); 