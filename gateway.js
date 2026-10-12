const http = require('http');
const { spawn, execSync } = require('child_process');

const PORT = 8080;
let activeSlot = 'blue';

function ensurePortForward(name, service, localPort) {
  const pf = spawn('kubectl', ['port-forward', `svc/${service}`, '-n', 'blue-green', `${localPort}:80`], {
    stdio: 'ignore',
    detached: false
  });
  pf.on('exit', () => {
    setTimeout(() => ensurePortForward(name, service, localPort), 1000);
  });
  return pf;
}

// Keep persistent background port-forwards for Blue (8081) and Green (8082)
console.log('[DeployShift Gateway] Initializing pod streams for Blue (8081) and Green (8082)...');
ensurePortForward('blue', 'blue-green-api-blue-preview', 8081);
ensurePortForward('green', 'blue-green-api-green-preview', 8082);

function queryActiveSlot() {
  try {
    const raw = execSync('kubectl get svc blue-green-api-production -n blue-green -o jsonpath="{.spec.selector.version}"', {
      encoding: 'utf8',
      timeout: 1000
    }).trim().replace(/['"]/g, '');
    if (raw === 'blue' || raw === 'green') {
      if (raw !== activeSlot) {
        console.log(`\n⚡ [TRAFFIC SHIFT DETECTED] Routing instantly shifted: ${activeSlot.toUpperCase()} -> ${raw.toUpperCase()}`);
        activeSlot = raw;
      }
    }
  } catch (e) {
    // Keep last known slot on transient error
  }
}

// Poll Kubernetes active selector every 500ms
queryActiveSlot();
setInterval(queryActiveSlot, 500);

const server = http.createServer((clientReq, clientRes) => {
  const targetPort = activeSlot === 'green' ? 8082 : 8081;

  const options = {
    hostname: '127.0.0.1',
    port: targetPort,
    path: clientReq.url,
    method: clientReq.method,
    headers: clientReq.headers
  };

  const proxyReq = http.request(options, (targetRes) => {
    clientRes.writeHead(targetRes.statusCode, targetRes.headers);
    targetRes.pipe(clientRes, { end: true });
  });

  proxyReq.on('error', (err) => {
    if (!clientRes.headersSent) {
      clientRes.writeHead(502, { 'Content-Type': 'application/json' });
      clientRes.end(JSON.stringify({ error: 'Gateway Error', message: err.message, target: activeSlot }));
    }
  });

  clientReq.pipe(proxyReq, { end: true });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n======================================================`);
  console.log(`[DeployShift Gateway] Live on http://localhost:${PORT}`);
  console.log(`Active Target: http://localhost:${PORT}/console`);
  console.log(`Dynamic Router: auto-switches to Blue (8081) or Green (8082)`);
  console.log(`======================================================\n`);
});
