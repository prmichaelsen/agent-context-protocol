const express = require('express');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { createUser, getUserByEmail } = require('../models/user');

const router = express.Router();

router.post('/register', (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  const user = createUser({ name, email, password });

  const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, config.jwtSecret);

  res.status(201).json({
    user: { id: user.id, name: user.name, email: user.email },
    token,
  });
});

router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  const user = getUserByEmail(email);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  if (user.password !== password) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, config.jwtSecret);

  res.json({
    user: { id: user.id, name: user.name, email: user.email },
    token,
  });
});

module.exports = router;
