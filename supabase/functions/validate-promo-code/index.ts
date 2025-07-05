import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

console.log('Fonction de validation de code promo initialisée');

interface PromoCodeValidation {
  is_valid: boolean;
  discount_type?: string;
  discount_value?: number;
  description?: string;
  error_message?: string;
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
    const { code, device_id, context } = await req.json();
    console.log(`Validation du code promo: ${code} pour le contexte: ${context}`);

    if (!code) {
      return new Response(
        JSON.stringify({ 
          is_valid: false, 
          error_message: 'Code promo requis.' 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
      );
    }

    // Créer le client Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Valider le code promo via la fonction SQL
    const { data, error } = await supabase
      .rpc('validate_promo_code', {
        p_code: code,
        p_device_id: device_id || null
      });

    if (error) {
      console.error('Erreur lors de la validation:', error);
      return new Response(
        JSON.stringify({ 
          is_valid: false, 
          error_message: 'Erreur lors de la validation du code promo.' 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 500 }
      );
    }

    if (!data || data.length === 0) {
      return new Response(
        JSON.stringify({ 
          is_valid: false, 
          error_message: 'Code promo invalide.' 
        }),
        { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 400 }
      );
    }

    const validation = data[0] as PromoCodeValidation;

    // Log pour analytics
    console.log(`Code promo ${code} validé:`, {
      is_valid: validation.is_valid,
      discount_type: validation.discount_type,
      discount_value: validation.discount_value,
      context: context,
      device_id: device_id
    });

    return new Response(
      JSON.stringify(validation),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 200 }
    );

  } catch (error) {
    console.error('Erreur de validation:', error);
    return new Response(
      JSON.stringify({ 
        is_valid: false, 
        error_message: 'Erreur interne du serveur.' 
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }, status: 500 }
    );
  }
}); 