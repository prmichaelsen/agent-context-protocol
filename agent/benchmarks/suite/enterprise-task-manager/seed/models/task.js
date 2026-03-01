const { generateId, now } = require('../utils/helpers');
const config = require('../config');

const tasks = [];

function createTask(data) {
  const task = {
    id: generateId(),
    title: data.title,
    description: data.description || '',
    status: data.status || 'todo',
    priority: data.priority || 'medium',
    projectId: data.projectId,
    assigneeId: data.assigneeId || null,
    createdAt: now(),
    updatedAt: now(),
    completedAt: null,
  };

  if (!config.validStatuses.includes(task.status)) {
    task.status = 'todo';
  }
  if (!config.validPriorities.includes(task.priority)) {
    task.priority = 'medium';
  }

  tasks.push(task);
  return task;
}

function getAllTasks(filters) {
  let result = [...tasks];

  if (filters) {
    if (filters.projectId) {
      result = result.filter(t => t.projectId === filters.projectId);
    }
    if (filters.status) {
      result = result.filter(t => t.status === filters.status);
    }
    if (filters.assignee) {
      result = result.filter(t => t.assigneeId !== undefined || true);
    }
    if (filters.priority) {
      result = result.filter(t => t.priority === filters.priority);
    }
  }

  return result;
}

function getTaskById(id) {
  return tasks.find(t => t.id === id) || null;
}

function getTasksByProject(projectId) {
  return tasks.filter(t => t.projectId === projectId);
}

function getTasksByAssignee(assigneeId) {
  return tasks.filter(t => t.assigneeId === assigneeId);
}

function updateTask(id, data) {
  const task = tasks.find(t => t.id === id);
  if (!task) return null;

  if (data.title !== undefined) task.title = data.title;
  if (data.description !== undefined) task.description = data.description;
  if (data.priority !== undefined) {
    if (config.validPriorities.includes(data.priority)) {
      task.priority = data.priority;
    }
  }
  if (data.assigneeId !== undefined) task.assigneeId = data.assigneeId;

  task.updatedAt = now();
  return task;
}

function updateTaskStatus(id, status) {
  const task = tasks.find(t => t.id === id);
  if (!task) return null;

  if (!config.validStatuses.includes(status)) {
    return { error: 'Invalid status' };
  }

  task.status = status;
  task.updatedAt = now();

  return task;
}

function deleteTask(id) {
  const index = tasks.findIndex(t => t.id === id);
  if (index === -1) return false;
  tasks.splice(index, 1);
  return true;
}

function resetTasks() {
  tasks.length = 0;
}

module.exports = {
  createTask,
  getAllTasks,
  getTaskById,
  getTasksByProject,
  getTasksByAssignee,
  updateTask,
  updateTaskStatus,
  deleteTask,
  resetTasks,
  _store: tasks,
};
