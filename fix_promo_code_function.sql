-- Supprimer toutes les versions existantes de la fonction
DROP FUNCTION IF EXISTS validate_promo_code(VARCHAR(50), VARCHAR(255));
DROP FUNCTION IF EXISTS validate_promo_code(TEXT, TEXT);
DROP FUNCTION IF EXISTS validate_promo_code(CHARACTER VARYING, CHARACTER VARYING);

-- Recréer la fonction avec les bons types
CREATE OR REPLACE FUNCTION validate_promo_code(
    p_code VARCHAR(50),
    p_device_id VARCHAR(255) DEFAULT NULL
)
RETURNS TABLE(
    is_valid BOOLEAN,
    discount_type VARCHAR(20),
    discount_value DECIMAL(5,2),
    description TEXT,
    error_message TEXT
) AS $$
DECLARE
    promo_record promo_codes%ROWTYPE;
    usage_count INTEGER;
BEGIN
    -- Vérifier si le code existe et est actif
    SELECT * INTO promo_record 
    FROM promo_codes 
    WHERE code = p_code 
    AND is_active = true 
    AND valid_from <= NOW() 
    AND valid_until >= NOW();
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 
            false, 
            NULL::VARCHAR(20), 
            NULL::DECIMAL(5,2), 
            NULL::TEXT, 
            'Code promo invalide ou expiré'::TEXT;
        RETURN;
    END IF;
    
    -- Vérifier la limite d'utilisation
    IF promo_record.max_uses IS NOT NULL THEN
        IF promo_record.current_uses >= promo_record.max_uses THEN
            RETURN QUERY SELECT 
                false, 
                NULL::VARCHAR(20), 
                NULL::DECIMAL(5,2), 
                NULL::TEXT, 
                'Code promo épuisé'::TEXT;
            RETURN;
        END IF;
    END IF;
    
    -- Vérifier si l'utilisateur a déjà utilisé ce code
    IF p_device_id IS NOT NULL THEN
        SELECT COUNT(*) INTO usage_count
        FROM promo_code_usage
        WHERE promo_code_id = promo_record.id 
        AND device_id = p_device_id;
        
        IF usage_count > 0 THEN
            RETURN QUERY SELECT 
                false, 
                NULL::VARCHAR(20), 
                NULL::DECIMAL(5,2), 
                NULL::TEXT, 
                'Code promo déjà utilisé'::TEXT;
            RETURN;
        END IF;
    END IF;
    
    -- Code valide
    RETURN QUERY SELECT 
        true, 
        promo_record.discount_type, 
        promo_record.discount_value, 
        promo_record.description, 
        NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Ajouter quelques codes promo de test
INSERT INTO promo_codes (code, description, discount_type, discount_value, max_uses, valid_until) VALUES
('WELCOME2025', 'Code de bienvenue - 10% de réduction pour les 100 premiers inscrits', 'percentage', 10.00, 100, NOW() + INTERVAL '6 months'),
('SMOOTH2TEAM', 'Code équipe - 50% de réduction', 'percentage', 50.00, NULL, NOW() + INTERVAL '6 months'),
('INFLUENCER4SM', 'Code influenceur - 100% de réduction', 'percentage', 100.00, NULL, NOW() + INTERVAL '1 year')
ON CONFLICT (code) DO NOTHING; 