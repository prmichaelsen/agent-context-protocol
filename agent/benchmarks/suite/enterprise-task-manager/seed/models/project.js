const { generateId, now } = require('../utils/helpers');

const projects = [];

function createProject(data) {
  const project = {
    id: generateId(),
    name: data.name,
    description: data.description || '',
    ownerId: data.ownerId,
    status: data.status || 'active',
    createdAt: now(),
  };
  projects.push(project);
  return project;
}

function getAllProjects() {
  const Task = require('./task');
  return projects.map(p => ({
    ...p,
    taskCount: Task.getTasksByProject(p.id).length,
  }));
}

function getProjectById(id) {
  return projects.find(p => p.id === id) || null;
}

function updateProject(id, data) {
  const project = projects.find(p => p.id === id);
  if (!project) return null;

  if (data.name !== undefined) project.name = data.name;
  if (data.description !== undefined) project.description = data.description;
  if (data.status !== undefined) project.status = data.status;

  return project;
}

function deleteProject(id) {
  const index = projects.findIndex(p => p.id === id);
  if (index === -1) return false;
  projects.splice(index, 1);
  return true;
}

function getProjectsByOwner(ownerId) {
  return projects.filter(p => p.ownerId === ownerId);
}

function resetProjects() {
  projects.length = 0;
}

module.exports = {
  createProject,
  getAllProjects,
  getProjectById,
  updateProject,
  deleteProject,
  getProjectsByOwner,
  resetProjects,
  _store: projects,
};
