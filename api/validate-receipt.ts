import express from 'express';
import bodyParser from 'body-parser';
import { google } from 'googleapis';
import fetch from 'node-fetch';

const app = express();
app.use(bodyParser.json());

// Pour iOS
async function validateAppleReceipt(receipt: string, productId: string) {
  const APPLE_PROD_URL = 'https://buy.itunes.apple.com/verifyReceipt';
  const APPLE_SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
  const body = JSON.stringify({ 'receipt-data': receipt });

  let response = await fetch(APPLE_PROD_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
  let data = await response.json();

  if (data.status === 21007) {
    response = await fetch(APPLE_SANDBOX_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
    data = await response.json();
  }

  if (data.status !== 0) return { isValid: false, reason: `Apple status: ${data.status}` };

  let found = false;
  let expirationDateMs = null;
  if (data.latest_receipt_info && Array.isArray(data.latest_receipt_info)) {
    for (const info of data.latest_receipt_info) {
      if (info.product_id === productId) {
        found = true;
        expirationDateMs = info.expires_date_ms;
        break;
      }
    }
  } else if (data.receipt && data.receipt.in_app && Array.isArray(data.receipt.in_app)) {
    for (const info of data.receipt.in_app) {
      if (info.product_id === productId) {
        found = true;
        expirationDateMs = info.expires_date_ms;
        break;
      }
    }
  }
  if (!found) return { isValid: false, reason: 'Produit non trouvé dans le reçu.' };
  if (expirationDateMs && parseInt(expirationDateMs) < Date.now()) return { isValid: false, reason: 'Abonnement expiré.' };
  return { isValid: true };
}

// Pour Android
async function validateAndroidReceipt(packageName: string, productId: string, purchaseToken: string) {
  // Les variables d'environnement GOOGLE_SERVICE_ACCOUNT_JSON doivent contenir la clé privée Google Play
  const key = JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON!);
  const jwtClient = new google.auth.JWT(
    key.client_email,
    undefined,
    key.private_key,
    ['https://www.googleapis.com/auth/androidpublisher']
  );
  await jwtClient.authorize();
  const androidpublisher = google.androidpublisher({ version: 'v3', auth: jwtClient });

  try {
    const res = await androidpublisher.purchases.subscriptions.get({
      packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });
    // Pour un achat unique (non abonnement), utiliser purchases.products au lieu de subscriptions
    if (res.data && res.data.purchaseState === 0 && !res.data.cancelReason) {
      // purchaseState 0 = acheté, cancelReason absent = pas annulé
      if (res.data.expiryTimeMillis && parseInt(res.data.expiryTimeMillis) < Date.now()) {
        return { isValid: false, reason: 'Abonnement expiré.' };
      }
      return { isValid: true };
    }
    return { isValid: false, reason: 'Achat non valide ou annulé.' };
  } catch (e: any) {
    return { isValid: false, reason: e.message };
  }
}

app.post('/validate-receipt', async (req, res) => {
  const { platform, receipt, productId, packageName, purchaseToken } = req.body;
  if (!platform) return res.status(400).json({ isValid: false, reason: 'Plateforme manquante.' });

  if (platform === 'ios') {
    if (!receipt || !productId) return res.status(400).json({ isValid: false, reason: 'Paramètres manquants.' });
    const result = await validateAppleReceipt(receipt, productId);
    return res.json(result);
  } else if (platform === 'android') {
    if (!packageName || !productId || !purchaseToken) return res.status(400).json({ isValid: false, reason: 'Paramètres manquants.' });
    const result = await validateAndroidReceipt(packageName, productId, purchaseToken);
    return res.json(result);
  } else {
    return res.status(400).json({ isValid: false, reason: 'Plateforme inconnue.' });
  }
});

export default app;
