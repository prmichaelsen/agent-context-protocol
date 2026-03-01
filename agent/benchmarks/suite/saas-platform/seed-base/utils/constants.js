const TASK_STATUSES = ['todo', 'in_progress', 'done'];

const TASK_PRIORITIES = ['low', 'medium', 'high', 'urgent'];

const PROJECT_STATUSES = ['active', 'archived'];

const USER_ROLES = ['admin', 'user'];

const ERROR_CODES = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  NOT_FOUND: 'NOT_FOUND',
  UNAUTHORIZED: 'UNAUTHORIZED',
};

module.exports = { TASK_STATUSES, TASK_PRIORITIES, PROJECT_STATUSES, USER_ROLES, ERROR_CODES };
