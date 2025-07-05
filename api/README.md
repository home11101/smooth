# API de validation des reçus (iOS & Android)

Ce service permet de valider les achats in-app iOS (Apple) et Android (Google Play) pour votre application Flutter.

---

## 1. Déploiement sur Vercel

1. **Poussez le dossier `/api` sur votre repo GitHub.**
2. **Connectez votre repo à Vercel** (https://vercel.com/import).
3. **Ajoutez la variable d'environnement `GOOGLE_SERVICE_ACCOUNT_JSON`** dans les settings Vercel (collez le contenu du fichier JSON de votre Service Account Google Play, tout sur une seule ligne).
4. **Déployez.**

---

## 2. Endpoints disponibles

- **POST `/api/validate-receipt`**

### Pour iOS (Apple)
- **Body JSON** :
```json
{
  "platform": "ios",
  "receipt": "...",
  "productId": "..."
}
```

### Pour Android (Google Play)
- **Body JSON** :
```json
{
  "platform": "android",
  "packageName": "com.example.app",
  "productId": "premium_monthly",
  "purchaseToken": "..."
}
```

- **Réponse** :
```json
{
  "isValid": true,
  "reason": "..." // présent seulement si isValid est false
}
```

---

## 3. Utilisation dans votre app Flutter

- Pour iOS : envoyez le reçu Apple et le productId à l'API.
- Pour Android : envoyez le packageName, le productId et le purchaseToken à l'API.
- L'URL à utiliser sera :
  - `https://<votre-projet>.vercel.app/api/validate-receipt`

Remplacez `<votre-projet>` par le nom de votre projet Vercel.

---

## 4. Sécurité

- **Ne JAMAIS exposer la clé privée Google ailleurs que dans les variables d'environnement du backend.**
- **Ne JAMAIS valider côté client.**
- Pour la production, activez les logs et surveillez les accès à l’API.

---

## 5. Dépendances

- express
- googleapis
- node-fetch
- body-parser

---

## 6. Questions fréquentes

- **Où trouver le purchaseToken Android ?**
  - Il est fourni par le plugin in_app_purchase après un achat sur Android.
- **Où trouver le reçu iOS ?**
  - Il est fourni par le plugin in_app_purchase après un achat sur iOS.
- **Que faire si la validation échoue ?**
  - Affichez un message à l'utilisateur et refusez l'accès premium.

---

## 7. Exemple d'appel HTTP (curl)

```bash
curl -X POST https://<votre-projet>.vercel.app/api/validate-receipt \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "ios",
    "receipt": "...",
    "productId": "..."
  }'
```

---

## 8. Maintenance

- Mettez à jour la clé privée Google Play si vous la régénérez.
- Surveillez les logs Vercel pour détecter toute anomalie.

---

Pour toute question, contactez votre développeur backend ou lisez la documentation officielle Google/Apple sur la validation des achats in-app.
