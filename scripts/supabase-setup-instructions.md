# Instructions de Setup Supabase - Système de Parrainage

## Étapes à suivre :

1. **Accédez à votre dashboard Supabase**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet Smooth AI

2. **Ouvrez l'éditeur SQL**
   - Cliquez sur "SQL Editor" dans le menu de gauche
   - Cliquez sur "New query"

3. **Copiez-collez le script SQL suivant :**

```sql
-- =====================================================
-- SYSTÈME DE PARRAINAGE SMOOTH AI
-- =====================================================

-- 1. Table des codes de parrainage
CREATE TABLE IF NOT EXISTS referral_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    max_uses INTEGER DEFAULT 1000,
    current_uses INTEGER DEFAULT 0
);

-- 2. Table des utilisations de codes de parrainage
CREATE TABLE IF NOT EXISTS referral_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    referral_code_id UUID REFERENCES referral_codes(id) ON DELETE CASCADE,
    referred_device_id VARCHAR(255) NOT NULL,
    subscription_type VARCHAR(50),
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_valid BOOLEAN DEFAULT TRUE
);

-- 3. Table des points de parrainage des utilisateurs
CREATE TABLE IF NOT EXISTS user_referral_points (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    available_points INTEGER DEFAULT 0,
    total_points_earned INTEGER DEFAULT 0,
    total_points_used INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Table des récompenses de parrainage
CREATE TABLE IF NOT EXISTS referral_rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    points_used INTEGER NOT NULL,
    discount_percentage INTEGER NOT NULL,
    payment_id VARCHAR(255),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- FONCTIONS SQL
-- =====================================================

-- Fonction pour générer un code de parrainage unique
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS VARCHAR(10) AS $$
DECLARE
    new_code VARCHAR(10);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Générer un code de 8 caractères alphanumériques
        new_code := upper(substring(md5(random()::text) from 1 for 8));
        
        -- Vérifier si le code existe déjà
        SELECT EXISTS(SELECT 1 FROM referral_codes WHERE code = new_code) INTO code_exists;
        
        -- Si le code n'existe pas, on peut l'utiliser
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer un code de parrainage pour un utilisateur
CREATE OR REPLACE FUNCTION create_referral_code(p_device_id VARCHAR(255))
RETURNS VARCHAR(10) AS $$
DECLARE
    new_code VARCHAR(10);
    existing_code VARCHAR(10);
BEGIN
    -- Vérifier si l'utilisateur a déjà un code
    SELECT code INTO existing_code 
    FROM referral_codes 
    WHERE device_id = p_device_id AND is_active = TRUE;
    
    -- Si un code existe déjà, le retourner
    IF existing_code IS NOT NULL THEN
        RETURN existing_code;
    END IF;
    
    -- Générer un nouveau code
    new_code := generate_referral_code();
    
    -- Insérer le nouveau code
    INSERT INTO referral_codes (code, device_id)
    VALUES (new_code, p_device_id);
    
    -- Créer ou mettre à jour les points de l'utilisateur
    INSERT INTO user_referral_points (device_id, available_points, total_points_earned)
    VALUES (p_device_id, 0, 0)
    ON CONFLICT (device_id) DO NOTHING;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour utiliser un code de parrainage
CREATE OR REPLACE FUNCTION use_referral_code(
    p_code VARCHAR(10),
    p_referred_device_id VARCHAR(255),
    p_subscription_type VARCHAR(50) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    referral_record RECORD;
    result JSON;
BEGIN
    -- Vérifier si le code existe et est actif
    SELECT * INTO referral_record
    FROM referral_codes
    WHERE code = p_code AND is_active = TRUE;
    
    IF referral_record IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Code de parrainage invalide'
        );
    END IF;
    
    -- Vérifier si l'utilisateur ne s'est pas parrainé lui-même
    IF referral_record.device_id = p_referred_device_id THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Vous ne pouvez pas utiliser votre propre code'
        );
    END IF;
    
    -- Vérifier si le code n'a pas dépassé sa limite d'utilisation
    IF referral_record.current_uses >= referral_record.max_uses THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Ce code de parrainage a atteint sa limite d\'utilisation'
        );
    END IF;
    
    -- Vérifier si ce device_id n'a pas déjà utilisé ce code
    IF EXISTS(
        SELECT 1 FROM referral_usage 
        WHERE referral_code_id = referral_record.id 
        AND referred_device_id = p_referred_device_id
        AND is_valid = TRUE
    ) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Ce code a déjà été utilisé par cet appareil'
        );
    END IF;
    
    -- Enregistrer l'utilisation du code
    INSERT INTO referral_usage (referral_code_id, referred_device_id, subscription_type)
    VALUES (referral_record.id, p_referred_device_id, p_subscription_type);
    
    -- Mettre à jour le nombre d'utilisations du code
    UPDATE referral_codes 
    SET current_uses = current_uses + 1
    WHERE id = referral_record.id;
    
    -- Ajouter un point au parraineur
    INSERT INTO user_referral_points (device_id, available_points, total_points_earned)
    VALUES (referral_record.device_id, 1, 1)
    ON CONFLICT (device_id) 
    DO UPDATE SET 
        available_points = user_referral_points.available_points + 1,
        total_points_earned = user_referral_points.total_points_earned + 1,
        updated_at = NOW();
    
    -- Créer ou mettre à jour les points du parrainé
    INSERT INTO user_referral_points (device_id, available_points, total_points_earned)
    VALUES (p_referred_device_id, 0, 0)
    ON CONFLICT (device_id) DO NOTHING;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Code de parrainage utilisé avec succès',
        'referrer_device_id', referral_record.device_id,
        'points_awarded', 1
    );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour appliquer une réduction de parrainage
CREATE OR REPLACE FUNCTION apply_referral_discount(
    p_device_id VARCHAR(255),
    p_points_to_use INTEGER,
    p_payment_id VARCHAR(255) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    user_points RECORD;
    discount_percentage INTEGER;
BEGIN
    -- Récupérer les points de l'utilisateur
    SELECT * INTO user_points
    FROM user_referral_points
    WHERE device_id = p_device_id;
    
    IF user_points IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Aucun compte de points trouvé'
        );
    END IF;
    
    -- Vérifier si l'utilisateur a assez de points
    IF user_points.available_points < p_points_to_use THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Points insuffisants'
        );
    END IF;
    
    -- Calculer le pourcentage de réduction (5% par tranche de 5 points)
    discount_percentage := (p_points_to_use / 5) * 5;
    
    -- Créer la récompense
    INSERT INTO referral_rewards (device_id, points_used, discount_percentage, payment_id)
    VALUES (p_device_id, p_points_to_use, discount_percentage, p_payment_id);
    
    -- Déduire les points utilisés
    UPDATE user_referral_points
    SET 
        available_points = available_points - p_points_to_use,
        total_points_used = total_points_used + p_points_to_use,
        updated_at = NOW()
    WHERE device_id = p_device_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Réduction appliquée avec succès',
        'discount_percentage', discount_percentage,
        'points_used', p_points_to_use
    );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour récupérer les statistiques de parrainage d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_referral_stats(p_device_id VARCHAR(255))
RETURNS JSON AS $$
DECLARE
    user_points RECORD;
    user_code RECORD;
    total_referrals INTEGER;
    result JSON;
BEGIN
    -- Récupérer les points de l'utilisateur
    SELECT * INTO user_points
    FROM user_referral_points
    WHERE device_id = p_device_id;
    
    -- Récupérer le code de parrainage de l'utilisateur
    SELECT code INTO user_code
    FROM referral_codes
    WHERE device_id = p_device_id AND is_active = TRUE;
    
    -- Compter le nombre total de parrainages
    SELECT COUNT(*) INTO total_referrals
    FROM referral_usage ru
    JOIN referral_codes rc ON ru.referral_code_id = rc.id
    WHERE rc.device_id = p_device_id AND ru.is_valid = TRUE;
    
    -- Construire le résultat
    result := json_build_object(
        'available_points', COALESCE(user_points.available_points, 0),
        'total_points_earned', COALESCE(user_points.total_points_earned, 0),
        'total_points_used', COALESCE(user_points.total_points_used, 0),
        'total_referrals', total_referrals,
        'referral_code', user_code.code,
        'can_claim_reward', COALESCE(user_points.available_points, 0) >= 5
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VUES POUR L'ADMIN
-- =====================================================

-- Vue des statistiques de parrainage pour l'admin
CREATE OR REPLACE VIEW referral_admin_stats AS
SELECT 
    rc.code,
    rc.device_id,
    rc.created_at,
    rc.current_uses,
    rc.max_uses,
    urp.available_points,
    urp.total_points_earned,
    urp.total_points_used,
    COUNT(ru.id) as total_referrals,
    COUNT(CASE WHEN ru.used_at >= NOW() - INTERVAL '30 days' THEN 1 END) as referrals_last_30_days
FROM referral_codes rc
LEFT JOIN user_referral_points urp ON rc.device_id = urp.device_id
LEFT JOIN referral_usage ru ON rc.id = ru.referral_code_id AND ru.is_valid = TRUE
WHERE rc.is_active = TRUE
GROUP BY rc.id, rc.code, rc.device_id, rc.created_at, rc.current_uses, rc.max_uses, urp.available_points, urp.total_points_earned, urp.total_points_used;

-- Vue des récompenses utilisées
CREATE OR REPLACE VIEW referral_rewards_used AS
SELECT 
    rr.device_id,
    rr.points_used,
    rr.discount_percentage,
    rr.applied_at,
    rr.is_used,
    rr.used_at,
    rr.payment_id
FROM referral_rewards rr
ORDER BY rr.applied_at DESC;

-- =====================================================
-- INDEX POUR LES PERFORMANCES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_referral_codes_device_id ON referral_codes(device_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_usage_code_id ON referral_usage(referral_code_id);
CREATE INDEX IF NOT EXISTS idx_referral_usage_device_id ON referral_usage(referred_device_id);
CREATE INDEX IF NOT EXISTS idx_user_referral_points_device_id ON user_referral_points(device_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_device_id ON referral_rewards(device_id);

-- =====================================================
-- TRIGGERS POUR LA MAINTENANCE
-- =====================================================

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_referral_points_updated_at
    BEFORE UPDATE ON user_referral_points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insérer quelques codes de parrainage de test
INSERT INTO referral_codes (code, device_id, max_uses) VALUES
('TEST1234', 'test_device_1', 1000),
('DEMO5678', 'test_device_2', 1000)
ON CONFLICT (code) DO NOTHING;

-- Insérer des points de test
INSERT INTO user_referral_points (device_id, available_points, total_points_earned) VALUES
('test_device_1', 3, 5),
('test_device_2', 7, 12)
ON CONFLICT (device_id) DO NOTHING; 
```

4. **Exécutez le script**
   - Cliquez sur le bouton "Run" (▶️)
   - Attendez que toutes les requêtes s'exécutent

5. **Vérifiez la création**
   - Allez dans "Table Editor"
   - Vérifiez que les tables suivantes existent :
     - `referral_codes`
     - `referral_usage`
     - `user_referral_points`
     - `referral_rewards`

6. **Testez les fonctions**
   - Retournez dans "SQL Editor"
   - Exécutez le script de test : `scripts/test-referral-system.sql`

## Tables créées :

- **referral_codes** : Codes de parrainage des utilisateurs
- **referral_usage** : Historique des utilisations de codes
- **user_referral_points** : Points de parrainage des utilisateurs
- **referral_rewards** : Récompenses et réductions appliquées

## Fonctions créées :

- **create_referral_code(device_id)** : Génère un code de parrainage
- **use_referral_code(code, device_id, subscription_type)** : Utilise un code
- **get_user_referral_stats(device_id)** : Récupère les statistiques
- **apply_referral_discount(device_id, points, payment_id)** : Applique une réduction

## Vues créées :

- **referral_admin_stats** : Statistiques pour l'administration
- **referral_rewards_used** : Historique des récompenses

---

*Script généré automatiquement le 7/8/2025, 12:25:14 AM*
