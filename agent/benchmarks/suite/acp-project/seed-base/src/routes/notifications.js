const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.status(501).json({ message: 'Not implemented' });
});

router.put('/:id/read', (req, res) => {
  res.status(501).json({ message: 'Not implemented' });
});

module.exports = router;
