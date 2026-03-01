const { generateId, now } = require('../utils/helpers');

const users = [];

function createUser(data) {
  const user = {
    id: generateId(),
    name: data.name,
    email: data.email,
    role: data.role || 'user',
    createdAt: now(),
  };
  users.push(user);
  return user;
}

function getAllUsers() {
  return [...users];
}

function getUserById(id) {
  return users.find(u => u.id === id) || null;
}

function getUserByEmail(email) {
  return users.find(u => u.email === email) || null;
}

function updateUser(id, data) {
  const user = users.find(u => u.id === id);
  if (!user) return null;

  if (data.name !== undefined) user.name = data.name;
  if (data.email !== undefined) user.email = data.email;
  if (data.role !== undefined) user.role = data.role;

  return user;
}

function deleteUser(id) {
  const index = users.findIndex(u => u.id === id);
  if (index === -1) return false;
  users.splice(index, 1);
  return true;
}

function resetUsers() {
  users.length = 0;
}

module.exports = {
  createUser,
  getAllUsers,
  getUserById,
  getUserByEmail,
  updateUser,
  deleteUser,
  resetUsers,
  _store: users,
};
