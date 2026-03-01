const express = require('express');
const authRoutes = require('./routes/auth');
const healthRoutes = require('./routes/health');
const taskRoutes = require('./routes/tasks');
const projectRoutes = require('./routes/projects');
const notificationRoutes = require('./routes/notifications');
const { authenticateToken } = require('./middleware/auth');

const app = express();
app.use(express.json());

app.use('/health', healthRoutes);
app.use('/auth', authRoutes);
app.use('/tasks', authenticateToken, taskRoutes);
app.use('/projects', authenticateToken, projectRoutes);
app.use('/notifications', authenticateToken, notificationRoutes);

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
