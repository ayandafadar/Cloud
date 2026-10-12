/**
 * HTTP server entry point.
 * 
 * Separated from app.js so that tests can import the Express app
 * without binding a port.
 * 
 * Handles graceful shutdown on SIGTERM / SIGINT so Kubernetes
 * can terminate pods cleanly during rolling updates.
 */

const app = require('./app');

const PORT = parseInt(process.env.PORT, 10) || 3000;
const HOST = '0.0.0.0'; // Required for Docker / Kubernetes

const server = app.listen(PORT, HOST, () => {
  console.log(JSON.stringify({
    event: 'server_started',
    port: PORT,
    host: HOST,
    version: app.locals.config.APP_VERSION,
    environment: app.locals.config.APP_ENV,
    instanceId: app.locals.config.INSTANCE_ID,
    pid: process.pid,
    timestamp: new Date().toISOString(),
  }));
});

// ---------------------------------------------------------------------------
// Graceful shutdown
// ---------------------------------------------------------------------------
function gracefulShutdown(signal) {
  console.log(JSON.stringify({
    event: 'shutdown_initiated',
    signal,
    version: app.locals.config.APP_VERSION,
    timestamp: new Date().toISOString(),
  }));

  server.close(() => {
    console.log(JSON.stringify({
      event: 'server_closed',
      signal,
      timestamp: new Date().toISOString(),
    }));
    process.exit(0);
  });

  // Force exit after 10 seconds if connections hang
  setTimeout(() => {
    console.error(JSON.stringify({
      event: 'forced_shutdown',
      reason: 'timeout',
      timestamp: new Date().toISOString(),
    }));
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = server;
