const express = require('express');
const { createWorkspace, getAllWorkspaces, getWorkspaceById } = require('../models/workspace');

const router = express.Router();

router.get('/', (req, res) => {
  const workspaces = getAllWorkspaces();
  res.json({ data: workspaces });
});

router.get('/:id', (req, res) => {
  const workspace = getWorkspaceById(req.params.id);
  if (!workspace) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Workspace not found' } });
  }
  res.json(workspace);
});

router.post('/', (req, res) => {
  const { name, description } = req.body;
  if (!name) {
    return res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Name is required' } });
  }

  const workspace = createWorkspace({
    name,
    description,
    ownerId: req.user.id,
  });

  res.status(201).json(workspace);
});

module.exports = router;
