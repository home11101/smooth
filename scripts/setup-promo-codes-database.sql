-- Script de configuration de la table des codes promo
-- À exécuter dans Supabase SQL Editor

-- Création de la table des codes promo
CREATE TABLE IF NOT EXISTS promo_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount', 'trial_extension')),
    discount_value DECIMAL(5,2) NOT NULL,
    max_uses INTEGER DEFAULT NULL,
    current_uses INTEGER DEFAULT 0,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Création de la table pour tracker l'utilisation des codes
CREATE TABLE IF NOT EXISTS promo_code_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promo_code_id UUID REFERENCES promo_codes(id) ON DELETE CASCADE,
    user_id UUID, -- Peut être null si l'utilisateur n'est pas encore créé
    device_id VARCHAR(255), -- Pour identifier les utilisateurs non connectés
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    discount_applied DECIMAL(5,2) NOT NULL,
    subscription_type VARCHAR(50), -- monthly, yearly, etc.
    ip_address INET,
    user_agent TEXT
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_promo_codes_valid_until ON promo_codes(valid_until);
CREATE INDEX IF NOT EXISTS idx_promo_codes_active ON promo_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_promo_code_usage_promo_id ON promo_code_usage(promo_code_id);
CREATE INDEX IF NOT EXISTS idx_promo_code_usage_device_id ON promo_code_usage(device_id);

-- Fonction pour mettre à jour le timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_promo_codes_updated_at 
    BEFORE UPDATE ON promo_codes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insertion des codes promo spécifiés
INSERT INTO promo_codes (
    code, 
    description, 
    discount_type, 
    discount_value, 
    max_uses, 
    valid_until
) VALUES 
(
    'WELCOME2025',
    'Code de bienvenue - 10% de réduction pour les 100 premiers inscrits',
    'percentage',
    10.00,
    100,
    NOW() + INTERVAL '6 months'
),
(
    'SMOOTH2TEAM',
    'Code équipe - 50% de réduction',
    'percentage',
    50.00,
    NULL,
    NOW() + INTERVAL '6 months'
),
(
    'INFLUENCER4SM',
    'Code influenceur - 100% de réduction',
    'percentage',
    100.00,
    NULL,
    NOW() + INTERVAL '1 year'
);

-- Fonction pour valider un code promo
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

-- Fonction pour enregistrer l'utilisation d'un code promo
CREATE OR REPLACE FUNCTION use_promo_code(
    p_code VARCHAR(50),
    p_device_id VARCHAR(255),
    p_discount_applied DECIMAL(5,2),
    p_subscription_type VARCHAR(50) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    promo_record promo_codes%ROWTYPE;
BEGIN
    -- Récupérer le code promo
    SELECT * INTO promo_record 
    FROM promo_codes 
    WHERE code = p_code;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Enregistrer l'utilisation
    INSERT INTO promo_code_usage (
        promo_code_id,
        device_id,
        discount_applied,
        subscription_type,
        ip_address,
        user_agent
    ) VALUES (
        promo_record.id,
        p_device_id,
        p_discount_applied,
        p_subscription_type,
        p_ip_address,
        p_user_agent
    );
    
    -- Incrémenter le compteur d'utilisation
    UPDATE promo_codes 
    SET current_uses = current_uses + 1
    WHERE id = promo_record.id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- RLS (Row Level Security) pour sécuriser les tables
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_code_usage ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour promo_codes (lecture publique, écriture admin seulement)
CREATE POLICY "Promo codes are viewable by everyone" ON promo_codes
    FOR SELECT USING (true);

CREATE POLICY "Promo codes are insertable by authenticated users only" ON promo_codes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Promo codes are updatable by authenticated users only" ON promo_codes
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Politiques RLS pour promo_code_usage
CREATE POLICY "Promo code usage is viewable by everyone" ON promo_code_usage
    FOR SELECT USING (true);

CREATE POLICY "Promo code usage is insertable by everyone" ON promo_code_usage
    FOR INSERT WITH CHECK (true);

-- Vues pour les analytics
CREATE OR REPLACE VIEW promo_codes_analytics AS
SELECT 
    pc.code,
    pc.description,
    pc.discount_type,
    pc.discount_value,
    pc.max_uses,
    pc.current_uses,
    CASE 
        WHEN pc.max_uses IS NULL THEN NULL
        ELSE ROUND((pc.current_uses::DECIMAL / pc.max_uses::DECIMAL) * 100, 2)
    END as usage_percentage,
    pc.valid_from,
    pc.valid_until,
    pc.is_active,
    COUNT(pcu.id) as total_uses,
    AVG(pcu.discount_applied) as avg_discount_applied,
    MIN(pcu.used_at) as first_use,
    MAX(pcu.used_at) as last_use
FROM promo_codes pc
LEFT JOIN promo_code_usage pcu ON pc.id = pcu.promo_code_id
GROUP BY pc.id, pc.code, pc.description, pc.discount_type, pc.discount_value, 
         pc.max_uses, pc.current_uses, pc.valid_from, pc.valid_until, pc.is_active;

-- Commentaires pour la documentation
COMMENT ON TABLE promo_codes IS 'Table des codes promo disponibles';
COMMENT ON TABLE promo_code_usage IS 'Table de suivi de l''utilisation des codes promo';
COMMENT ON FUNCTION validate_promo_code IS 'Valide un code promo et retourne les détails de la réduction';
COMMENT ON FUNCTION use_promo_code IS 'Enregistre l''utilisation d''un code promo';
COMMENT ON VIEW promo_codes_analytics IS 'Vue analytique des codes promo avec statistiques d''utilisation'; 