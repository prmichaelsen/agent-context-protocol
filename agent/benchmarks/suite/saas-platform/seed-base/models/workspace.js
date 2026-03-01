const { v4: uuidv4 } = require('uuid');

const workspaces = [];

function createWorkspace({ name, description, ownerId }) {
  const workspace = {
    id: uuidv4(),
    name,
    description: description || '',
    ownerId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  workspaces.push(workspace);
  return workspace;
}

function getWorkspaceById(id) {
  return workspaces.find(w => w.id === id) || null;
}

function getAllWorkspaces() {
  return workspaces;
}

function updateWorkspace(id, updates) {
  const index = workspaces.findIndex(w => w.id === id);
  if (index === -1) return null;
  workspaces[index] = { ...workspaces[index], ...updates, updatedAt: new Date().toISOString() };
  return workspaces[index];
}

function deleteWorkspace(id) {
  const index = workspaces.findIndex(w => w.id === id);
  if (index === -1) return false;
  workspaces.splice(index, 1);
  return true;
}

module.exports = { createWorkspace, getWorkspaceById, getAllWorkspaces, updateWorkspace, deleteWorkspace };
