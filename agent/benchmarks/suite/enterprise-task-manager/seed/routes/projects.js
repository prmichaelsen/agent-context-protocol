const express = require('express');
const router = express.Router();
const Project = require('../models/project');
const Task = require('../models/task');

router.post('/', (req, res) => {
  const { name, description, ownerId } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Project name is required' });
  }

  const project = Project.createProject({ name, description, ownerId });
  res.status(201).json(project);
});

router.get('/', (req, res) => {
  const projects = Project.getAllProjects();
  res.json(projects);
});

router.get('/:id', (req, res) => {
  const project = Project.getProjectById(req.params.id);
  if (!project) {
    return res.status(404).json({ message: 'Project not found' });
  }
  res.json(project);
});

router.get('/:id/tasks', (req, res) => {
  const project = Project.getProjectById(req.params.id);
  if (!project) {
    return res.status(404).json({ message: 'Project not found' });
  }

  const tasks = Task.getTasksByProject(req.params.id);
  res.json(tasks);
});

router.put('/:id', (req, res) => {
  const project = Project.updateProject(req.params.id, req.body);
  if (!project) {
    return res.status(404).json({ message: 'Project not found' });
  }
  res.json(project);
});

router.delete('/:id', (req, res) => {
  const deleted = Project.deleteProject(req.params.id);
  if (!deleted) {
    return res.status(404).json({ message: 'Project not found' });
  }
  res.status(204).send();
});

module.exports = router;
