const fs = require('fs');
const path = require('path');

// Configuration Supabase
const SUPABASE_URL = 'https://qlomkoexurbxqsezavdi.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

async function executeSQL(sqlContent) {
  try {
    console.log('🔧 Exécution du script SQL...');
    
    // Diviser le script en requêtes individuelles
    const queries = sqlContent
      .split(';')
      .map(query => query.trim())
      .filter(query => query.length > 0 && !query.startsWith('--'));

    console.log(`📊 ${queries.length} requêtes à exécuter`);

    for (let i = 0; i < queries.length; i++) {
      const query = queries[i];
      if (query.trim().length === 0) continue;

      console.log(`\n🔄 Exécution de la requête ${i + 1}/${queries.length}...`);
      
      try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
          method: 'POST',
          headers: {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            sql: query
          })
        });

        if (response.ok) {
          console.log(`✅ Requête ${i + 1} exécutée avec succès`);
        } else {
          const errorText = await response.text();
          console.log(`⚠️  Requête ${i + 1} - Status: ${response.status}`);
          console.log(`   Erreur: ${errorText}`);
        }
      } catch (error) {
        console.log(`❌ Erreur lors de l'exécution de la requête ${i + 1}:`);
        console.log(`   ${error.message}`);
      }

      // Pause entre les requêtes pour éviter la surcharge
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log('\n🎉 Exécution terminée !');
  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

async function testReferralSystem() {
  try {
    console.log('\n🧪 Test du système de parrainage...');
    
    // Test 1: Créer un code de parrainage
    console.log('\n1️⃣ Test de création de code de parrainage...');
    const createCodeResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/create_referral_code`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        p_device_id: 'test_device_setup'
      })
    });

    if (createCodeResponse.ok) {
      const code = await createCodeResponse.text();
      console.log(`✅ Code créé: ${code}`);
    } else {
      console.log(`❌ Erreur création code: ${createCodeResponse.status}`);
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
        p_device_id: 'test_device_setup'
      })
    });

    if (statsResponse.ok) {
      const stats = await statsResponse.json();
      console.log(`✅ Statistiques récupérées:`, stats);
    } else {
      console.log(`❌ Erreur récupération stats: ${statsResponse.status}`);
    }

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
}

async function main() {
  try {
    console.log('🚀 Démarrage du setup du système de parrainage...\n');

    // Lire le fichier SQL
    const sqlPath = path.join(__dirname, 'setup-referral-system.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');

    // Exécuter le setup
    await executeSQL(sqlContent);

    // Tester le système
    await testReferralSystem();

    console.log('\n🎊 Setup du système de parrainage terminé avec succès !');
    console.log('\n📋 Prochaines étapes:');
    console.log('1. Tester l\'application Flutter');
    console.log('2. Vérifier les fonctionnalités de parrainage');
    console.log('3. Configurer les notifications si nécessaire');

  } catch (error) {
    console.error('❌ Erreur lors du setup:', error);
    process.exit(1);
  }
}

// Exécuter le script
main(); 