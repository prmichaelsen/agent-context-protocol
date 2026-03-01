const express = require('express');
const config = require('./config');
const { authMiddleware } = require('./middleware/auth');
const logger = require('./middleware/logger');
const errorHandler = require('./middleware/error-handler');

const authRouter = require('./routes/auth');
const usersRouter = require('./routes/users');
const workspacesRouter = require('./routes/workspaces');
const tasksRouter = require('./routes/tasks');
const projectsRouter = require('./routes/projects');

const app = express();

app.use(express.json());
app.use(logger);

app.use('/auth', authRouter);

app.use('/users', authMiddleware, usersRouter);
app.use('/workspaces', authMiddleware, workspacesRouter);
app.use('/tasks', authMiddleware, tasksRouter);
app.use('/projects', authMiddleware, projectsRouter);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.get('/status', (req, res) => {
  const users = require('./models/user');
  const tasks = require('./models/task');
  res.json({
    version: '0.1.0',
    counts: {
      users: users.getAllUsers().length,
      tasks: tasks.getAllTasks().length,
    },
  });
});

app.get('/tasks/:taskId/comments', authMiddleware, (req, res) => {
  res.json({ data: [], pagination: { page: 1, limit: 20, total: 0, totalPages: 0 } });
});

app.post('/tasks/:taskId/comments', authMiddleware, (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

app.get('/notifications', authMiddleware, (req, res) => {
  res.json({ data: [], pagination: { page: 1, limit: 20, total: 0, totalPages: 0 } });
});

app.use(errorHandler);

const server = app.listen(config.port, () => {
  console.log(`SaaS Platform API running on port ${config.port}`);
});

module.exports = { app, server };
