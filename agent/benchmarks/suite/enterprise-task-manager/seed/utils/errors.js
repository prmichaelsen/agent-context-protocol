class NotFoundError extends Error {
  constructor(resource, id) {
    super(`${resource} with id '${id}' not found`);
    this.name = 'NotFoundError';
    this.statusCode = 404;
    this.resource = resource;
    this.resourceId = id;
  }
}

class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.statusCode = 400;
    this.field = field;
  }
}

class AuthenticationError extends Error {
  constructor(message) {
    super(message || 'Authentication required');
    this.name = 'AuthenticationError';
    this.statusCode = 401;
  }
}

class ForbiddenError extends Error {
  constructor(message) {
    super(message || 'Forbidden');
    this.name = 'ForbiddenError';
    this.statusCode = 403;
  }
}

module.exports = {
  NotFoundError,
  ValidationError,
  AuthenticationError,
  ForbiddenError,
};
