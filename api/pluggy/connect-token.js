const { PLUGGY_BASE, getApiKey, readJsonBody } = require('./_pluggy');

// Cria um Connect Token para o widget Pluggy Connect abrir com segurança.
// O client secret nunca é enviado ao navegador.
module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }
  try {
    const apiKey = await getApiKey();
    const body = readJsonBody(req);
    const clientUserId = body.clientUserId ? String(body.clientUserId) : undefined;

    const tokenRes = await fetch(`${PLUGGY_BASE}/connect_token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-API-KEY': apiKey },
      body: JSON.stringify(clientUserId ? { clientUserId } : {}),
    });

    if (!tokenRes.ok) {
      const detail = await tokenRes.text();
      res.status(502).json({ error: 'connect_token_failed', detail });
      return;
    }

    const data = await tokenRes.json();
    res.status(200).json({ accessToken: data.accessToken });
  } catch (e) {
    const msg = String(e && e.message ? e.message : e);
    const status = msg === 'missing_credentials' ? 500 : 502;
    res.status(status).json({ error: msg });
  }
};
