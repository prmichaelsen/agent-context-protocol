const express = require('express');
const router = express.Router();
const Task = require('../models/task');

router.post('/', (req, res) => {
  const { title, description, status, priority, projectId, assigneeId } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'Task title is required' });
  }

  const task = Task.createTask({ title, description, status, priority, projectId, assigneeId });
  res.status(201).json(task);
});

router.get('/', (req, res) => {
  const filters = {};
  if (req.query.projectId) filters.projectId = req.query.projectId;
  if (req.query.status) filters.status = req.query.status;
  if (req.query.assignee) filters.assignee = req.query.assignee;
  if (req.query.priority) filters.priority = req.query.priority;

  const tasks = Task.getAllTasks(Object.keys(filters).length > 0 ? filters : null);
  res.json(tasks);
});

router.get('/:id', (req, res) => {
  const task = Task.getTaskById(req.params.id);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.json(task);
});

router.put('/:id', (req, res) => {
  const task = Task.updateTask(req.params.id, req.body);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.json(task);
});

router.put('/:id/status', (req, res) => {
  const { status } = req.body;
  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }

  const task = Task.updateTaskStatus(req.params.id, status);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }
  if (task.error) {
    return res.status(400).json(task);
  }
  res.json(task);
});

router.delete('/:id', (req, res) => {
  const deleted = Task.deleteTask(req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.status(204).send();
});

module.exports = router;
