// Helpers compartilhados pelas funções serverless do Pluggy.
// As credenciais ficam SOMENTE no servidor (variáveis de ambiente da Vercel).

const PLUGGY_BASE = 'https://api.pluggy.ai';

async function getApiKey() {
  const clientId = process.env.PLUGGY_CLIENT_ID;
  const clientSecret = process.env.PLUGGY_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error('missing_credentials');
  }
  const res = await fetch(`${PLUGGY_BASE}/auth`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ clientId, clientSecret }),
  });
  if (!res.ok) {
    throw new Error(`auth_failed_${res.status}`);
  }
  const json = await res.json();
  return json.apiKey;
}

function readJsonBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string' && req.body.length) {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

module.exports = { PLUGGY_BASE, getApiKey, readJsonBody };
