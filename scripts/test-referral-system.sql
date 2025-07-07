-- =====================================================
-- TESTS DU SYSTÈME DE PARRAINAGE
-- =====================================================

-- Test 1: Créer un code de parrainage
SELECT 'Test 1: Création de code de parrainage' as test_name;
SELECT create_referral_code('device_test_1') as code_genere;

-- Test 2: Créer un autre code de parrainage
SELECT 'Test 2: Création d\'un second code' as test_name;
SELECT create_referral_code('device_test_2') as code_genere;

-- Test 3: Utiliser un code de parrainage
SELECT 'Test 3: Utilisation d\'un code de parrainage' as test_name;
SELECT use_referral_code('TEST1234', 'device_test_3', 'premium_monthly') as resultat_utilisation;

-- Test 4: Vérifier les statistiques
SELECT 'Test 4: Statistiques utilisateur' as test_name;
SELECT get_user_referral_stats('device_test_1') as stats_utilisateur;

-- Test 5: Appliquer une réduction
SELECT 'Test 5: Application d\'une réduction' as test_name;
SELECT apply_referral_discount('device_test_1', 5, 'payment_test_1') as resultat_reduction;

-- Test 6: Vérifier les vues admin
SELECT 'Test 6: Vue admin des statistiques' as test_name;
SELECT * FROM referral_admin_stats LIMIT 5;

-- Test 7: Vérifier les récompenses
SELECT 'Test 7: Vue des récompenses' as test_name;
SELECT * FROM referral_rewards_used LIMIT 5;

-- Test 8: Vérifier la structure des tables
SELECT 'Test 8: Structure des tables' as test_name;
SELECT 
    'referral_codes' as table_name,
    COUNT(*) as total_records
FROM referral_codes
UNION ALL
SELECT 
    'referral_usage' as table_name,
    COUNT(*) as total_records
FROM referral_usage
UNION ALL
SELECT 
    'user_referral_points' as table_name,
    COUNT(*) as total_records
FROM user_referral_points
UNION ALL
SELECT 
    'referral_rewards' as table_name,
    COUNT(*) as total_records
FROM referral_rewards;

-- Test 9: Test d'erreur - Code invalide
SELECT 'Test 9: Test d\'erreur - Code invalide' as test_name;
SELECT use_referral_code('INVALID', 'device_test_4') as resultat_erreur;

-- Test 10: Test d'erreur - Auto-parrainage
SELECT 'Test 10: Test d\'erreur - Auto-parrainage' as test_name;
SELECT use_referral_code('TEST1234', 'test_device_1') as resultat_auto_parrainage; 