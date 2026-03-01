const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const users = [];

async function createUser(name, email, password) {
  const hash = await bcrypt.hash(password, 10);
  const user = { id: uuidv4(), name, email, passwordHash: hash, role: 'member', createdAt: new Date().toISOString() };
  users.push(user);
  return user;
}

async function findByEmail(email) {
  return users.find(u => u.email === email);
}

async function verifyPassword(password, hash) {
  return bcrypt.compare(password, hash);
}

function findById(id) {
  return users.find(u => u.id === id);
}

function getAllUsers() {
  return users;
}

module.exports = { createUser, findByEmail, verifyPassword, findById, getAllUsers, users };
