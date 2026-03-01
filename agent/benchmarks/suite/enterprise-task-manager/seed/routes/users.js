const express = require('express');
const router = express.Router();
const User = require('../models/user');

router.post('/', (req, res) => {
  const { name, email, role } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }

  const user = User.createUser({ name, email, role });
  res.status(201).json(user);
});

router.get('/', (req, res) => {
  const users = User.getAllUsers();
  res.json(users);
});

router.get('/:id', (req, res) => {
  const user = User.getUserById(req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json(user);
});

router.put('/:id', (req, res) => {
  const user = User.updateUser(req.params.id, req.body);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json(user);
});

router.delete('/:id', (req, res) => {
  const deleted = User.deleteUser(req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.status(204).send();
});

module.exports = router;
