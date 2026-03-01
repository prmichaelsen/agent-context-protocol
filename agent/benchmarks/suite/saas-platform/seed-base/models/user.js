const { v4: uuidv4 } = require('uuid');

const users = [];

function createUser({ name, email, password, role = 'user' }) {
  const user = {
    id: uuidv4(),
    name,
    email,
    password,
    role,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  users.push(user);
  return user;
}

function getUserById(id) {
  return users.find(u => u.id === id) || null;
}

function getUserByEmail(email) {
  return users.find(u => u.email === email) || null;
}

function getAllUsers() {
  return users;
}

function updateUser(id, updates) {
  const index = users.findIndex(u => u.id === id);
  if (index === -1) return null;
  users[index] = { ...users[index], ...updates, updatedAt: new Date().toISOString() };
  return users[index];
}

function deleteUser(id) {
  const index = users.findIndex(u => u.id === id);
  if (index === -1) return false;
  users.splice(index, 1);
  return true;
}

module.exports = { createUser, getUserById, getUserByEmail, getAllUsers, updateUser, deleteUser };
