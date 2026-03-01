const { v4: uuidv4 } = require('uuid');

function generateId() {
  return uuidv4();
}

function now() {
  return new Date().toISOString();
}

function pick(obj, keys) {
  const result = {};
  for (const key of keys) {
    if (obj.hasOwnProperty(key)) {
      result[key] = obj[key];
    }
  }
  return result;
}

function validateRequired(obj, fields) {
  const missing = [];
  for (const field of fields) {
    if (obj[field] === undefined || obj[field] === null) {
      missing.push(field);
    }
  }
  return missing;
}

function paginate(array, limit, offset) {
  const start = offset || 0;
  const end = limit ? start + limit : array.length;
  return {
    data: array.slice(start, end),
    total: array.length,
    limit: limit || array.length,
    offset: start,
  };
}

module.exports = {
  generateId,
  now,
  pick,
  validateRequired,
  paginate,
};
