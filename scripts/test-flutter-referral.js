const fs = require('fs');

// Configuration Supabase
const SUPABASE_URL = 'https://qlomkoexurbxqsezavdi.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsb21rb2V4dXJieHFzZXphdmRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODYxOTYsImV4cCI6MjA2Njk2MjE5Nn0.eVV4vRp1a_5FVMqqRcSHFC5cjaBEOKCODHZQ76fpED8';

async function testFlutterReferralSystem() {
  try {
    console.log('🧪 Test du système de parrainage pour Flutter...\n');

    // Test 1: Vérifier que les tables existent
    console.log('1️⃣ Vérification des tables...');
    const tables = ['referral_codes', 'referral_usage', 'user_referral_points', 'referral_rewards'];
    
    for (const table of tables) {
      try {
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
          console.log(`✅ Table ${table} accessible (${data.length} enregistrements)`);
        } else {
          console.log(`❌ Table ${table} non accessible (${response.status})`);
        }
      } catch (error) {
        console.log(`❌ Erreur table ${table}: ${error.message}`);
      }
    }

    // Test 2: Vérifier que les fonctions existent
    console.log('\n2️⃣ Vérification des fonctions...');
    const functions = [
      { name: 'create_referral_code', params: { p_device_id: 'test_flutter_device' } },
      { name: 'get_user_referral_stats', params: { p_device_id: 'test_flutter_device' } },
      { name: 'use_referral_code', params: { p_code: 'TEST1234', p_referred_device_id: 'test_flutter_device_2', p_subscription_type: 'premium_monthly' } }
    ];

    for (const func of functions) {
      try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${func.name}`, {
          method: 'POST',
          headers: {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(func.params)
        });

        if (response.ok) {
          const result = await response.json();
          console.log(`✅ Fonction ${func.name} accessible`);
          console.log(`   Résultat: ${JSON.stringify(result).substring(0, 100)}...`);
        } else {
          const errorText = await response.text();
          console.log(`❌ Fonction ${func.name} non accessible (${response.status})`);
          console.log(`   Erreur: ${errorText.substring(0, 100)}...`);
        }
      } catch (error) {
        console.log(`❌ Erreur fonction ${func.name}: ${error.message}`);
      }
    }

    // Test 3: Test complet du flux de parrainage
    console.log('\n3️⃣ Test complet du flux de parrainage...');
    
    const testDeviceId = `flutter_test_${Date.now()}`;
    
    // Créer un code de parrainage
    console.log(`   Création d'un code pour ${testDeviceId}...`);
    const createResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/create_referral_code`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        p_device_id: testDeviceId
      })
    });

    if (createResponse.ok) {
      const code = await createResponse.text();
      console.log(`   ✅ Code créé: ${code}`);

      // Récupérer les statistiques
      console.log(`   Récupération des statistiques...`);
      const statsResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_user_referral_stats`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          p_device_id: testDeviceId
        })
      });

      if (statsResponse.ok) {
        const stats = await statsResponse.json();
        console.log(`   ✅ Statistiques récupérées:`, stats);
      } else {
        console.log(`   ❌ Erreur récupération stats`);
      }
    } else {
      console.log(`   ❌ Erreur création code`);
    }

    console.log('\n✅ Tests terminés !');

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
}

async function generateFlutterTestInstructions() {
  try {
    console.log('\n📱 Instructions pour tester l\'application Flutter :\n');

    const instructions = `# Test de l'Application Flutter - Système de Parrainage

## Prérequis
- Les tables et fonctions SQL ont été créées dans Supabase
- L'application Flutter est compilée et prête

## Étapes de test

### 1. Test de l'écran Premium
1. Ouvrez l'application Flutter
2. Allez dans l'écran Premium
3. Vérifiez que la section parrainage s'affiche
4. Vérifiez que les statistiques se chargent

### 2. Test du menu Parrainage
1. Ouvrez le menu principal (icône hamburger)
2. Cliquez sur "Parrainage"
3. Vérifiez que la page de parrainage s'ouvre
4. Vérifiez que les statistiques s'affichent

### 3. Test du flux d'achat
1. Effectuez un achat premium (test)
2. Vérifiez que le dialogue de succès s'affiche
3. Vérifiez que le code de parrainage est visible
4. Testez les boutons copier/partager

### 4. Test des fonctionnalités
1. Copiez un code de parrainage
2. Partagez un code de parrainage
3. Vérifiez que les points se mettent à jour

## Points à vérifier

### Interface utilisateur
- [ ] Section parrainage visible dans l'écran premium
- [ ] Page de parrainage accessible via le menu
- [ ] Dialogue de succès après achat
- [ ] Boutons copier/partager fonctionnels

### Fonctionnalités
- [ ] Génération de codes de parrainage
- [ ] Affichage des statistiques
- [ ] Copie des codes dans le presse-papiers
- [ ] Partage des codes

### Intégration
- [ ] Connexion à Supabase fonctionnelle
- [ ] Appels API sans erreur
- [ ] Gestion des erreurs appropriée

## Debug

Si des erreurs surviennent :
1. Vérifiez les logs de l'application
2. Vérifiez la console de développement
3. Vérifiez les logs Supabase
4. Testez les fonctions SQL directement

## Support

Pour toute question technique : contact@smoothai.app
`;

    fs.writeFileSync('./scripts/flutter-test-instructions.md', instructions);
    console.log('✅ Instructions de test Flutter sauvegardées dans : scripts/flutter-test-instructions.md');

  } catch (error) {
    console.error('❌ Erreur lors de la génération des instructions:', error);
  }
}

async function main() {
  try {
    console.log('🚀 Test du système de parrainage Flutter...\n');

    await testFlutterReferralSystem();
    await generateFlutterTestInstructions();

    console.log('\n🎊 Tests terminés !');
    console.log('\n📋 Prochaines étapes :');
    console.log('1. Exécutez le script SQL dans Supabase');
    console.log('2. Testez l\'application Flutter');
    console.log('3. Vérifiez toutes les fonctionnalités');

  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

main(); 