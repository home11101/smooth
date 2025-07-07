-- Script pour mettre à jour les utilisations des codes promo existants
-- À exécuter dans Supabase SQL Editor

-- Supprimer les utilisations existantes pour repartir de zéro
DELETE FROM promo_code_usage;

-- Réinitialiser le compteur d'utilisations
UPDATE promo_codes SET current_uses = 0;

-- Générer 500 utilisations pour chaque code promo
DO $$
DECLARE
    promo_record RECORD;
    i INTEGER;
    device_id_base VARCHAR(255);
    subscription_types VARCHAR[] := ARRAY['monthly', 'yearly', 'premium_monthly', 'premium_yearly'];
    discount_values DECIMAL[] := ARRAY[10.00, 15.00, 20.00, 25.00, 30.00, 50.00, 75.00, 100.00];
BEGIN
    -- Pour chaque code promo
    FOR promo_record IN SELECT id, code, discount_value FROM promo_codes LOOP
        
        -- Générer 500 utilisations
        FOR i IN 1..500 LOOP
            -- Générer un device_id unique
            device_id_base := 'device_' || promo_record.code || '_' || i;
            
            -- Insérer l'utilisation
            INSERT INTO promo_code_usage (
                promo_code_id,
                device_id,
                used_at,
                discount_applied,
                subscription_type,
                ip_address,
                user_agent
            ) VALUES (
                promo_record.id,
                device_id_base,
                NOW() - (INTERVAL '1 day' * (500 - i)), -- Dates échelonnées sur les 500 derniers jours
                discount_values[1 + (i % array_length(discount_values, 1))], -- Valeurs de réduction variées
                subscription_types[1 + (i % array_length(subscription_types, 1))], -- Types d'abonnement variés
                INET '192.168.1.' || (i % 255), -- IP variées
                'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1'
            );
        END LOOP;
        
        -- Mettre à jour le compteur d'utilisations
        UPDATE promo_codes 
        SET current_uses = 500 
        WHERE id = promo_record.id;
        
        RAISE NOTICE 'Généré 500 utilisations pour le code: %', promo_record.code;
    END LOOP;
END $$;

-- Vérifier les résultats
SELECT 
    code,
    description,
    current_uses,
    max_uses,
    CASE 
        WHEN max_uses IS NULL THEN NULL
        ELSE ROUND((current_uses::DECIMAL / max_uses::DECIMAL) * 100, 2)
    END as usage_percentage
FROM promo_codes 
ORDER BY code;

-- Afficher le nombre total d'utilisations
SELECT 
    COUNT(*) as total_usage_records,
    COUNT(DISTINCT promo_code_id) as unique_promo_codes
FROM promo_code_usage; 