-- Script pour ajouter les statistiques d'utilisateurs et de téléchargements
-- À exécuter dans Supabase SQL Editor

-- Table pour tracker les utilisateurs de l'app
CREATE TABLE IF NOT EXISTS app_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    platform VARCHAR(50) NOT NULL, -- 'ios', 'android', 'web'
    app_version VARCHAR(20),
    os_version VARCHAR(20),
    device_model VARCHAR(100),
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_sessions INTEGER DEFAULT 1,
    is_premium BOOLEAN DEFAULT false,
    subscription_type VARCHAR(50), -- 'monthly', 'yearly', 'premium_monthly', 'premium_yearly'
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table pour tracker les téléchargements par store
CREATE TABLE IF NOT EXISTS app_downloads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    platform VARCHAR(50) NOT NULL, -- 'ios', 'android', 'web'
    store VARCHAR(50) NOT NULL, -- 'app_store', 'play_store', 'web_direct'
    download_date DATE NOT NULL,
    downloads_count INTEGER DEFAULT 1,
    country VARCHAR(10), -- Code pays ISO
    source VARCHAR(100), -- 'organic', 'paid', 'referral'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table pour tracker les sessions utilisateur
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    session_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_end TIMESTAMP WITH TIME ZONE,
    session_duration INTEGER, -- en secondes
    features_used TEXT[], -- ['chat_analysis', 'pickup_lines', 'coaching']
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_app_users_device_id ON app_users(device_id);
CREATE INDEX IF NOT EXISTS idx_app_users_platform ON app_users(platform);
CREATE INDEX IF NOT EXISTS idx_app_users_premium ON app_users(is_premium);
CREATE INDEX IF NOT EXISTS idx_app_downloads_platform ON app_downloads(platform);
CREATE INDEX IF NOT EXISTS idx_app_downloads_date ON app_downloads(download_date);
CREATE INDEX IF NOT EXISTS idx_user_sessions_device_id ON user_sessions(device_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_start ON user_sessions(session_start);

-- Fonction pour mettre à jour le timestamp updated_at
CREATE OR REPLACE FUNCTION update_app_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_app_users_updated_at 
    BEFORE UPDATE ON app_users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_app_users_updated_at();

-- Fonction pour enregistrer ou mettre à jour un utilisateur
CREATE OR REPLACE FUNCTION register_app_user(
    p_device_id VARCHAR(255),
    p_platform VARCHAR(50),
    p_app_version VARCHAR(20) DEFAULT NULL,
    p_os_version VARCHAR(20) DEFAULT NULL,
    p_device_model VARCHAR(100) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO app_users (device_id, platform, app_version, os_version, device_model)
    VALUES (p_device_id, p_platform, p_app_version, p_os_version, p_device_model)
    ON CONFLICT (device_id) DO UPDATE SET
        last_seen = NOW(),
        total_sessions = app_users.total_sessions + 1,
        app_version = COALESCE(p_app_version, app_users.app_version),
        os_version = COALESCE(p_os_version, app_users.os_version),
        device_model = COALESCE(p_device_model, app_users.device_model);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour enregistrer un téléchargement
CREATE OR REPLACE FUNCTION record_app_download(
    p_platform VARCHAR(50),
    p_store VARCHAR(50),
    p_country VARCHAR(10) DEFAULT NULL,
    p_source VARCHAR(100) DEFAULT 'organic'
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO app_downloads (platform, store, download_date, country, source)
    VALUES (p_platform, p_store, CURRENT_DATE, p_country, p_source)
    ON CONFLICT (platform, store, download_date, country, source) DO UPDATE SET
        downloads_count = app_downloads.downloads_count + 1;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour enregistrer une session
CREATE OR REPLACE FUNCTION record_user_session(
    p_device_id VARCHAR(255),
    p_features_used TEXT[] DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    session_id UUID;
BEGIN
    INSERT INTO user_sessions (device_id, features_used)
    VALUES (p_device_id, p_features_used)
    RETURNING id INTO session_id;
    
    RETURN session_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour terminer une session
CREATE OR REPLACE FUNCTION end_user_session(
    p_session_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE user_sessions 
    SET session_end = NOW(),
        session_duration = EXTRACT(EPOCH FROM (NOW() - session_start))
    WHERE id = p_session_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Vues pour les analytics
CREATE OR REPLACE VIEW app_users_analytics AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_premium = true THEN 1 END) as premium_users,
    COUNT(CASE WHEN is_premium = false THEN 1 END) as free_users,
    COUNT(CASE WHEN platform = 'ios' THEN 1 END) as ios_users,
    COUNT(CASE WHEN platform = 'android' THEN 1 END) as android_users,
    COUNT(CASE WHEN platform = 'web' THEN 1 END) as web_users,
    COUNT(CASE WHEN last_seen >= NOW() - INTERVAL '7 days' THEN 1 END) as active_users_7d,
    COUNT(CASE WHEN last_seen >= NOW() - INTERVAL '30 days' THEN 1 END) as active_users_30d,
    AVG(total_sessions) as avg_sessions_per_user,
    COUNT(CASE WHEN subscription_type IS NOT NULL THEN 1 END) as subscribed_users
FROM app_users;

CREATE OR REPLACE VIEW app_downloads_analytics AS
SELECT 
    platform,
    store,
    SUM(downloads_count) as total_downloads,
    COUNT(DISTINCT download_date) as days_with_downloads,
    AVG(downloads_count) as avg_daily_downloads,
    MAX(download_date) as last_download_date,
    COUNT(CASE WHEN download_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as downloads_7d,
    COUNT(CASE WHEN download_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as downloads_30d
FROM app_downloads
GROUP BY platform, store;

-- RLS (Row Level Security)
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour app_users
CREATE POLICY "App users are viewable by everyone" ON app_users
    FOR SELECT USING (true);

CREATE POLICY "App users are insertable by everyone" ON app_users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "App users are updatable by everyone" ON app_users
    FOR UPDATE USING (true);

-- Politiques RLS pour app_downloads
CREATE POLICY "App downloads are viewable by everyone" ON app_downloads
    FOR SELECT USING (true);

CREATE POLICY "App downloads are insertable by everyone" ON app_downloads
    FOR INSERT WITH CHECK (true);

-- Politiques RLS pour user_sessions
CREATE POLICY "User sessions are viewable by everyone" ON user_sessions
    FOR SELECT USING (true);

CREATE POLICY "User sessions are insertable by everyone" ON user_sessions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "User sessions are updatable by everyone" ON user_sessions
    FOR UPDATE USING (true);

-- Données de test pour les téléchargements
INSERT INTO app_downloads (platform, store, download_date, downloads_count, country, source) VALUES
('ios', 'app_store', CURRENT_DATE - INTERVAL '30 days', 150, 'FR', 'organic'),
('ios', 'app_store', CURRENT_DATE - INTERVAL '29 days', 180, 'FR', 'organic'),
('ios', 'app_store', CURRENT_DATE - INTERVAL '28 days', 220, 'FR', 'paid'),
('android', 'play_store', CURRENT_DATE - INTERVAL '30 days', 120, 'FR', 'organic'),
('android', 'play_store', CURRENT_DATE - INTERVAL '29 days', 160, 'FR', 'organic'),
('android', 'play_store', CURRENT_DATE - INTERVAL '28 days', 190, 'FR', 'paid'),
('web', 'web_direct', CURRENT_DATE - INTERVAL '30 days', 50, 'FR', 'organic'),
('web', 'web_direct', CURRENT_DATE - INTERVAL '29 days', 70, 'FR', 'organic'),
('web', 'web_direct', CURRENT_DATE - INTERVAL '28 days', 90, 'FR', 'paid');

-- Données de test pour les utilisateurs
INSERT INTO app_users (device_id, platform, app_version, os_version, device_model, is_premium, subscription_type, total_sessions) VALUES
('device_001', 'ios', '1.2.0', 'iOS 17.0', 'iPhone 15', true, 'premium_monthly', 45),
('device_002', 'android', '1.2.0', 'Android 14', 'Samsung Galaxy S23', false, NULL, 12),
('device_003', 'ios', '1.1.9', 'iOS 16.5', 'iPhone 14', true, 'premium_yearly', 78),
('device_004', 'android', '1.2.0', 'Android 13', 'Google Pixel 7', false, NULL, 8),
('device_005', 'web', '1.2.0', 'Chrome 120', 'Desktop', true, 'monthly', 23),
('device_006', 'ios', '1.1.8', 'iOS 17.1', 'iPhone 13', false, NULL, 15),
('device_007', 'android', '1.2.0', 'Android 14', 'OnePlus 11', true, 'yearly', 34),
('device_008', 'web', '1.2.0', 'Safari 17', 'Desktop', false, NULL, 5);

-- Commentaires pour la documentation
COMMENT ON TABLE app_users IS 'Table des utilisateurs de l''application avec leurs informations de base';
COMMENT ON TABLE app_downloads IS 'Table de suivi des téléchargements par plateforme et store';
COMMENT ON TABLE user_sessions IS 'Table de suivi des sessions utilisateur';
COMMENT ON FUNCTION register_app_user IS 'Enregistre ou met à jour un utilisateur de l''app';
COMMENT ON FUNCTION record_app_download IS 'Enregistre un téléchargement de l''app';
COMMENT ON FUNCTION record_user_session IS 'Enregistre le début d''une session utilisateur';
COMMENT ON FUNCTION end_user_session IS 'Termine une session utilisateur';
COMMENT ON VIEW app_users_analytics IS 'Vue analytique des utilisateurs de l''app';
COMMENT ON VIEW app_downloads_analytics IS 'Vue analytique des téléchargements par store'; 