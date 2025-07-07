# Test de l'Application Flutter - Système de Parrainage

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
