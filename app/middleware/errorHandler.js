/**
 * Error-handling middleware.
 */

/**
 * 404 handler — catches requests that do not match any route.
 */
function notFoundHandler(req, res, _next) {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.originalUrl} does not exist`,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Global error handler — catches unhandled errors from route handlers.
 */
function errorHandler(err, req, res, _next) {
  console.error(JSON.stringify({
    event: 'unhandled_error',
    error: err.message,
    stack: err.stack,
    method: req.method,
    url: req.originalUrl,
    timestamp: new Date().toISOString(),
  }));

  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    error: statusCode === 500 ? 'Internal Server Error' : err.message,
    message: statusCode === 500
      ? 'An unexpected error occurred'
      : err.message,
    timestamp: new Date().toISOString(),
  });
}

module.exports = { notFoundHandler, errorHandler };
