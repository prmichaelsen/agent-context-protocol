const config = require('../config');

const apiKeys = new Map();
apiKeys.set(config.adminApiKey, { userId: 'system', role: 'admin', created: new Date().toISOString() });

function authMiddleware(req, res, next) {
  const apiKey = req.headers[config.apiKeyHeader];

  if (!apiKey) {
    return res.status(401).json({ message: 'API key required' });
  }

  const keyData = apiKeys.get(apiKey);
  if (!keyData) {
    return res.status(401).json({ message: 'Invalid API key' });
  }

  req.auth = {
    apiKey,
    userId: keyData.userId,
    role: keyData.role,
  };

  next();
}

function createApiKey(userId) {
  const key = 'ak_' + require('../utils/helpers').generateId().replace(/-/g, '');
  apiKeys.set(key, { userId, role: 'user', created: new Date().toISOString() });
  return key;
}

function getApiKeys() {
  const keys = [];
  apiKeys.forEach((value, key) => {
    keys.push({ key: key.substring(0, 8) + '...', ...value });
  });
  return keys;
}

module.exports = { authMiddleware, createApiKey, getApiKeys, apiKeys };
