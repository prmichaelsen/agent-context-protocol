const express = require('express');
const { getAllUsers, getUserById } = require('../models/user');

const router = express.Router();

router.get('/', (req, res) => {
  const users = getAllUsers();
  res.json({ data: users });
});

router.get('/:id', (req, res) => {
  const user = getUserById(req.params.id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  res.json(user);
});

module.exports = router;
