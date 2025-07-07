const fs = require('fs');

// Configuration Supabase
const SUPABASE_URL = 'https://qlomkoexurbxqsezavdi.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

async function createTable(tableName, columns) {
  try {
    console.log(`🔧 Création de la table ${tableName}...`);
    
    // Créer la table via l'API REST
    const response = await fetch(`${SUPABASE_URL}/rest/v1/${tableName}`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify({
        // Envoyer une ligne vide pour créer la table
        id: 'temp'
      })
    });

    if (response.status === 201 || response.status === 200) {
      console.log(`✅ Table ${tableName} créée avec succès`);
      return true;
    } else {
      console.log(`⚠️  Table ${tableName} - Status: ${response.status}`);
      const errorText = await response.text();
      console.log(`   Erreur: ${errorText}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Erreur lors de la création de la table ${tableName}:`);
    console.log(`   ${error.message}`);
    return false;
  }
}

async function createReferralFunctions() {
  try {
    console.log('\n🔧 Création des fonctions SQL...');
    
    // Créer les fonctions une par une via des requêtes SQL
    const functions = [
      {
        name: 'generate_referral_code',
        sql: `
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
        `
      },
      {
        name: 'create_referral_code',
        sql: `
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
        `
      }
    ];

    for (const func of functions) {
      console.log(`\n🔄 Création de la fonction ${func.name}...`);
      
      // Note: Les fonctions SQL doivent être créées via l'interface SQL de Supabase
      // car l'API REST ne permet pas d'exécuter du DDL
      console.log(`⚠️  La fonction ${func.name} doit être créée manuellement via l'interface SQL de Supabase`);
      console.log(`   SQL: ${func.sql.substring(0, 100)}...`);
    }

  } catch (error) {
    console.error('❌ Erreur lors de la création des fonctions:', error);
  }
}

async function testBasicOperations() {
  try {
    console.log('\n🧪 Test des opérations de base...');
    
    // Test 1: Insérer un code de parrainage de test
    console.log('\n1️⃣ Test d\'insertion d\'un code de parrainage...');
    const insertResponse = await fetch(`${SUPABASE_URL}/rest/v1/referral_codes`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        code: 'TEST1234',
        device_id: 'test_device_1',
        is_active: true,
        max_uses: 1000,
        current_uses: 0
      })
    });

    if (insertResponse.ok) {
      const result = await insertResponse.json();
      console.log(`✅ Code de parrainage inséré:`, result);
    } else {
      console.log(`❌ Erreur insertion: ${insertResponse.status}`);
      const errorText = await insertResponse.text();
      console.log(`   Erreur: ${errorText}`);
    }

    // Test 2: Récupérer les codes
    console.log('\n2️⃣ Test de récupération des codes...');
    const selectResponse = await fetch(`${SUPABASE_URL}/rest/v1/referral_codes?select=*`, {
      method: 'GET',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (selectResponse.ok) {
      const codes = await selectResponse.json();
      console.log(`✅ Codes récupérés:`, codes);
    } else {
      console.log(`❌ Erreur récupération: ${selectResponse.status}`);
    }

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
}

async function main() {
  try {
    console.log('🚀 Démarrage du setup des tables de parrainage...\n');

    // Créer les tables
    const tables = [
      {
        name: 'referral_codes',
        columns: ['id', 'code', 'device_id', 'created_at', 'is_active', 'max_uses', 'current_uses']
      },
      {
        name: 'referral_usage',
        columns: ['id', 'referral_code_id', 'referred_device_id', 'subscription_type', 'used_at', 'is_valid']
      },
      {
        name: 'user_referral_points',
        columns: ['id', 'device_id', 'available_points', 'total_points_earned', 'total_points_used', 'created_at', 'updated_at']
      },
      {
        name: 'referral_rewards',
        columns: ['id', 'device_id', 'points_used', 'discount_percentage', 'payment_id', 'applied_at', 'is_used', 'used_at']
      }
    ];

    for (const table of tables) {
      await createTable(table.name, table.columns);
    }

    // Créer les fonctions (instructions manuelles)
    await createReferralFunctions();

    // Tester les opérations de base
    await testBasicOperations();

    console.log('\n🎊 Setup des tables terminé !');
    console.log('\n📋 Instructions manuelles:');
    console.log('1. Allez dans l\'interface SQL de Supabase');
    console.log('2. Exécutez le script setup-referral-system.sql');
    console.log('3. Testez les fonctions de parrainage');

  } catch (error) {
    console.error('❌ Erreur lors du setup:', error);
    process.exit(1);
  }
}

// Exécuter le script
main(); 