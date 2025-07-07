const fs = require('fs');

async function generateSQLInstructions() {
  try {
    console.log('📝 Génération des instructions SQL pour Supabase...\n');

    // Lire le script SQL complet
    const sqlPath = './scripts/setup-referral-system.sql';
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');

    // Diviser en sections
    const sections = sqlContent.split('-- =====================================================');

    console.log('🎯 Instructions pour configurer le système de parrainage :\n');
    console.log('1️⃣ Allez dans votre dashboard Supabase');
    console.log('2️⃣ Cliquez sur "SQL Editor" dans le menu de gauche');
    console.log('3️⃣ Cliquez sur "New query"');
    console.log('4️⃣ Copiez-collez le script SQL suivant :\n');
    console.log('='.repeat(80));
    console.log(sqlContent);
    console.log('='.repeat(80));
    console.log('\n5️⃣ Cliquez sur "Run" pour exécuter le script');
    console.log('6️⃣ Vérifiez que toutes les tables et fonctions ont été créées');

    // Créer un fichier de sortie
    const outputPath = './scripts/supabase-setup-instructions.md';
    const instructions = `# Instructions de Setup Supabase - Système de Parrainage

## Étapes à suivre :

1. **Accédez à votre dashboard Supabase**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet Smooth AI

2. **Ouvrez l'éditeur SQL**
   - Cliquez sur "SQL Editor" dans le menu de gauche
   - Cliquez sur "New query"

3. **Copiez-collez le script SQL suivant :**

\`\`\`sql
${sqlContent}
\`\`\`

4. **Exécutez le script**
   - Cliquez sur le bouton "Run" (▶️)
   - Attendez que toutes les requêtes s'exécutent

5. **Vérifiez la création**
   - Allez dans "Table Editor"
   - Vérifiez que les tables suivantes existent :
     - \`referral_codes\`
     - \`referral_usage\`
     - \`user_referral_points\`
     - \`referral_rewards\`

6. **Testez les fonctions**
   - Retournez dans "SQL Editor"
   - Exécutez le script de test : \`scripts/test-referral-system.sql\`

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

*Script généré automatiquement le ${new Date().toLocaleString()}*
`;

    fs.writeFileSync(outputPath, instructions);
    console.log(`\n✅ Instructions sauvegardées dans : ${outputPath}`);

    // Créer aussi un fichier SQL séparé pour faciliter le copier-coller
    const sqlOutputPath = './scripts/supabase-referral-setup.sql';
    fs.writeFileSync(sqlOutputPath, sqlContent);
    console.log(`✅ Script SQL sauvegardé dans : ${sqlOutputPath}`);

    console.log('\n🎯 Prochaines étapes :');
    console.log('1. Ouvrez le fichier supabase-referral-setup.sql');
    console.log('2. Copiez tout le contenu');
    console.log('3. Collez-le dans l\'éditeur SQL de Supabase');
    console.log('4. Exécutez le script');

  } catch (error) {
    console.error('❌ Erreur lors de la génération des instructions:', error);
  }
}

async function testAfterSetup() {
  try {
    console.log('\n🧪 Script de test après setup :\n');

    const testSQL = fs.readFileSync('./scripts/test-referral-system.sql', 'utf8');

    console.log('📋 Pour tester le système après setup :\n');
    console.log('1. Dans l\'éditeur SQL de Supabase, créez une nouvelle requête');
    console.log('2. Copiez-collez le script de test suivant :\n');
    console.log('='.repeat(80));
    console.log(testSQL);
    console.log('='.repeat(80));
    console.log('\n3. Exécutez le script de test');
    console.log('4. Vérifiez que tous les tests passent');

  } catch (error) {
    console.error('❌ Erreur lors de la génération du script de test:', error);
  }
}

async function main() {
  try {
    await generateSQLInstructions();
    await testAfterSetup();

    console.log('\n🎊 Génération terminée !');
    console.log('\n📋 Résumé :');
    console.log('- Instructions : scripts/supabase-setup-instructions.md');
    console.log('- Script SQL : scripts/supabase-referral-setup.sql');
    console.log('- Script de test : scripts/test-referral-system.sql');

  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

main(); 