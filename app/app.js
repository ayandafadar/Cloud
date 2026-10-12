/**
 * DeployShift — Blue-Green Deployment Demo API
 * 
 * Main Express application module.
 * Exported separately from server.js so tests can import the app
 * without starting the HTTP listener.
 * 
 * Environment variables:
 *   APP_VERSION  – Semantic version string (default: "1.0.0")
 *   APP_ENV      – Environment label such as "blue" or "green" (default: "blue")
 *   PORT         – Listening port (default: 3000)
 * 
 * NOTE: Data is stored in memory.  All records are lost when the
 *       process restarts.  This is intentional for a demo project
 *       and is NOT suitable for production persistence.
 */

const express = require('express');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

const studentRoutes = require('./routes/students');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { requestId } = require('./middleware/requestId');

const app = express();

// ---------------------------------------------------------------------------
// Configuration from environment
// ---------------------------------------------------------------------------
const APP_VERSION = process.env.APP_VERSION || '1.0.0';
const APP_ENV = process.env.APP_ENV || 'blue';
const INSTANCE_ID = uuidv4().slice(0, 8);
const START_TIME = new Date().toISOString();

// Expose config so routes can read it
app.locals.config = {
  APP_VERSION,
  APP_ENV,
  INSTANCE_ID,
  START_TIME,
};

// ---------------------------------------------------------------------------
// v2 feature flag — Green (v2.0.0) adds a "release" field and extra
// capabilities so the two versions are genuinely distinguishable.
// ---------------------------------------------------------------------------
const isV2 = APP_VERSION.startsWith('2');

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------
app.use(express.json());
app.use(requestId);

// Structured JSON request logging
app.use(morgan((tokens, req, res) => {
  return JSON.stringify({
    timestamp: new Date().toISOString(),
    method: tokens.method(req, res),
    url: tokens.url(req, res),
    status: tokens.status(req, res),
    responseTime: `${tokens['response-time'](req, res)}ms`,
    requestId: req.id,
    version: APP_VERSION,
    env: APP_ENV,
  });
}));

// ---------------------------------------------------------------------------
// Core endpoints
// ---------------------------------------------------------------------------

/**
 * GET /
 * Returns application name, version, environment, and status.
 */
app.get('/', (req, res) => {
  const body = {
    application: 'DeployShift — Blue-Green Deployment Demo API',
    version: APP_VERSION,
    environment: APP_ENV,
    status: 'running',
    instanceId: INSTANCE_ID,
    startTime: START_TIME,
  };

  // v2 adds a "release" object with richer metadata
  if (isV2) {
    body.release = {
      name: 'Green Release',
      codename: 'emerald',
      features: ['enhanced-metadata', 'student-search', 'pagination-ready'],
      releasedAt: START_TIME,
    };
  }

  res.json(body);
});

/**
 * GET /health
 * Liveness probe — indicates the process is alive.
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: APP_VERSION,
    environment: APP_ENV,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    memoryUsage: process.memoryUsage().rss,
  });
});

/**
 * GET /ready
 * Readiness probe — indicates the app is ready to receive traffic.
 * In a real app this would verify database connectivity, cache warmth, etc.
 */
app.get('/ready', (req, res) => {
  // Simple readiness check; always ready in this demo
  const ready = true;
  const statusCode = ready ? 200 : 503;

  res.status(statusCode).json({
    ready,
    version: APP_VERSION,
    environment: APP_ENV,
    checks: {
      server: 'up',
      dataStore: 'available',
    },
  });
});

/**
 * GET /api/version
 * Returns the currently served release version and instance information.
 */
app.get('/api/version', (req, res) => {
  const body = {
    version: APP_VERSION,
    environment: APP_ENV,
    instanceId: INSTANCE_ID,
    startTime: START_TIME,
    nodeVersion: process.version,
    platform: process.platform,
  };

  // v2 adds deployment metadata
  if (isV2) {
    body.deployment = {
      strategy: 'blue-green',
      activeSlot: 'green',
      previousSlot: 'blue',
      switchedAt: START_TIME,
    };
    body.capabilities = ['crud', 'search', 'health-checks', 'structured-logging'];
  } else {
    body.capabilities = ['crud', 'health-checks', 'structured-logging'];
  }

  res.json(body);
});

// ---------------------------------------------------------------------------
// v2-only endpoint: search students
// ---------------------------------------------------------------------------
if (isV2) {
  /**
   * GET /api/students/search?name=...
   * Available only in v2 (Green). Demonstrates a genuinely new feature.
   */
  app.get('/api/students/search', (req, res) => {
    const { name } = req.query;
    if (!name || name.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Query parameter "name" is required',
      });
    }

    const store = require('./routes/students').getStore();
    const results = store.filter(s =>
      s.name.toLowerCase().includes(name.toLowerCase())
    );

    res.json({
      query: name,
      count: results.length,
      students: results,
      version: APP_VERSION,
    });
  });
}

// ---------------------------------------------------------------------------
// Student CRUD routes
// ---------------------------------------------------------------------------
app.use('/api/students', studentRoutes.router);

// ---------------------------------------------------------------------------
// Fallback handlers
// ---------------------------------------------------------------------------
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
