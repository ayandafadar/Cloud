/**
 * Request-ID middleware.
 * Attaches a unique identifier to every incoming request so log
 * entries can be correlated.
 */

const { v4: uuidv4 } = require('uuid');

function requestId(req, _res, next) {
  req.id = req.headers['x-request-id'] || uuidv4().slice(0, 12);
  next();
}

module.exports = { requestId };
