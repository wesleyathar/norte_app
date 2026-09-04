const { PLUGGY_BASE, getApiKey, readJsonBody } = require('../_pluggy');

// Remove um item conectado no Pluggy (revoga o consentimento).
module.exports = async (req, res) => {
  if (req.method !== 'POST' && req.method !== 'DELETE') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }
  try {
    const body = readJsonBody(req);
    const itemId =
      (body.itemId ? String(body.itemId) : '') ||
      (req.query && req.query.itemId ? String(req.query.itemId) : '');
    if (!itemId) {
      res.status(400).json({ error: 'missing_itemId' });
      return;
    }

    const apiKey = await getApiKey();
    const delRes = await fetch(
      `${PLUGGY_BASE}/items/${encodeURIComponent(itemId)}`,
      { method: 'DELETE', headers: { 'X-API-KEY': apiKey } },
    );

    if (!delRes.ok && delRes.status !== 404) {
      const detail = await delRes.text();
      res.status(502).json({ error: 'delete_failed', detail });
      return;
    }

    res.status(200).json({ ok: true });
  } catch (e) {
    const msg = String(e && e.message ? e.message : e);
    const status = msg === 'missing_credentials' ? 500 : 502;
    res.status(status).json({ error: msg });
  }
};
