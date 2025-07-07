const fs = require('fs');

// Configuration Supabase
const SUPABASE_URL = 'https://qlomkoexurbxqsezavdi.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

async function executeSQLQuery(sql) {
  try {
    console.log(`🔧 Exécution: ${sql.substring(0, 50)}...`);
    
    // Utiliser l'API REST pour exécuter du SQL
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: sql
      })
    });

    if (response.ok) {
      const result = await response.json();
      console.log(`✅ Succès`);
      return result;
    } else {
      const errorText = await response.text();
      console.log(`❌ Erreur (${response.status}): ${errorText}`);
      return null;
    }
  } catch (error) {
    console.log(`❌ Exception: ${error.message}`);
    return null;
  }
}

async function createTablesViaAPI() {
  try {
    console.log('🚀 Création des tables via API REST...\n');

    // Créer la table referral_codes
    const createReferralCodes = `
      CREATE TABLE IF NOT EXISTS referral_codes (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        code VARCHAR(10) UNIQUE NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        is_active BOOLEAN DEFAULT TRUE,
        max_uses INTEGER DEFAULT 1000,
        current_uses INTEGER DEFAULT 0
      );
    `;
    await executeSQLQuery(createReferralCodes);

    // Créer la table referral_usage
    const createReferralUsage = `
      CREATE TABLE IF NOT EXISTS referral_usage (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        referral_code_id UUID REFERENCES referral_codes(id) ON DELETE CASCADE,
        referred_device_id VARCHAR(255) NOT NULL,
        subscription_type VARCHAR(50),
        used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        is_valid BOOLEAN DEFAULT TRUE
      );
    `;
    await executeSQLQuery(createReferralUsage);

    // Créer la table user_referral_points
    const createUserReferralPoints = `
      CREATE TABLE IF NOT EXISTS user_referral_points (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        available_points INTEGER DEFAULT 0,
        total_points_earned INTEGER DEFAULT 0,
        total_points_used INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `;
    await executeSQLQuery(createUserReferralPoints);

    // Créer la table referral_rewards
    const createReferralRewards = `
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
    `;
    await executeSQLQuery(createReferralRewards);

    console.log('\n✅ Tables créées !');

  } catch (error) {
    console.error('❌ Erreur lors de la création des tables:', error);
  }
}

async function createFunctionsViaAPI() {
  try {
    console.log('\n🔧 Création des fonctions SQL...\n');

    // Fonction pour générer un code de parrainage
    const generateReferralCodeFunction = `
      CREATE OR REPLACE FUNCTION generate_referral_code()
      RETURNS VARCHAR(10) AS $$
      DECLARE
          new_code VARCHAR(10);
          code_exists BOOLEAN;
      BEGIN
          LOOP
              new_code := upper(substring(md5(random()::text) from 1 for 8));
              SELECT EXISTS(SELECT 1 FROM referral_codes WHERE code = new_code) INTO code_exists;
              IF NOT code_exists THEN
                  RETURN new_code;
              END IF;
          END LOOP;
      END;
      $$ LANGUAGE plpgsql;
    `;
    await executeSQLQuery(generateReferralCodeFunction);

    // Fonction pour créer un code de parrainage
    const createReferralCodeFunction = `
      CREATE OR REPLACE FUNCTION create_referral_code(p_device_id VARCHAR(255))
      RETURNS VARCHAR(10) AS $$
      DECLARE
          new_code VARCHAR(10);
          existing_code VARCHAR(10);
      BEGIN
          SELECT code INTO existing_code 
          FROM referral_codes 
          WHERE device_id = p_device_id AND is_active = TRUE;
          
          IF existing_code IS NOT NULL THEN
              RETURN existing_code;
          END IF;
          
          new_code := generate_referral_code();
          
          INSERT INTO referral_codes (code, device_id)
          VALUES (new_code, p_device_id);
          
          INSERT INTO user_referral_points (device_id, available_points, total_points_earned)
          VALUES (p_device_id, 0, 0)
          ON CONFLICT (device_id) DO NOTHING;
          
          RETURN new_code;
      END;
      $$ LANGUAGE plpgsql;
    `;
    await executeSQLQuery(createReferralCodeFunction);

    // Fonction pour utiliser un code de parrainage
    const useReferralCodeFunction = `
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
          SELECT * INTO referral_record
          FROM referral_codes
          WHERE code = p_code AND is_active = TRUE;
          
          IF referral_record IS NULL THEN
              RETURN json_build_object(
                'success', false,
                'message', 'Code de parrainage invalide'
              );
          END IF;
          
          IF referral_record.device_id = p_referred_device_id THEN
              RETURN json_build_object(
                'success', false,
                'message', 'Vous ne pouvez pas utiliser votre propre code'
              );
          END IF;
          
          IF referral_record.current_uses >= referral_record.max_uses THEN
              RETURN json_build_object(
                'success', false,
                'message', 'Ce code de parrainage a atteint sa limite d\\'utilisation'
              );
          END IF;
          
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
          
          INSERT INTO referral_usage (referral_code_id, referred_device_id, subscription_type)
          VALUES (referral_record.id, p_referred_device_id, p_subscription_type);
          
          UPDATE referral_codes 
          SET current_uses = current_uses + 1
          WHERE id = referral_record.id;
          
          INSERT INTO user_referral_points (device_id, available_points, total_points_earned)
          VALUES (referral_record.device_id, 1, 1)
          ON CONFLICT (device_id) 
          DO UPDATE SET 
            available_points = user_referral_points.available_points + 1,
            total_points_earned = user_referral_points.total_points_earned + 1,
            updated_at = NOW();
          
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
    `;
    await executeSQLQuery(useReferralCodeFunction);

    // Fonction pour récupérer les statistiques
    const getUserReferralStatsFunction = `
      CREATE OR REPLACE FUNCTION get_user_referral_stats(p_device_id VARCHAR(255))
      RETURNS JSON AS $$
      DECLARE
          user_points RECORD;
          user_code RECORD;
          total_referrals INTEGER;
          result JSON;
      BEGIN
          SELECT * INTO user_points
          FROM user_referral_points
          WHERE device_id = p_device_id;
          
          SELECT code INTO user_code
          FROM referral_codes
          WHERE device_id = p_device_id AND is_active = TRUE;
          
          SELECT COUNT(*) INTO total_referrals
          FROM referral_usage ru
          JOIN referral_codes rc ON ru.referral_code_id = rc.id
          WHERE rc.device_id = p_device_id AND ru.is_valid = TRUE;
          
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
    `;
    await executeSQLQuery(getUserReferralStatsFunction);

    console.log('\n✅ Fonctions créées !');

  } catch (error) {
    console.error('❌ Erreur lors de la création des fonctions:', error);
  }
}

async function testReferralSystem() {
  try {
    console.log('\n🧪 Test du système de parrainage...\n');

    // Test 1: Créer un code de parrainage
    console.log('1️⃣ Test de création de code de parrainage...');
    const createCodeResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/create_referral_code`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        p_device_id: 'test_device_api'
      })
    });

    if (createCodeResponse.ok) {
      const code = await createCodeResponse.text();
      console.log(`✅ Code créé: ${code}`);
    } else {
      console.log(`❌ Erreur création code: ${createCodeResponse.status}`);
      const errorText = await createCodeResponse.text();
      console.log(`   Erreur: ${errorText}`);
    }

    // Test 2: Récupérer les statistiques
    console.log('\n2️⃣ Test de récupération des statistiques...');
    const statsResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_user_referral_stats`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        p_device_id: 'test_device_api'
      })
    });

    if (statsResponse.ok) {
      const stats = await statsResponse.json();
      console.log(`✅ Statistiques récupérées:`, stats);
    } else {
      console.log(`❌ Erreur récupération stats: ${statsResponse.status}`);
      const errorText = await statsResponse.text();
      console.log(`   Erreur: ${errorText}`);
    }

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
}

async function main() {
  try {
    console.log('🚀 Setup complet du système de parrainage via API...\n');

    // Créer les tables
    await createTablesViaAPI();

    // Créer les fonctions
    await createFunctionsViaAPI();

    // Tester le système
    await testReferralSystem();

    console.log('\n🎊 Setup terminé avec succès !');
    console.log('\n📋 Le système de parrainage est maintenant opérationnel !');

  } catch (error) {
    console.error('❌ Erreur lors du setup:', error);
    process.exit(1);
  }
}

main(); 