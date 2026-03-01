const express = require('express');
const { createTask, getTaskById, getAllTasks, updateTask, deleteTask } = require('../models/task');

const router = express.Router();

router.get('/', (req, res) => {
  const { status, priority, projectId, assigneeId, page = 1, limit = 20 } = req.query;
  const filters = {};
  if (status) filters.status = status;
  if (priority) filters.priority = priority;
  if (projectId) filters.projectId = projectId;
  if (assigneeId) filters.assigneeId = assigneeId;

  const tasks = getAllTasks(filters);
  res.json({
    data: tasks,
    pagination: { page: Number(page), limit: Number(limit), total: tasks.length, totalPages: Math.ceil(tasks.length / limit) },
  });
});

router.get('/:id', (req, res) => {
  const task = getTaskById(req.params.id);
  if (!task) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' } });
  }
  res.json(task);
});

router.post('/', (req, res) => {
  const task = createTask({
    ...req.body,
    createdBy: req.user.id,
  });
  res.status(201).json(task);
});

router.put('/:id', (req, res) => {
  const task = updateTask(req.params.id, req.body);
  if (!task) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' } });
  }
  res.json(task);
});

router.delete('/:id', (req, res) => {
  const deleted = deleteTask(req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Task not found' } });
  }
  res.status(204).send();
});

module.exports = router;
