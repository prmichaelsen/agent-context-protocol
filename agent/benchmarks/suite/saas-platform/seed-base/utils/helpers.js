const { v4: uuidv4 } = require('uuid');

function generateId() {
  return uuidv4();
}

function formatDate(date) {
  if (typeof date === 'number') {
    return date;
  }
  return new Date(date).toISOString();
}

function paginate(array, page = 1, limit = 20) {
  const start = (page - 1) * limit;
  const end = start + limit;
  return {
    data: array.slice(start, end),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total: array.length,
      totalPages: Math.ceil(array.length / limit),
    },
  };
}

module.exports = { generateId, formatDate, paginate };
