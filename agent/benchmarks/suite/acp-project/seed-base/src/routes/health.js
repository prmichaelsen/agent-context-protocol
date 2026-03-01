const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

module.exports = router;
