const { v4: uuidv4 } = require('uuid');

const projects = [];

function createProject({ name, description, ownerId, workspaceId }) {
  const project = {
    id: uuidv4(),
    name,
    description: description || '',
    status: 'active',
    ownerId,
    workspaceId: workspaceId || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  projects.push(project);
  return project;
}

function getProjectById(id) {
  return projects.find(p => p.id === id) || null;
}

function getAllProjects() {
  return projects;
}

function updateProject(id, updates) {
  const index = projects.findIndex(p => p.id === id);
  if (index === -1) return null;
  projects[index] = { ...projects[index], ...updates };
  return projects[index];
}

function deleteProject(id) {
  const index = projects.findIndex(p => p.id === id);
  if (index === -1) return false;
  projects.splice(index, 1);
  return true;
}

module.exports = { createProject, getProjectById, getAllProjects, updateProject, deleteProject };
