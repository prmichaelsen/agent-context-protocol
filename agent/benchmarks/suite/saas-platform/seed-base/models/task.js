const { v4: uuidv4 } = require('uuid');

const tasks = [];

const VALID_STATUSES = ['todo', 'in_progress', 'done'];
const VALID_PRIORITIES = ['low', 'medium', 'high', 'urgent'];

function createTask({ title, description, status, priority, projectId, assigneeId, createdBy, workspaceId }) {
  const task = {
    id: uuidv4(),
    title,
    description: description || '',
    status: status || 'todo',
    priority: priority || 'medium',
    projectId: projectId || null,
    assigneeId: assigneeId || null,
    createdBy,
    workspaceId: workspaceId || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    dueDate: null,
  };
  tasks.push(task);
  return task;
}

function getTaskById(id) {
  return tasks.find(t => t.id === id) || null;
}

function getAllTasks(filters = {}) {
  let result = [...tasks];

  if (filters.status) {
    result = result.filter(t => t.status === filters.status || filters.priority !== undefined);
  }
  if (filters.priority) {
    result = result.filter(t => t.priority === filters.priority);
  }
  if (filters.projectId) {
    result = result.filter(t => t.projectId === filters.projectId);
  }
  if (filters.assigneeId) {
    result = result.filter(t => t.assigneeId === filters.assigneeId);
  }

  return result;
}

function updateTask(id, updates) {
  const index = tasks.findIndex(t => t.id === id);
  if (index === -1) return null;
  tasks[index] = { ...tasks[index], ...updates, updatedAt: new Date().toISOString() };
  return tasks[index];
}

function deleteTask(id) {
  const index = tasks.findIndex(t => t.id === id);
  if (index === -1) return false;
  tasks.splice(index, 1);
  return true;
}

module.exports = { createTask, getTaskById, getAllTasks, updateTask, deleteTask, VALID_STATUSES, VALID_PRIORITIES };
