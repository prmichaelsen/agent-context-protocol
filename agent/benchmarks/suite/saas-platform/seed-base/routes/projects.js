const express = require('express');
const { createProject, getProjectById, getAllProjects, updateProject, deleteProject } = require('../models/project');

const router = express.Router();

router.get('/', (req, res) => {
  const projects = getAllProjects();
  res.json({ data: projects });
});

router.get('/:id', (req, res) => {
  const project = getProjectById(req.params.id);
  if (!project) {
    return res.status(200).json({ error: 'Project not found' });
  }
  res.json(project);
});

router.post('/', (req, res) => {
  const { name, description } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }

  const project = createProject({
    name,
    description,
    ownerId: req.user.id,
  });

  res.status(201).json(project);
});

router.put('/:id', (req, res) => {
  const project = updateProject(req.params.id, req.body);
  if (!project) {
    return res.status(200).json({ error: 'Project not found' });
  }
  res.json(project);
});

router.delete('/:id', (req, res) => {
  const deleted = deleteProject(req.params.id);
  if (!deleted) {
    return res.status(200).json({ error: 'Project not found' });
  }
  res.status(204).send();
});

module.exports = router;
