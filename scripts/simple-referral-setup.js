const fs = require('fs');

// Configuration Supabase
const SUPABASE_URL = 'https://qlomkoexurbxqsezavdi.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

async function testSupabaseConnection() {
  try {
    console.log('🔍 Test de connexion à Supabase...');
    
    // Test de connexion basique
    const response = await fetch(`${SUPABASE_URL}/rest/v1/`, {
      method: 'GET',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    console.log(`Status: ${response.status}`);
    console.log(`Headers:`, Object.fromEntries(response.headers.entries()));

    if (response.ok) {
      const data = await response.text();
      console.log(`✅ Connexion réussie`);
      console.log(`Données: ${data.substring(0, 200)}...`);
    } else {
      console.log(`❌ Erreur de connexion`);
    }

  } catch (error) {
    console.error('❌ Erreur de connexion:', error);
  }
}

async function listExistingTables() {
  try {
    console.log('\n📋 Liste des tables existantes...');
    
    // Essayer de lister les tables existantes
    const tables = ['promo_codes', 'payments', 'users', 'referral_codes'];
    
    for (const table of tables) {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}?select=count`, {
        method: 'GET',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        console.log(`✅ Table ${table} existe (${data.length} enregistrements)`);
      } else {
        console.log(`❌ Table ${table} n'existe pas (${response.status})`);
      }
    }

  } catch (error) {
    console.error('❌ Erreur lors de la liste des tables:', error);
  }
}

async function createReferralCodeTable() {
  try {
    console.log('\n🔧 Tentative de création de la table referral_codes...');
    
    // Essayer de créer la table en insérant une ligne de test
    const response = await fetch(`${SUPABASE_URL}/rest/v1/referral_codes`, {
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

    console.log(`Status: ${response.status}`);
    
    if (response.ok) {
      const data = await response.json();
      console.log(`✅ Table referral_codes créée/accessible`);
      console.log(`Données insérées:`, data);
    } else {
      const errorText = await response.text();
      console.log(`❌ Erreur: ${errorText}`);
    }

  } catch (error) {
    console.error('❌ Erreur lors de la création:', error);
  }
}

async function main() {
  try {
    console.log('🚀 Test de configuration Supabase...\n');

    await testSupabaseConnection();
    await listExistingTables();
    await createReferralCodeTable();

    console.log('\n📋 Instructions:');
    console.log('Si les tables n\'existent pas, vous devez:');
    console.log('1. Aller dans l\'interface SQL de Supabase');
    console.log('2. Exécuter le script setup-referral-system.sql manuellement');
    console.log('3. Ou créer les tables une par une via l\'interface');

  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

main(); 