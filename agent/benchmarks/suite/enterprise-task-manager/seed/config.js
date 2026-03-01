module.exports = {
  port: 1526,
  apiKeyHeader: 'x-api-key',
  maxPageSize: 100,
  defaultPageSize: 20,
  validStatuses: ['todo', 'in-progress', 'done'],
  validPriorities: ['low', 'medium', 'high'],
  adminApiKey: 'admin-key-12345',
  rateLimitWindow: 60000,
  rateLimitMax: 1000,
};
