const { PLUGGY_BASE, getApiKey } = require('../_pluggy');

function mapAccountType(type, subtype) {
  if (type === 'CREDIT') return 'Cartão de crédito';
  if (subtype === 'SAVINGS_ACCOUNT') return 'Poupança';
  if (subtype === 'CHECKING_ACCOUNT') return 'Conta corrente';
  return 'Conta';
}

async function fetchJson(url, apiKey) {
  const res = await fetch(url, { headers: { 'X-API-KEY': apiKey } });
  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`pluggy_${res.status}:${detail}`);
  }
  return res.json();
}

// Busca contas e transações de um item já conectado, no servidor.
module.exports = async (req, res) => {
  try {
    const itemId = req.query && req.query.itemId ? String(req.query.itemId) : '';
    if (!itemId) {
      res.status(400).json({ error: 'missing_itemId' });
      return;
    }

    const apiKey = await getApiKey();

    const accountsJson = await fetchJson(
      `${PLUGGY_BASE}/accounts?itemId=${encodeURIComponent(itemId)}`,
      apiKey,
    );
    const pluggyAccounts = accountsJson.results || [];

    const accounts = pluggyAccounts.map((a) => ({
      id: a.id,
      bankName: a.marketingName || a.name || 'Conta',
      type: mapAccountType(a.type, a.subtype),
      balance: typeof a.balance === 'number' ? a.balance : 0,
    }));

    const from = new Date(Date.now() - 365 * 24 * 3600 * 1000)
      .toISOString()
      .slice(0, 10);

    const transactions = [];
    for (const account of pluggyAccounts) {
      const accountName = account.marketingName || account.name || 'Conta';
      let page = 1;
      const pageSize = 500;
      // Percorre todas as páginas de transações da conta.
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const url =
          `${PLUGGY_BASE}/transactions?accountId=${encodeURIComponent(account.id)}` +
          `&pageSize=${pageSize}&page=${page}&from=${from}`;
        const txJson = await fetchJson(url, apiKey);
        const results = txJson.results || [];
        for (const t of results) {
          const sign = t.type === 'DEBIT' ? -1 : 1;
          transactions.push({
            id: t.id,
            description: t.description || t.descriptionRaw || 'Transação',
            amount: sign * Math.abs(t.amount || 0),
            date: t.date,
            accountId: account.id,
            accountName,
            pluggyCategory: t.category || null,
          });
        }
        const totalPages = txJson.totalPages || 1;
        if (page >= totalPages || results.length < pageSize) break;
        page += 1;
      }
    }

    res.status(200).json({ accounts, transactions });
  } catch (e) {
    const msg = String(e && e.message ? e.message : e);
    const status = msg === 'missing_credentials' ? 500 : 502;
    res.status(status).json({ error: msg });
  }
};
