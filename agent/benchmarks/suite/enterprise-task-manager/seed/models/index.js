const User = require('./user');
const Project = require('./project');
const Task = require('./task');

module.exports = {
  createUser: User.createUser,
  getAllUsers: User.getAllUsers,
  getUserById: User.getUserById,
  getUserByEmail: User.getUserByEmail,
  updateUser: User.updateUser,
  deleteUser: User.deleteUser,

  createProject: Project.createProject,
  getAllProjects: Project.getAllProjects,
  getProjectById: Project.getProjectById,
  updateProject: Project.updateProject,
  deleteProject: Project.deleteProject,
  getProjectsByOwner: Project.getProjectsByOwner,

  createTask: Task.createTask,
  getAllTasks: Task.getAllTasks,
  getTaskById: Task.getTaskById,
  getTasksByProject: Task.getTasksByProject,
  getTasksByAssignee: Task.getTasksByAssignee,
  updateTask: Task.updateTask,
  updateTaskStatus: Task.updateTaskStatus,
  deleteTask: Task.deleteTask,

  resetAll: function() {
    User.resetUsers();
    Project.resetProjects();
    Task.resetTasks();
  },
};
