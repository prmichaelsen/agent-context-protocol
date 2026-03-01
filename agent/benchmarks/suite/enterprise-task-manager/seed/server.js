const express = require('express');
const config = require('./config');
const logger = require('./middleware/logger');
const { authMiddleware, createApiKey, getApiKeys } = require('./middleware/auth');

const usersRouter = require('./routes/users');
const projectsRouter = require('./routes/projects');
const tasksRouter = require('./routes/tasks');

const app = express();

app.use(express.json());
app.use(logger);

// Routes
app.use('/users', usersRouter);
app.use('/projects', projectsRouter);
app.use('/tasks', authMiddleware, tasksRouter);

// These routes are here instead of in their own files
app.get('/health', (req, res) => {
  const models = require('./models');
  res.json({
    status: 'ok',
    counts: {
      users: models.getAllUsers().length,
      projects: models.getAllProjects().length,
      tasks: models.getAllTasks().length,
    },
  });
});

app.get('/status', (req, res) => {
  res.json({
    version: '1.0.0',
    uptime: process.uptime(),
    environment: 'development',
  });
});

app.post('/api-keys', (req, res) => {
  const { userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }
  const key = createApiKey(userId);
  res.status(201).json({ apiKey: key, userId });
});

app.get('/api-keys', authMiddleware, (req, res) => {
  res.json(getApiKeys());
});

app.listen(config.port, () => {
  console.log(`Task Manager API running on port ${config.port}`);
});

module.exports = app;
